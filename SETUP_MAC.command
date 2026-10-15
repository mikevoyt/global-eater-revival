#!/bin/bash
# Global Eater: prepare this checkout on a Mac, provision tools, build and install.
# Run from the project folder in Terminal: bash SETUP_MAC.command --build-only
# macOS Bash 3.2 compatible. Never run with sudo. Licenses remain interactive.
set -Eeuo pipefail

fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
step() { printf '\n=== %s ===\n' "$*"; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PROJECT="$HERE"
if [[ ! -f "$HERE/pubspec.yaml" ]]; then DEFAULT_PROJECT="$HOME/Development/global_eater"; fi
PROJECT="${GE_PROJECT_DIR:-$DEFAULT_PROJECT}"
MODE="${1:-all}"
case "$MODE" in
  all|--build-only|--install-only) ;;
  *) fail 'Usage: bash SETUP_MAC.command [--build-only|--install-only]';;
esac
[[ "$(uname -s)" == Darwin ]] || fail 'This launcher must run on your Mac, not a Linux/cloud terminal.'
[[ "$PROJECT" == /* && "$PROJECT" != / ]] || fail 'GE_PROJECT_DIR must be an absolute project-directory path.'
[[ ! -L "$PROJECT" ]] || fail "Refusing a symlink as the project destination: $PROJECT"

# Validate the destination before installing tools or changing existing files.
if [[ -e "$PROJECT" ]]; then
  [[ -d "$PROJECT" && -f "$PROJECT/pubspec.yaml" && -f "$PROJECT/lib/main.dart" &&
     -f "$PROJECT/scripts/android.sh" && -f "$PROJECT/scripts/bootstrap.sh" ]] ||
    fail "Destination already exists but is not this Flutter project. It was left unchanged: $PROJECT"
  grep -Eq '^name:[[:space:]]*global_eater[[:space:]]*$' "$PROJECT/pubspec.yaml" ||
    fail "Destination contains another project; it was left unchanged: $PROJECT"
  printf 'Using existing project without copying over its source: %s\n' "$PROJECT"
else
  [[ $EUID -ne 0 ]] || fail 'Run this as your regular Mac user, not with sudo.'
  SOURCE="$HERE/global_eater"
  [[ -f "$SOURCE/pubspec.yaml" && -f "$SOURCE/scripts/android.sh" ]] ||
    fail 'The bundled global_eater folder is missing. Extract the whole setup ZIP first.'
  mkdir -p "$(dirname "$PROJECT")"
  # mkdir fails rather than merging into a destination created concurrently.
  mkdir "$PROJECT"
  cp -R "$SOURCE/." "$PROJECT/"
  cp "$HERE/SETUP_MAC.command" "$PROJECT/SETUP_MAC.command"
fi
[[ $EUID -ne 0 ]] || fail 'Run this as your regular Mac user, not with sudo.'
cd "$PROJECT"
mkdir -p dist
LOG="$PROJECT/dist/mac-setup.log"
# Keep interactive stdin and logging without relying on /dev/fd substitution.
if [[ "${GE_SETUP_LOGGING_ACTIVE:-}" != 1 ]]; then
  set +e
  GE_SETUP_LOGGING_ACTIVE=1 bash "$HERE/SETUP_MAC.command" "$@" 2>&1 | tee -a "$LOG"
  LOG_STATUS=("${PIPESTATUS[@]}")
  if [[ "${LOG_STATUS[0]}" -ne 0 ]]; then exit "${LOG_STATUS[0]}"; fi
  exit "${LOG_STATUS[1]}"
fi
trap 'code=$?; printf "\nSetup stopped (exit %s). Log: %s\n" "$code" "$LOG" >&2; exit "$code"' ERR
printf '\nGlobal Eater Mac setup — %s\nProject: %s\n' "$(date)" "$PROJECT"
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    step 'Installing Homebrew from its official installer'
    local installer
    installer="$(mktemp "${TMPDIR:-/tmp}/global-eater-brew.XXXXXX")"
    curl --fail --show-error --location --retry 3 --connect-timeout 20 \
      --proto '=https' --tlsv1.2 \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
    # This installer displays its plan and may request your Mac password.
    if ! /bin/bash "$installer"; then
      rm -f "$installer"
      fail 'Homebrew installation did not finish. Rerun this launcher after resolving the displayed error.'
    fi
    rm -f "$installer"
    hash -r
  fi
  command -v brew >/dev/null 2>&1 || fail 'Homebrew is still not available on PATH.'
  eval "$(brew shellenv)"
}

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  fail 'Finish the macOS Command Line Tools installer, then rerun this command. Full Xcode is not needed for Android.'
fi

if ! python3 -c 'import sys; assert sys.version_info >= (3, 10)' >/dev/null 2>&1; then
  ensure_brew
  brew install python
  export PATH="$(brew --prefix)/bin:$PATH"
  hash -r
fi
python3 -c 'import sys; assert sys.version_info >= (3, 10)' || fail 'Python 3.10 or newer is required.'

if ! command -v flutter >/dev/null 2>&1; then
  ensure_brew
  step 'Installing Flutter'
  brew install --cask flutter
  hash -r
fi
command -v flutter >/dev/null 2>&1 || fail 'Flutter is not available after installation.'
FLUTTER_ROOT="$(python3 -c 'from pathlib import Path; import shutil; print(Path(shutil.which("flutter")).resolve().parent.parent)')"
[[ -f "$FLUTTER_ROOT/packages/flutter_tools/pubspec.yaml" ]] ||
  fail 'The flutter command is a wrapper, not a direct SDK executable. Put the intended Flutter SDK bin directory first on PATH and rerun.'
# Retain the same SDK throughout this run, including when Homebrew is loaded later.

STUDIO="${GE_ANDROID_STUDIO:-}"
if [[ -z "$STUDIO" ]]; then
  for candidate in '/Applications/Android Studio.app' "$HOME/Applications/Android Studio.app"; do
    if [[ -d "$candidate" ]]; then STUDIO="$candidate"; break; fi
  done
fi
if [[ -z "$STUDIO" ]]; then
  ensure_brew
  step 'Installing Android Studio'
  brew install --cask android-studio
  STUDIO='/Applications/Android Studio.app'
fi
[[ -d "$STUDIO" ]] || fail "Android Studio app not found: $STUDIO"
export JAVA_HOME="$STUDIO/Contents/jbr/Contents/Home"
[[ -x "$JAVA_HOME/bin/java" ]] || fail "Android Studio's bundled Java was not found at $JAVA_HOME. Finish installing the stable Android Studio app."
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
[[ "$ANDROID_HOME" == /* ]] || fail 'ANDROID_HOME must be an absolute path.'
mkdir -p "$ANDROID_HOME"
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$SDKMANAGER" ]]; then
  if command -v sdkmanager >/dev/null 2>&1; then
    SDKMANAGER="$(command -v sdkmanager)"
  else
    ensure_brew
    step 'Installing Android command-line tools'
    brew install --cask android-commandlinetools
    SDKMANAGER="$(brew --prefix)/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager"
  fi
fi
[[ -x "$SDKMANAGER" ]] || fail 'Android sdkmanager was not found after installation.'
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

step 'Configuring Flutter to use Android Studio and its SDK/Java'
if [[ ! -e dist/flutter-config-before.txt ]]; then
  flutter config --list > dist/flutter-config-before.txt
fi
flutter config --android-sdk "$ANDROID_HOME" --android-studio-dir "$STUDIO" --jdk-dir "$JAVA_HOME"
flutter --version

# Read the selected Flutter SDK's Android requirements instead of pinning stale
# native project templates. API 36 is the documented fallback as of Oct 14, 2026.
python3 - "$FLUTTER_ROOT" > dist/flutter-android-requirements.txt <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1]) / 'packages/flutter_tools/gradle'
paths = [root/'src/main/kotlin/FlutterExtension.kt', root/'src/main/groovy/flutter.groovy']
text = '\n'.join(p.read_text(encoding='utf-8') for p in paths if p.exists())
api = re.search(r'compileSdkVersion\s*(?::\s*Int)?\s*=\s*(\d+)', text)
ndk = re.search(r'''ndkVersion\s*(?::\s*String)?\s*=\s*["']([\d.]+)["']''', text)
print(api.group(1) if api else '36')
print(ndk.group(1) if ndk else '')
if not api:
    print('NOTE: Flutter compile SDK value was not found; using documented API 36. Gradle may install another required SDK.', file=sys.stderr)
PY
API="${GE_ANDROID_API:-$(sed -n '1p' dist/flutter-android-requirements.txt)}"
NDK="$(sed -n '2p' dist/flutter-android-requirements.txt)"
[[ "$API" =~ ^[0-9]+$ ]] || fail 'Invalid Android API level.'

step 'Review Android SDK licenses in this Terminal window'
printf 'Read and accept the required SDK licenses at the prompts. They are not accepted automatically.\n'
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" --list > dist/android-sdk-packages.txt
BUILD_TOOLS="${GE_BUILD_TOOLS:-$(python3 - dist/android-sdk-packages.txt "$API" <<'PY'
from pathlib import Path
import re, sys
versions = set(re.findall(r'build-tools;(\d+\.\d+\.\d+)(?=\s|\||$)', Path(sys.argv[1]).read_text()))
matching = [v for v in versions if v.split('.')[0] == sys.argv[2]]
if not (matching or versions):
    raise SystemExit('No stable Android Build-Tools packages were listed. Check the SDK network/download error above.')
print(max(matching or versions, key=lambda v: tuple(map(int, v.split('.')))))
PY
)}"
PACKAGES=("cmdline-tools;latest" 'platform-tools' "platforms;android-$API" "build-tools;$BUILD_TOOLS")
if [[ -n "$NDK" ]]; then PACKAGES+=("ndk;$NDK"); fi
step "Installing Android SDK packages for API $API"
printf '  %s\n' "${PACKAGES[@]}"
"$SDKMANAGER" --sdk_root="$ANDROID_HOME" "${PACKAGES[@]}"
# Gradle can install additional exact NDK/CMake/Build-Tools versions when needed,
# subject to the SDK licenses you have accepted.

# A project-local environment helper; no shell startup files are edited.
if [[ ! -e scripts/mac-env.sh ]]; then
  {
    printf '#!/bin/bash\n# Generated by the Global Eater Mac setup launcher.\n'
    printf 'export JAVA_HOME=%q\n' "$JAVA_HOME"
    printf 'export ANDROID_HOME=%q\n' "$ANDROID_HOME"
    printf 'export ANDROID_SDK_ROOT=%q\n' "$ANDROID_HOME"
    printf 'export PATH=%q:"$PATH"\n' "$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
  } > scripts/mac-env.sh
fi

step 'Checking the Pixel connection'
adb start-server
adb devices -l
printf '\nUnlock the Pixel and approve USB debugging if prompted. A bootloader unlock is NOT required.\n'
if [[ "$MODE" != '--install-only' ]]; then
  flutter precache --android
  python3 -m unittest discover -s tool -p 'test_*.py' -v
fi

step 'Building, checking, and installing Global Eater'
# Use the existing project pipeline. It rejects ambiguous devices and never
# automatically uninstalls an existing application.
BUILD_RESULT=0
bash scripts/android.sh "$MODE" || BUILD_RESULT=$?
# SDK provisioning and compilation are command-line driven; open the actual
# workspace in Android Studio for editing and the next iteration.
open -a "$STUDIO" "$PROJECT" || printf 'Android Studio did not open automatically; open the project folder manually.\n'
printf '\nFor Flutter editing/run controls in Android Studio, install its Flutter plugin\n'
printf 'under Settings > Plugins if it is not already installed (allow the Dart dependency).\n'
printf 'Flutter SDK path: %s\n' "$FLUTTER_ROOT"
if [[ "$BUILD_RESULT" -ne 0 ]]; then
  printf '\nBuild/install did not finish. Logs:\n  %s\n  %s/dist/android-build.log\n' "$LOG" "$PROJECT" >&2
  printf 'After fixing USB authorization only, retry from the project directory:\n'
  printf '  source scripts/mac-env.sh && bash scripts/android.sh --install-only\n'
  exit "$BUILD_RESULT"
fi
printf '\nProject: %s\nAPK: %s/dist/GlobalEater-0.1.0-android-arm64-debug.apk\n' "$PROJECT" "$PROJECT"
if [[ "$MODE" == '--build-only' ]]; then
  printf 'Build-only completed. Nothing was installed on a phone.\n'
else
  printf 'Build/install pipeline completed. Check Global Eater on your Pixel.\n'
fi
