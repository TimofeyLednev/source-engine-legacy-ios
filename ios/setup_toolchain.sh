#!/bin/bash
set -e
# ios/setup_toolchain.sh -- build the Linux->iOS cross toolchain.
# Downloads iOS SDK (9.3, still armv7-capable), builds libtapi,
# apple-libdispatch, cctools-port (ld64/lipo/strip) and ldid.
HERE="$(cd "$(dirname "$0")" && pwd)"
export TC="${NBC_TOOLCHAIN:-$HERE/build/work}"
mkdir -p "$TC"
cd "$TC"
mkdir -p toolchain/bin
export PATH="$TC/toolchain/bin:$PATH"
sdk="$TC/sdks/ios-sdk"

echo "=========== STAGE 1: iOS SDK (9.3, has armv7) ==========="
if [ ! -e "$sdk/SDKSettings.plist" ]; then
  echo "[SDK] sparse-checkout iPhoneOS9.3.sdk from theos/sdks..."
  rm -rf theossdks
  git clone --depth 1 --filter=blob:none --sparse https://github.com/theos/sdks.git theossdks > /tmp/sdk_clone.log 2>&1
  ( cd theossdks && git sparse-checkout set iPhoneOS9.3.sdk >> /tmp/sdk_clone.log 2>&1 )
  mkdir -p "$TC/sdks"
  rm -rf "$sdk"
  ln -sfn "$TC/theossdks/iPhoneOS9.3.sdk" "$sdk"
fi
echo "[SDK] path: $(ls -d $sdk 2>/dev/null || echo MISSING)"
ls "$sdk/System/Library/Frameworks" 2>/dev/null | grep -iE "OpenGLES|UIKit|Foundation" || echo "[SDK] WARN frameworks not found"

echo "=========== STAGE 2: libBlocksRuntime ==========="
dpkg -l | grep -q libblocksruntime-dev || apt-get install -y libblocksruntime-dev 2>&1 | tail -1 || true
echo "blocks: $(dpkg -l | grep -i blocksruntime-dev | awk '{print $3}' | head -1)"

echo "=========== STAGE 3: cctools-port (ld64/lipo/strip) ==========="
# ld64 needs Apple's libdispatch + BlocksRuntime on Linux. Build the
# tpoechtrager port of libdispatch and point cctools at it.
DISPATCH="$TC/apple-libdispatch"
if [ ! -f "$TC/toolchain/lib/libdispatch.so" ]; then
  rm -rf "$DISPATCH"
  git clone --depth 1 https://github.com/tpoechtrager/apple-libdispatch.git "$DISPATCH" > /tmp/dispatch_clone.log 2>&1
  mkdir -p "$DISPATCH/build"
  cd "$DISPATCH/build"
  CC=clang CXX=clang++ cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_INSTALL_PREFIX="$TC/toolchain" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF .. > /tmp/dispatch_cmake.log 2>&1 \
    || { echo "libdispatch cmake FAILED"; tail -30 /tmp/dispatch_cmake.log; exit 1; }
  make -j$(nproc) dispatch BlocksRuntime > /tmp/dispatch_make.log 2>&1 \
    || { echo "libdispatch make FAILED"; tail -40 /tmp/dispatch_make.log; exit 1; }
  # Install libs + headers into the toolchain prefix by hand (the port's
  # `make install` pulls in test targets we skipped).
  mkdir -p "$TC/toolchain/lib" "$TC/toolchain/include/dispatch" "$TC/toolchain/include/os"
  cp -f libdispatch.so libBlocksRuntime.so "$TC/toolchain/lib/" 2>/dev/null || true
  cp -f "$DISPATCH"/dispatch/*.h "$TC/toolchain/include/dispatch/" 2>/dev/null || true
  cp -f "$DISPATCH"/os/*.h "$TC/toolchain/include/os/" 2>/dev/null || true
  cp -f "$DISPATCH"/BlocksRuntime/Block.h "$TC/toolchain/include/" 2>/dev/null || true
  cd "$TC"
fi
echo "libdispatch: $(ls $TC/toolchain/lib/libdispatch.so 2>/dev/null || echo MISSING)"

# ld64 must read .tbd text stubs from the iOS SDK -> needs libtapi.
if [ ! -f "$TC/toolchain/lib/libtapi.so" ] && [ ! -f "$TC/toolchain/lib/libtapi.dylib" ]; then
  echo "=========== STAGE 3b: libtapi ==========="
  rm -rf apple-libtapi
  git clone --depth 1 https://github.com/tpoechtrager/apple-libtapi.git > /tmp/tapi_clone.log 2>&1
  cd apple-libtapi
  INSTALLPREFIX="$TC/toolchain" ./build.sh > /tmp/tapi_build.log 2>&1 \
    || { echo "libtapi build FAILED"; tail -40 /tmp/tapi_build.log; exit 1; }
  ./install.sh > /tmp/tapi_install.log 2>&1 || { echo "libtapi install FAILED"; tail -20 /tmp/tapi_install.log; exit 1; }
  cd "$TC"
fi
echo "libtapi: $(ls $TC/toolchain/lib/libtapi.* 2>/dev/null | head -1 || echo MISSING)"

if [ ! -x toolchain/bin/arm-apple-darwin11-ld ] && [ ! -x toolchain/bin/ld64 ]; then
  rm -rf cctools-port
  git clone --depth 1 https://github.com/tpoechtrager/cctools-port.git > /tmp/cctools_clone.log 2>&1
  cd cctools-port/cctools
  ./configure --prefix="$TC/toolchain" --target=arm-apple-darwin11 \
    --with-libtapi="$TC/toolchain" \
    --with-libdispatch="$TC/toolchain" --with-libblocksruntime="$TC/toolchain" > /tmp/cctools_conf.log 2>&1 \
    || { echo "configure FAILED"; tail -30 /tmp/cctools_conf.log; exit 1; }
  make -j$(nproc) > /tmp/cctools_make.log 2>&1 || { echo "make FAILED"; tail -40 /tmp/cctools_make.log; exit 1; }
  make install > /tmp/cctools_install.log 2>&1 || { echo "install FAILED"; tail -20 /tmp/cctools_install.log; exit 1; }
  cd "$TC"
fi
echo "cctools:"; ls toolchain/bin/ | grep -iE "arm-apple|ld$|lipo|strip|ranlib|ar$" | head

echo "=========== STAGE 4: ldid ==========="
if [ ! -x toolchain/bin/ldid ]; then
  rm -rf ldid
  git clone --depth 1 https://github.com/ProcursusTeam/ldid.git > /tmp/ldid_clone.log 2>&1
  cd ldid
  make -j$(nproc) LDID_STATIC=1 > /tmp/ldid_make.log 2>&1 || make -j$(nproc) > /tmp/ldid_make.log 2>&1 \
    || { echo "ldid make FAILED"; tail -40 /tmp/ldid_make.log; exit 1; }
  cp -f ldid "$TC/toolchain/bin/" 2>/dev/null || find . -name ldid -type f -executable -exec cp -f {} "$TC/toolchain/bin/" \;
  cd "$TC"
fi
echo "ldid: $(ls toolchain/bin/ldid 2>/dev/null || echo MISSING)"

echo "=========== TOOLCHAIN DONE ==========="
