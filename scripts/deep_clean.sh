#!/usr/bin/env bash
# Deep clean Android + iOS, then restore.

# Usage: sh ./scripts/deep_clean.sh

set -euo pipefail

cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

# Colour only on a terminal — piping to a file or CI log keeps it plain.
if [[ -t 1 ]]; then
  CYAN=$'\033[1;36m'; GREEN=$'\033[1;32m'; YELLOW=$'\033[0;33m'; OFF=$'\033[0m'
else
  CYAN=''; GREEN=''; YELLOW=''; OFF=''
fi

step() { printf '\n%s==> %s%s\n' "$CYAN" "$1" "$OFF"; }
warn() { printf '%s    %s%s\n' "$YELLOW" "$1" "$OFF"; }

# `flutter` is a shell alias for `fvm flutter` here, and aliases don't exist
# in scripts — resolve it explicitly or we run the wrong SDK.
if [[ -f .fvmrc ]] && command -v fvm >/dev/null; then
  FLUTTER=(fvm flutter); DART=(fvm dart)
else
  FLUTTER=(flutter); DART=(dart)
fi

step "flutter clean"
"${FLUTTER[@]}" clean

step "android"
if [[ -x android/gradlew ]]; then
  (cd android && ./gradlew clean) || warn "gradlew clean failed, continuing"
else
  warn "android/gradlew missing or not executable — skipped"
fi
rm -rf android/.gradle android/build android/app/build

step "ios"
# SPM project
rm -rf ios/.symlinks ios/Flutter/ephemeral

step "flutter pub get"
"${FLUTTER[@]}" pub get

step "gen code"
"${DART[@]}" run build_runner build

printf '\n%s==> done%s\n' "$GREEN" "$OFF"
