#!/bin/bash
set -euo pipefail

APP="LiteEdit"
BUNDLE="${APP}.app"
DMG="${APP}.dmg"
STAGING="dmg-staging"
VOLUME_NAME="LiteEdit"

echo "▸ Step 1: Building ${APP}…"
bash build.sh

if [ ! -d "${BUNDLE}" ]; then
  echo "✗ Build failed — ${BUNDLE} not found"
  exit 1
fi

echo "▸ Step 2: Creating DMG…"
rm -rf "${STAGING}" "${DMG}"

mkdir -p "${STAGING}"
cp -R "${BUNDLE}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${STAGING}" \
  -ov \
  -format UDZO \
  "${DMG}"

rm -rf "${STAGING}"

SIZE=$(du -h "${DMG}" | cut -f1 | xargs)
echo ""
echo "✓ Created ${DMG} (${SIZE})"
echo "  Install: open ${DMG}"
