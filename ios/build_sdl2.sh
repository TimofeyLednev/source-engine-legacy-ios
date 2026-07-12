#!/bin/bash
# ios/build_sdl2.sh -- cross-compile a static libSDL2.a (2.0.7) for legacy iOS
# (armv7, iOS 6.1+) using the cctools-port toolchain built by setup_toolchain.sh.
#
# SDL 2.0.7 is the LAST SDL2 release that still supports iOS 6.1 (2.0.8 bumped
# the minimum to iOS 8.0). It has no SDL_UIKitRunApp (that arrived in 2.0.10);
# instead libSDL2.a itself provides the real main() in SDL_uikitappdelegate.m,
# and the engine's main() becomes SDL_main via SDL_main.h's `#define main`.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
TC="${NBC_TOOLCHAIN:-$HERE/build/work}"
export PATH="$TC/toolchain/bin:$PATH"

SDK="$TC/sdks/ios-sdk"
SDLSRC="$TC/SDL2-2.0.7"
OUT="$TC/sdl2/lib"
OBJ="$TC/sdl2/obj"

[ -d "$SDLSRC" ] || { echo "ERROR: SDL2-2.0.7 sources not found at $SDLSRC (run setup_toolchain.sh)"; exit 1; }
[ -d "$SDK" ]    || { echo "ERROR: iOS SDK not found at $SDK"; exit 1; }

if [ -f "$OUT/libSDL2.a" ] && [ "$1" != "--force" ]; then
  echo "libSDL2.a already built: $OUT/libSDL2.a ($(du -h "$OUT/libSDL2.a" | cut -f1)) -- pass --force to rebuild"
  exit 0
fi

mkdir -p "$OUT" "$OBJ"
rm -f "$OBJ"/*.o

CFLAGS="-isysroot $SDK --target=armv7-apple-ios6.0 -arch armv7 -mfpu=neon \
-D__IPHONEOS__=1 -O2 -fPIC \
-I$SDLSRC/include -I$SDLSRC/src -I$SDLSRC/src/video/khronos \
-Wno-everything"

echo "=== building libSDL2.a (2.0.7, armv7-ios6.0) ==="

# SDL selects platform backends via config guards keyed on __IPHONEOS__, but a
# few desktop backends (x11/wayland/cocoa/qnx/windows/linux-evdev/...) include
# their platform headers unconditionally and won't cross-compile. Skip those
# directories; keep the portable core + the uikit/coreaudio/iphoneos backends.
# NOTE: only video/cocoa + filesystem/cocoa are AppKit desktop code — file/cocoa
# (SDL_rwopsbundlesupport.m, provides SDL_OpenFPFromBundleOrFallback) is Foundation
# only and IS needed on iOS, so we do NOT blanket-exclude "cocoa".
# main/dummy defines its own _main which collides with the uikit delegate's.
EXCLUDE_RE='/(x11|wayland|video/cocoa|filesystem/cocoa|qnx|windows|winrt|directfb|kmsdrm|mir|vivante|haiku|nacl|psp|emscripten|directsound|winmm|wasapi|xaudio2|alsa|pulseaudio|jack|arts|esd|nas|sndio|dsp|sun|paudio|netbsd|fusionsound|linux|test|main/dummy|dummy/SDL_nullevents|windowsvideo)/'
srcs=$(find "$SDLSRC/src" -name '*.c' -o -name '*.m' | grep -vE "$EXCLUDE_RE" | sort)
total=$(echo "$srcs" | wc -l)
n=0; failed=0
for f in $srcs; do
  n=$((n+1))
  rel="${f#$SDLSRC/src/}"
  o="$OBJ/$(echo "$rel" | tr '/' '_').o"
  extra=""
  case "$f" in *.m) extra="-fobjc-arc" ;; esac
  if ! clang $CFLAGS $extra -c "$f" -o "$o" 2>>"$TC/sdl2/build_err.log"; then
    echo "  [FAIL $n/$total] $rel"
    failed=$((failed+1))
  fi
done
echo "compiled $((n-failed))/$total objects (failed=$failed)"

[ "$failed" -eq 0 ] || { echo "SDL2 build had failures; see $TC/sdl2/build_err.log"; exit 1; }

rm -f "$OUT/libSDL2.a"
# Use cctools' libtool -static, NOT ar: ld64 rejects ar-built archives with a
# bogus "building for iOS-armv7 but attempting to link with file built for iOS
# Simulator" warning and silently ignores the whole .a. libtool -static writes
# the platform info ld64 expects, so the archive links correctly.
LIBTOOL="$TC/toolchain/bin/arm-apple-darwin11-libtool"
if [ -x "$LIBTOOL" ]; then
  "$LIBTOOL" -static -o "$OUT/libSDL2.a" "$OBJ"/*.o
else
  echo "WARN: cctools libtool not found, falling back to ar (may be ignored by ld64)"
  ar rcs "$OUT/libSDL2.a" "$OBJ"/*.o
  ranlib "$OUT/libSDL2.a" 2>/dev/null || true
fi

echo "=== libSDL2.a: $OUT/libSDL2.a ($(du -h "$OUT/libSDL2.a" | cut -f1)) ==="
echo "=== main symbol present? ==="
"$TC/toolchain/bin/arm-apple-darwin11-nm" "$OUT/libSDL2.a" 2>/dev/null | grep -E " T _main$" | head || echo "(nm check skipped)"
