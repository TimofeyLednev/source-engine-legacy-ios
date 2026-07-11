#!/bin/bash
# ios/build.sh -- cross-compile Source Engine for legacy iOS (armv7, iOS 5/6+)
# from a Linux host, using a cctools-port toolchain + an unpacked iOS SDK (9.3, still armv7-capable).
#
# Usage:
#   ./ios/build.sh <game> [--configure-only] [--jobs N]
#
#   <game> is one of:
#     hl2       Half-Life 2 (and Lost Coast, which shares the hl2 game dir)
#     portal    Portal 1
#     episodic  Half-Life 2: Episodes
#
# Environment (auto-detected if the toolchain lives in ios/build/work):
#   NBC_TOOLCHAIN   root of the cross toolchain (contains bin/, sdks/)
#
# The toolchain is built by ios/setup_toolchain.sh (run that once first).
set -e

# --- resolve paths ------------------------------------------------------------
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TC="${NBC_TOOLCHAIN:-$HERE/build/work}"

GAME="${1:-hl2}"
shift || true

CONFIGURE_ONLY=0
JOBS="$(nproc 2>/dev/null || echo 4)"
while [ $# -gt 0 ]; do
  case "$1" in
    --configure-only) CONFIGURE_ONLY=1 ;;
    --jobs) shift; JOBS="$1" ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

case "$GAME" in
  hl2|portal|episodic) ;;
  *) echo "unknown game '$GAME' (expected: hl2, portal, episodic)" >&2; exit 2 ;;
esac

# --- toolchain env ------------------------------------------------------------
export NBC_SDK="$TC/sdks/ios-sdk"
export NBC_TARGET="armv7-apple-ios6.0"
export NBC_TOOLCHAIN_BIN="$TC/toolchain/bin"
export NBC_LIBCXX_SHIM="$HERE/libcxx"
export NBC_LEGACY_COMPAT="$HERE/compat/ios_legacy_compat.h"
export NBC_COMPAT_INCLUDE="$HERE/compat"
export NBC_SDL2_INCLUDE="$TC/sdl2/include/SDL2"
export PATH="$NBC_TOOLCHAIN_BIN:$PATH"
export CC=clang
export CXX=clang++

if [ ! -d "$NBC_SDK" ]; then
  echo "ERROR: iOS SDK not found at $NBC_SDK" >&2
  echo "Run ios/setup_toolchain.sh first to build the toolchain + fetch the SDK." >&2
  exit 1
fi

echo "=== legacy-iOS build ==="
echo "  game       : $GAME"
echo "  target     : $NBC_TARGET"
echo "  sdk        : $NBC_SDK"
echo "  toolchain  : $NBC_TOOLCHAIN_BIN"
echo "  jobs       : $JOBS"

cd "$ROOT"

# --- submodules ---------------------------------------------------------------
# The engine pulls physics (ivp) and third-party sources from git submodules.
# waf's subproject loader errors out ("Cannot read the folder ivp/havana") if
# they are not checked out, so make sure they are present before configuring.
if [ ! -f "$ROOT/ivp/ivp_physics/wscript" ] || [ ! -d "$ROOT/thirdparty" ]; then
  echo "=== initializing git submodules (ivp, thirdparty) ==="
  git -C "$ROOT" submodule update --init --depth 1 ivp thirdparty
fi

# --- configure ----------------------------------------------------------------
# --togles  : OpenGL ES 2 render path (DX->GL abstraction for GLES)
# --disable-warns : the leaked engine is warning-noisy; keep output readable
python3 waf configure \
  -T release \
  --ios \
  --togles \
  --disable-warns \
  --build-games="$GAME"

[ "$CONFIGURE_ONLY" = "1" ] && { echo "configure only -- done"; exit 0; }

# --- build --------------------------------------------------------------------
python3 waf build -j"$JOBS"

echo "=== build finished: game=$GAME ==="
