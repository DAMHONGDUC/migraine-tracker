#!/bin/sh
# Wipe Android + iOS build artefacts. Follow with `melos run setup`.
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

# Xcode caches precompiled modules against the modulemap it saw at the time.
# Bump a Firebase plugin and the modulemap under build/ changes while the .pcm
# in DerivedData does not, and the build dies with "has been modified since the
# module file was built" — which `flutter clean` alone never fixes, because
# DerivedData lives outside the repo.
if [ "$(uname)" = "Darwin" ] && command -v plutil >/dev/null 2>&1; then
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

# Suppressed when `setup --deepclean` chained this, since setup runs next.
if [ -z "${MELOS_CHAINED_CLEAN:-}" ]; then
  done_msg "Now run: melos run setup"
fi
