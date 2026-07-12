#!/bin/bash
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
APPNAME="${1:-HL2Launcher}"
OUTDIR="$HERE/ipa"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR/Payload/$APPNAME.app"
cp -f "$ROOT/build/launcher_main/hl2_launcher" "$OUTDIR/Payload/$APPNAME.app/$APPNAME"
cat > "$OUTDIR/Payload/$APPNAME.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>HL2 Launcher</string>
  <key>CFBundleExecutable</key><string>HL2Launcher</string>
  <key>CFBundleIdentifier</key><string>com.timofeylednev.sourceenginlegacyios.hl2launcher</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>HL2Launcher</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSRequiresIPhoneOS</key><true/>
  <key>MinimumOSVersion</key><string>5.0</string>
  <key>UIRequiredDeviceCapabilities</key><array><string>armv7</string></array>
</dict>
</plist>
PLIST
for f in launcher/liblauncher.dylib engine/libengine.dylib gameui/libGameUI.dylib filesystem/libfilesystem_stdio.dylib tier0/libtier0.dylib vstdlib/libvstdlib.dylib datacache/libdatacache.dylib inputsystem/libinputsystem.dylib materialsystem/libmaterialsystem.dylib soundemittersystem/libsoundemittersystem.dylib serverbrowser/libServerBrowser.dylib scenefilecache/libscenefilecache.dylib vguimatsurface/libvguimatsurface.dylib studiorender/libstudiorender.dylib vphysics/libvphysics.dylib video/libvideo_services.dylib togles/libtogl.dylib stub_steam/libsteam_api.dylib; do
  src="$ROOT/build/$f"
  [ -e "$src" ] && cp -f "$src" "$OUTDIR/Payload/$APPNAME.app/bin/" 2>/dev/null || true
done
mkdir -p "$OUTDIR/Payload/$APPNAME.app/bin"
cd "$OUTDIR"
zip -qry "../${APPNAME}-test.ipa" Payload
printf '%s\n' "$OUTDIR/../${APPNAME}-test.ipa"
