#!/bin/sh
# Everything a fresh clone needs, in order. Safe to re-run.
#
# Always wipes first (tool/_clean.sh: flutter clean, gradle, pods), so set-up
# is the one answer to "it built yesterday and not today". Xcode's DerivedData
# is deliberately NOT part of it — clearing that costs a full cold build, and
# lives in `melos run deep-set-up` for when a stale module cache is the actual
# problem. Reach for `melos run gen` when all you changed is a table or a
# string.
set -eu
. "$(dirname "$0")/_common.sh"

sh "$(dirname "$0")/_clean.sh"

# Submodules land on their branch and follow it, rather than sitting detached
# at the commit the gitlink records. That is deliberate: the design system is
# developed alongside this app, and nobody wants to remember to
# `git checkout main` inside it before every edit.
#
# The cost is real, so know it: after this, what you build is whatever is on
# the submodule's branch, NOT what the parent commit pins. The parent shows
# `packages/system_design` as modified the moment the branch moves ahead of
# the gitlink — commit that gitlink when you mean to, and never assume a past
# parent commit rebuilds byte-for-byte.
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
# build_runner 2.15 removed --delete-conflicting-outputs; it deletes them
# by default now, and passing it warns on every run.
$DT run build_runner build

# env/*.json is gitignored (Firebase + RevenueCat keys), so a fresh clone has
# none. Lay down the key-only templates and say so loudly.
step "env config"
MISSING=""
for f in dev prod; do
  if [ ! -f "env/$f.json" ]; then
    cp "env/$f.example.json" "env/$f.json"
    MISSING="$MISSING env/$f.json"
  fi
done

if [ -d functions ] && command -v npm >/dev/null 2>&1; then
  step "cloud functions"
  (cd functions && npm ci --silent)
fi

# `health` pins an old device_info with no Swift Package, so iOS still needs
# CocoaPods for that one plugin. See CLAUDE.md.
if [ "$(uname)" = "Darwin" ] && [ -f ios/Podfile ] && command -v pod >/dev/null 2>&1; then
  step "ios pods"
  # CocoaPods is Ruby, and Ruby without a UTF-8 locale reads the Podfile as
  # ASCII-8BIT and dies inside its own error reporter — a stack trace that
  # says nothing about the missing LANG.
  #
  # Forced, not defaulted: a LANG that is set but not UTF-8 (LANG=C, a
  # stripped CI environment, a terminal configured for another charset)
  # breaks it exactly the same way, and only an unset one used to be caught.
  case "${LANG:-}" in
    *UTF-8 | *utf8) ;;
    *) LANG=en_US.UTF-8 ;;
  esac
  export LANG
  $FL precache --ios
  # - Warnings on stderr, and melos labels every stderr line "ERROR:", which
  #   makes a clean run read as a failed one.
  # - CocoaPods writes two here that cannot be silenced at the source: a Ruby
  #   gem note, and Firebase's own CocoaPods-deprecation notice.
  # - Folding them into stdout loses nothing: `set -e` still stops the script
  #   on a real failure, and the message is still printed either way.
  (cd ios && pod install 2>&1)
fi

if [ -n "$MISSING" ]; then
  printf '\n'
  warn "Created from templates:$MISSING"
  warn "Fill in the Firebase and RevenueCat keys before running."
fi
