#!/bin/bash
set -euo pipefail

APP="LiteEdit"
BUILD=".build/release"
BUNDLE="${APP}.app"

echo "▸ Building ${APP} (release)…"
swift build -c release 2>&1

echo "▸ Packaging ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "${BUILD}/${APP}" "${BUNDLE}/Contents/MacOS/"

if [ -f "LiteEdit.icns" ]; then
  cp "LiteEdit.icns" "${BUNDLE}/Contents/Resources/AppIcon.icns"
fi

cat > "${BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>LiteEdit</string>
  <key>CFBundleDisplayName</key>
  <string>LiteEdit</string>
  <key>CFBundleIdentifier</key>
  <string>com.liteedit.app</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleExecutable</key>
  <string>LiteEdit</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>All Files</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>public.text</string>
        <string>public.plain-text</string>
        <string>public.source-code</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

echo ""
echo "✓ Built ${BUNDLE} ($(du -sh "${BUNDLE}" | cut -f1) on disk)"
echo "  Run:  open ${BUNDLE}"
echo "  Copy: cp -r ${BUNDLE} /Applications/"
