#!/bin/sh
# Build an iOS release archive for one environment, with its config attached.
#
#   sh tool/release-ios.sh <dev|prod> [extra `flutter build ipa` args...]
#
# This exists because Xcode's own Product > Archive cannot work here: the
# app's Firebase and RevenueCat values arrive through
# `--dart-define-from-file`, which Xcode knows nothing about. An archive made
# that way carries empty config, `Firebase.initializeApp` throws, main()
# swallows it, and the app then dies on the first `FirebaseAuth.instance` with
# "No Firebase App '[DEFAULT]' has been created" — a crash that names nothing
# to do with the missing flag.
#
# The assert in main() does NOT catch this: Dart strips asserts from release
# builds, which is exactly where the mistake happens.
set -eu
. "$(dirname "$0")/_common.sh"

TARGET="${1:-}"
[ $# -gt 0 ] && shift

# dev defaults to ad-hoc so the build installs on a device without a
# TestFlight round trip; prod defaults to the App Store export. Either can be
# overridden by passing --export-method through.
case "$TARGET" in
  dev)
    ENV_FILE="env/dev.json"
    EXPORT_METHOD="ad-hoc"
    ;;
  prod)
    ENV_FILE="env/prod.json"
    EXPORT_METHOD="app-store"
    ;;
  *)
    warn "usage: release-ios.sh <dev|prod> [flutter build ipa args...]"
    exit 1
    ;;
esac

# Existence only — never the contents (hard rule 13).
if [ ! -f "$ENV_FILE" ]; then
  warn "$ENV_FILE is missing. Run: melos run set-up"
  exit 1
fi

# Both environments write to the same folder under the same filename, so a
# stale IPA from the other one is indistinguishable from this build's. Clear
# it first and there is exactly one file, and it is the one just built.
IPA_DIR="build/ios/ipa"
rm -rf "$IPA_DIR"

step "ios release archive — $TARGET ($ENV_FILE), export $EXPORT_METHOD"
$FL build ipa \
  --release \
  --dart-define-from-file="$ENV_FILE" \
  --export-method "$EXPORT_METHOD" \
  "$@"

done_msg "Built $TARGET from $ENV_FILE into $IPA_DIR."
warn "App Store Connect refuses a build number it has already seen — pass --build-number to bump it."
