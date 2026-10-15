#!/usr/bin/env bash
# Build and install on one explicitly selected/uniquely connected Android device.
# Compatible with the macOS system Bash (3.2). Does not uninstall existing apps.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MODE="${1:-all}"
case "$MODE" in
  all|--build-only|--install-only) ;;
  *) echo 'Usage: bash scripts/android.sh [--build-only|--install-only]' >&2; exit 2;;
esac
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
if [[ -z "${ANDROID_HOME:-}" ]]; then
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
  elif [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
  elif [[ -d "$HOME/Android/Sdk" ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
  fi
fi
if [[ -n "${ANDROID_HOME:-}" ]]; then
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
if [[ -z "${JAVA_HOME:-}" && -d '/Applications/Android Studio.app/Contents/jbr/Contents/Home' ]]; then
  export JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
  export PATH="$JAVA_HOME/bin:$PATH"
fi
APK="$ROOT/dist/GlobalEater-0.1.0-android-arm64-debug.apk"
mkdir -p dist
# A normal pipeline also works where /dev/fd process substitution is unavailable.
# Re-enter once with stdin preserved for tools that prompt, then wait for tee so
# the log is complete before returning the build/install command's exit status.
if [[ "${GE_ANDROID_LOGGING_ACTIVE:-}" != 1 ]]; then
  set +e
  GE_ANDROID_LOGGING_ACTIVE=1 bash "$ROOT/scripts/android.sh" "$@" 2>&1 | tee -a "$ROOT/dist/android-build.log"
  LOG_STATUS=("${PIPESTATUS[@]}")
  if [[ "${LOG_STATUS[0]}" -ne 0 ]]; then exit "${LOG_STATUS[0]}"; fi
  exit "${LOG_STATUS[1]}"
fi
trap 'printf "\nStopped after an error. Details: %s/dist/android-build.log\n" "$ROOT" >&2' ERR
printf '\n=== Global Eater · %s ===\n' "$(date)"
if [[ "$MODE" != '--install-only' ]]; then
  if ! command -v flutter >/dev/null 2>&1; then
    printf '\nFlutter is not on PATH. Install it, then rerun this script:\n'
    printf '  brew install --cask flutter\n\n'
    printf 'Android Studio and its Android SDK are also needed. See README.md.\n'
    exit 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo 'Python 3 is missing. Install it with: brew install python'; exit 1
  fi
  bash scripts/bootstrap.sh
  flutter doctor -v
  python3 tool/validate_catalog.py
  flutter pub get
  # Lint suggestions are nonfatal; compilation/analyzer warnings and errors fail.
  flutter analyze --no-fatal-infos
  flutter test
  flutter build apk --debug --target-platform android-arm64
  cp build/app/outputs/flutter-apk/app-debug.apk "$APK"
  flutter --version > dist/flutter-version.txt
  python3 - "$APK" <<'PY'
import hashlib, pathlib, sys
p = pathlib.Path(sys.argv[1])
(p.parent/'SHA256SUMS.txt').write_text(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n')
print('\nAPK created: '+str(p))
PY
fi
if [[ "$MODE" == '--build-only' ]]; then
  echo "Build complete. APK: $APK"
  exit 0
fi
[[ -f "$APK" ]] || { echo 'No APK exists yet. Run this script without --install-only first.'; exit 1; }
command -v adb >/dev/null 2>&1 || {
  echo 'adb is missing. Install Android SDK Platform-Tools in Android Studio, or: brew install --cask android-platform-tools'
  exit 1
}
adb start-server
DEVICES="$(adb devices)"
printf '\n%s\n' "$DEVICES"
SERIAL="${ANDROID_SERIAL:-}"
if [[ -z "$SERIAL" ]]; then
  AVAILABLE="$(printf '%s\n' "$DEVICES" | awk 'NR>1 && $2=="device" {print $1}')"
  COUNT="$(printf '%s\n' "$AVAILABLE" | awk 'NF {n++} END {print n+0}')"
  if [[ "$COUNT" -eq 0 ]]; then
    printf '\nAPK is built, but no authorized device is connected.\n'
    printf 'Unlock your Pixel, enable USB debugging, connect a data-capable USB cable,\n'
    printf 'and approve the USB debugging prompt. Then run:\n'
    printf '  bash scripts/android.sh --install-only\n'
    exit 1
  elif [[ "$COUNT" -gt 1 ]]; then
    printf '\nMore than one device is connected. Choose your Pixel explicitly:\n'
    printf '  ANDROID_SERIAL=YOUR_PIXEL_SERIAL bash scripts/android.sh --install-only\n'
    exit 1
  fi
  SERIAL="$AVAILABLE"
fi
if [[ "$(adb -s "$SERIAL" get-state 2>/dev/null || true)" != 'device' ]]; then
  echo "Device $SERIAL is not authorized or is offline."; exit 1
fi
ABI="$(adb -s "$SERIAL" shell getprop ro.product.cpu.abilist | tr -d '\r')"
case "$ABI" in
  *arm64-v8a*) ;;
  *) echo "This APK is ARM64 for your Pixel. Device ABIs: $ABI"; exit 1;;
esac
if ! adb -s "$SERIAL" install -r "$APK"; then
  echo 'Installation failed. No app was uninstalled.'
  echo 'A signing-key conflict requires the previous key or your explicit decision to uninstall.'
  echo 'Uninstalling would delete that app’s local saved items.'
  exit 1
fi
LAUNCH_OUTPUT="$(adb -s "$SERIAL" shell am start -W -n com.bayapps.globaleater/.MainActivity 2>&1)" || {
  printf '%s\n' "$LAUNCH_OUTPUT"
  echo 'APK installed, but the launch command failed.'
  exit 1
}
printf '%s\n' "$LAUNCH_OUTPUT"
if ! printf '%s\n' "$LAUNCH_OUTPUT" | grep -Eq '^[[:space:]]*Status:[[:space:]]*ok[[:space:]]*$'; then
  echo 'APK installed, but Android did not confirm a successful launch.'
  exit 1
fi
if ! adb -s "$SERIAL" shell pidof com.bayapps.globaleater >/dev/null 2>&1; then
  echo 'APK installed, but the app process is not running. Inspect adb logcat for a startup crash.'
  exit 1
fi
printf '\nGlobal Eater installed and launched on %s. You can disconnect USB.\n' "$SERIAL"
