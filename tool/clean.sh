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

done_msg "Now run: melos run setup"
