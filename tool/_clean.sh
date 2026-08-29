#!/bin/sh
# The wipe, shared by set-up and deep-set-up.
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

# Only for `melos run deep-set-up`, which sets this.
if [ -n "${MELOS_CLEAN_DERIVED:-}" ] && [ "$(uname)" = "Darwin" ] &&
  command -v plutil >/dev/null 2>&1; then
  step "xcode deriveddata"
  DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
  REPO=$(pwd)
  if [ -d "$DERIVED" ]; then
    # Matched on the workspace path each cache records, never on the folder name.
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

