#!/usr/bin/env python3
"""Local tooling tests. Mocked adb is not an APK build or Android runtime test."""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

from recover_legacy import recover

ROOT = Path(__file__).resolve().parents[1]
ANDROID = '{http://schemas.android.com/apk/res/android}'
APK_NAME = 'GlobalEater-0.1.0-android-arm64-debug.apk'


class RecoveryAndCatalogTests(unittest.TestCase):
    def test_full_binary_recovery_matches_archived_rows(self):
        recovered = recover(ROOT / 'archive/Global Eater V1B.xls')
        archived = json.loads((ROOT / 'archive/legacy_rows.json').read_text())
        self.assertEqual(len(recovered), 1815)
        self.assertEqual(recovered, archived)
        self.assertIn('北京烤鸭', recovered[0]['Menu Item Name'])

    def test_generated_catalog_is_reproducible(self):
        files = [ROOT / 'assets/data' / n for n in ('foods.json', 'cuisines.json', 'metadata.json')]
        before = [hashlib.sha256(p.read_bytes()).hexdigest() for p in files]
        subprocess.run([sys.executable, str(ROOT / 'tool/build_catalog.py')],
                       check=True, capture_output=True, text=True)
        self.assertEqual(before, [hashlib.sha256(p.read_bytes()).hexdigest() for p in files])
        result = subprocess.run([sys.executable, str(ROOT / 'tool/validate_catalog.py')],
                                check=True, capture_output=True, text=True)
        self.assertIn('PASS:', result.stdout)

    def test_branding_is_idempotent_and_preserves_manifest_activity(self):
        with tempfile.TemporaryDirectory(prefix='ge-brand-test-') as temp:
            root = Path(temp)
            (root / 'tool').mkdir()
            shutil.copy2(ROOT / 'tool/apply_native_branding.py', root / 'tool')
            shutil.copytree(ROOT / 'platform_assets', root / 'platform_assets')
            manifest = root / 'android/app/src/main/AndroidManifest.xml'
            manifest.parent.mkdir(parents=True)
            manifest.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:name="${applicationName}" android:label="globaleater" android:icon="@mipmap/ic_launcher"><activity android:name=".MainActivity" android:exported="true"/></application></manifest>''')
            info = root / 'ios/Runner/Info.plist'
            info.parent.mkdir(parents=True)
            info.write_bytes(plistlib.dumps({'CFBundleDisplayName': 'globaleater', 'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)'}))
            for _ in range(2):
                subprocess.run([sys.executable, str(root / 'tool/apply_native_branding.py')],
                               check=True, capture_output=True, text=True)
            application = ET.parse(manifest).getroot().find('application')
            self.assertEqual(application.get(ANDROID + 'label'), 'Global Eater')
            self.assertEqual(application.get(ANDROID + 'allowBackup'), 'false')
            self.assertEqual(application.get(ANDROID + 'name'), '${applicationName}')
            self.assertEqual(application.find('activity').get(ANDROID + 'name'), '.MainActivity')
            self.assertEqual(plistlib.loads(info.read_bytes())['CFBundleDisplayName'], 'Global Eater')
            self.assertTrue((root / 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').is_file())
            self.assertTrue((root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').is_file())


MOCK_ADB = '''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['MOCK_ADB_LOG'], 'a') as f:
    f.write(json.dumps(args) + '\\n')
case = os.environ['MOCK_ADB_CASE']
if args == ['start-server']:
    sys.exit(0)
if args == ['devices']:
    print('List of devices attached')
    if case == 'unauthorized':
        print('PIXEL_A\\tunauthorized')
    elif case in ('multiple', 'explicit'):
        print('PIXEL_A\\tdevice\\nPIXEL_B\\tdevice')
    else:
        print('PIXEL_A\\tdevice')
    sys.exit(0)
if len(args) < 3 or args[0] != '-s':
    sys.exit(20)
command = args[2:]
if command == ['get-state']:
    print('device'); sys.exit(0)
if command == ['shell', 'getprop', 'ro.product.cpu.abilist']:
    print('x86_64' if case == 'wrong-abi' else 'arm64-v8a,armeabi-v7a'); sys.exit(0)
if command[:2] == ['install', '-r']:
    if case == 'signature-conflict':
        print('INSTALL_FAILED_UPDATE_INCOMPATIBLE'); sys.exit(1)
    print('Success'); sys.exit(0)
if command == ['shell', 'am', 'start', '-W', '-n', 'com.bayapps.globaleater/.MainActivity']:
    if case == 'launch-failed':
        print('Error type 3: Activity class does not exist'); sys.exit(0)
    print('Starting: Intent { cmp=com.bayapps.globaleater/.MainActivity }\\nStatus: ok'); sys.exit(0)
if command == ['shell', 'pidof', 'com.bayapps.globaleater']:
    if case == 'startup-crash':
        sys.exit(1)
    print('12345'); sys.exit(0)
sys.exit(21)
'''


class InstallerTests(unittest.TestCase):
    def run_fixture(self, case, serial=None):
        # No real adb can be selected: the script prepends this isolated SDK path.
        with tempfile.TemporaryDirectory(prefix='ge-install-test-') as temp:
            root = Path(temp)
            (root / 'scripts').mkdir()
            shutil.copy2(ROOT / 'scripts/android.sh', root / 'scripts/android.sh')
            (root / 'dist').mkdir()
            # Deliberately not an APK, only a file-existence fixture in /tmp.
            (root / 'dist' / APK_NAME).write_text('TEST FIXTURE ONLY - NOT AN APK')
            adb = root / 'mock-sdk/platform-tools/adb'
            adb.parent.mkdir(parents=True)
            adb.write_text(MOCK_ADB)
            adb.chmod(0o755)
            log = root / 'adb-calls.jsonl'
            env = dict(os.environ, ANDROID_HOME=str(root / 'mock-sdk'),
                       MOCK_ADB_LOG=str(log), MOCK_ADB_CASE=case)
            env.pop('ANDROID_SERIAL', None)
            if serial:
                env['ANDROID_SERIAL'] = serial
            result = subprocess.run(['bash', str(root / 'scripts/android.sh'), '--install-only'],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
            self.assertEqual((root / 'dist/android-build.log').read_text(), result.stdout)
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            return result, calls

    def test_single_authorized_device_installs_and_launches(self):
        result, calls = self.run_fixture('success')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('installed and launched on PIXEL_A', result.stdout)
        self.assertTrue(any(c[:4] == ['-s', 'PIXEL_A', 'install', '-r'] for c in calls))
        self.assertFalse(any('uninstall' in c for c in calls))

    def test_unauthorized_device_stops_without_install(self):
        result, calls = self.run_fixture('unauthorized')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('no authorized device', result.stdout)
        self.assertFalse(any('install' in c for c in calls))

    def test_multiple_devices_require_explicit_selection(self):
        result, calls = self.run_fixture('multiple')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('More than one device', result.stdout)
        self.assertFalse(any('install' in c for c in calls))

    def test_explicit_serial_selects_only_the_named_device(self):
        result, calls = self.run_fixture('explicit', serial='PIXEL_B')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(any(c[:4] == ['-s', 'PIXEL_B', 'install', '-r'] for c in calls))
        self.assertFalse(any(c[:2] == ['-s', 'PIXEL_A'] for c in calls))

    def test_wrong_abi_stops_before_install(self):
        result, calls = self.run_fixture('wrong-abi')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('ARM64 for your Pixel', result.stdout)
        self.assertFalse(any('install' in c for c in calls))

    def test_launch_error_with_zero_exit_does_not_report_success(self):
        result, calls = self.run_fixture('launch-failed')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('did not confirm a successful launch', result.stdout)
        self.assertNotIn('installed and launched on', result.stdout)

    def test_startup_crash_does_not_report_success(self):
        result, calls = self.run_fixture('startup-crash')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('app process is not running', result.stdout)
        self.assertNotIn('installed and launched on', result.stdout)

    def test_signing_conflict_never_uninstalls(self):
        result, calls = self.run_fixture('signature-conflict')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No app was uninstalled', result.stdout)
        self.assertFalse(any('uninstall' in c for c in calls))
        self.assertFalse(any('am' in c for c in calls))


if __name__ == '__main__':
    unittest.main(verbosity=2)
