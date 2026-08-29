#!/bin/sh
# Everything a fresh clone needs, in order.
set -eu
. "$(dirname "$0")/_common.sh"

sh "$(dirname "$0")/_clean.sh"

# Submodules land on their branch and follow it, rather than sitting detached at the commit the gitlink records.
step "submodules"
git submodule update --init --recursive
git submodule foreach --quiet --recursive '
  branch=$(git config -f "$toplevel/.gitmodules" "submodule.$name.branch" || echo main)
  if ! git checkout -q "$branch" 2>/dev/null; then
    echo "    $name: cannot switch to $branch (uncommitted changes?), left as is"
  elif ! git pull -q --ff-only origin "$branch" 2>/dev/null; then
    echo "    $name: on $branch, but not fast-forwardable — pull it by hand"
  else
    echo "    $name -> $branch"
  fi
'

step "dependencies"
$FL pub get
(cd packages/system_design && $FL pub get)

step "localizations"
$FL gen-l10n

step "code generation"
# build_runner 2.15 removed --delete-conflicting-outputs; it deletes them by default now, and passing it warns on every run.
$DT run build_runner build

# env/*.json is gitignored (Firebase + RevenueCat keys), so a fresh clone has none. Lay down the key-only templates and say so loudly.
step "env config"
MISSING=""
for f in dev prod; do
  if [ ! -f "env/$f.json" ]; then
    cp "env/$f.example.json" "env/$f.json"
    MISSING="$MISSING env/$f.json"
  fi
done

# The Firebase CLI reads this at deploy, and melos pipes stdout so it cannot prompt for the values — an absent file fails the deploy rather than asking.
if [ -f functions/.env.example ] && [ ! -f functions/.env ]; then
  cp functions/.env.example functions/.env
  MISSING="$MISSING functions/.env"
fi

if [ -d functions ] && command -v npm >/dev/null 2>&1; then
  step "cloud functions"
  (cd functions && npm ci --silent)
fi

# `health` pins an old device_info with no Swift Package, so iOS still needs CocoaPods for that one plugin. See CLAUDE.md.
if [ "$(uname)" = "Darwin" ] && [ -f ios/Podfile ] && command -v pod >/dev/null 2>&1; then
  step "ios pods"
  # CocoaPods is Ruby, and Ruby without a UTF-8 locale reads the Podfile as ASCII-8BIT and dies inside its own error reporter.
  case "${LANG:-}" in
    *UTF-8 | *utf8) ;;
    *) LANG=en_US.UTF-8 ;;
  esac
  export LANG
  $FL precache --ios
  # - Warnings on stderr, and melos labels every stderr line "ERROR:", which makes a clean run read as a failed one.
  (cd ios && pod install 2>&1)
fi

if [ -n "$MISSING" ]; then
  printf '\n'
  warn "Created from templates:$MISSING"
  warn "Fill in the Firebase and RevenueCat keys before running."
fi
