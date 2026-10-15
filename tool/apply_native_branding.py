#!/usr/bin/env python3
"""Apply the recovered icon and app name. Safe to rerun; no image packages needed."""
from pathlib import Path
import plistlib, shutil, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
ANDROID = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID)
manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
if not manifest.exists():
    raise SystemExit('Run bash scripts/bootstrap.sh first.')
tree = ET.parse(manifest)
app = tree.getroot().find('application')
if app is None:
    raise SystemExit('Android manifest has no application element.')
app.set(f'{{{ANDROID}}}label', 'Global Eater')
app.set(f'{{{ANDROID}}}allowBackup', 'false')
app.set(f'{{{ANDROID}}}icon', '@mipmap/ic_launcher')
tree.write(manifest, encoding='utf-8', xml_declaration=True)
shutil.copytree(ROOT/'platform_assets/android/res', ROOT/'android/app/src/main/res', dirs_exist_ok=True)
info = ROOT/'ios/Runner/Info.plist'
if info.exists():
    with info.open('rb') as f: plist = plistlib.load(f)
    plist['CFBundleDisplayName'] = 'Global Eater'
    plist['CFBundleName'] = 'Global Eater'
    with info.open('wb') as f: plistlib.dump(plist, f, sort_keys=False)
    shutil.copytree(ROOT/'platform_assets/ios/AppIcon.appiconset',
                    ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset', dirs_exist_ok=True)
print('Applied original Global Eater branding to Android and iOS hosts.')
