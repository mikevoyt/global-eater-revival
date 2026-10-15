#!/usr/bin/env bash
# Generate native hosts from your installed Flutter SDK, without touching lib/.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v flutter >/dev/null 2>&1 || { echo 'Flutter is missing. See README.md.' >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo 'Python 3 is required for project setup.' >&2; exit 1; }
if [[ ! -f android/gradlew || ! -d ios/Runner.xcodeproj ]]; then
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/global-eater.XXXXXX")"
  trap 'rm -rf "$TMP"' EXIT
  flutter create --empty --no-pub --platforms=android,ios \
    --org com.bayapps --project-name globaleater --android-language kotlin "$TMP/globaleater"
  if [[ ! -f android/gradlew ]]; then
    if [[ -d android ]]; then
      echo 'android/ exists but is incomplete. Move it aside before bootstrapping; it was not overwritten.' >&2
      exit 1
    fi
    cp -R "$TMP/globaleater/android" "$ROOT/android"
  fi
  if [[ ! -d ios/Runner.xcodeproj ]]; then
    if [[ -d ios ]]; then
      echo 'ios/ exists but is incomplete. Move it aside before bootstrapping; it was not overwritten.' >&2
      exit 1
    fi
    cp -R "$TMP/globaleater/ios" "$ROOT/ios"
  fi
  if [[ ! -f .metadata ]]; then cp "$TMP/globaleater/.metadata" .metadata; fi
fi
python3 tool/apply_native_branding.py
chmod +x android/gradlew
printf '\nNative hosts ready. App ID: com.bayapps.globaleater\n'
