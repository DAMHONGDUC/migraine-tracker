#!/bin/sh
# The wipe, shared by set-up and deep-set-up. Underscore-prefixed like
# _common.sh: not a melos command, never run on its own.
#
# Clears Xcode's DerivedData too, but only when MELOS_CLEAN_DERIVED is set,
# which is the single thing deep-set-up adds over set-up.
set -eu
. "$(dirname "$0")/_common.sh"

step "flutter clean"
$FL clean

step "android"
if [ -x android/gradlew ]; then
  (cd android && ./gradlew clean) || warn "gradlew clean failed, continuing"
fi
rm -rf android/.gradle android/build android/app/build

step "ios"
rm -rf ios/.symlinks ios/Flutter/ephemeral ios/Pods ios/Podfile.lock

# Only for `melos run deep-set-up`, which sets this. Xcode caches precompiled
# modules against the modulemap it saw at the time: bump a Firebase plugin and
# the modulemap under build/ changes while the .pcm in DerivedData does not,
# and the build dies with "has been modified since the module file was built".
# `flutter clean` never fixes that, because DerivedData lives outside the repo
# — but clearing it costs a full cold build, so it stays opt-in.
if [ -n "${MELOS_CLEAN_DERIVED:-}" ] && [ "$(uname)" = "Darwin" ] &&
  command -v plutil >/dev/null 2>&1; then
  step "xcode deriveddata"
  DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
  REPO=$(pwd)
  if [ -d "$DERIVED" ]; then
    # Matched on the workspace path each cache records, never on the folder
    # name: every Flutter app builds a target called Runner, so `Runner-*`
    # would take other projects' caches down with it.
    for dir in "$DERIVED"/*/; do
      [ -f "$dir/info.plist" ] || continue
      workspace=$(plutil -extract WorkspacePath raw -o - "$dir/info.plist" \
        2>/dev/null) || continue
      case "$workspace" in
        "$REPO"/*)
          rm -rf "$dir"
          echo "    removed $(basename "$dir")"
          ;;
      esac
    done
  fi
fi

