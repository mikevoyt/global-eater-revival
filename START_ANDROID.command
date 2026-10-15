#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
bash scripts/android.sh
result=$?
printf '\nPress Return to close this window. '
read -r _
exit "$result"
