#!/bin/sh
# Build an iOS release archive for one environment, with its config attached.
#
#   sh tool/build-ipa.sh <dev|prod> [extra `flutter build ipa` args...]
#
# It builds and nothing else. Uploading is the fastlane lane's job — hence the
# name: `release-ios` claimed a release this script never performed.
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

# Both go to TestFlight, so both export app-store — it is the only method
# App Store Connect accepts. Override with --export-method to sideload one.
case "$TARGET" in
  dev)
    ENV_FILE="env/dev.json"
    ;;
  prod)
    ENV_FILE="env/prod.json"
    ;;
  *)
    warn "usage: build-ipa.sh <dev|prod> [flutter build ipa args...]"
    exit 1
    ;;
esac

EXPORT_METHOD="app-store"

# `--export-method` makes Flutter generate the ExportOptions.plist itself, and
# that generator maps the MAIN bundle id only — its own source calls
# multi-target apps a TODO. This app has two: Runner and
# BaroEaseWidgetExtension. With automatic signing (a developer's Mac) that
# never shows, because Xcode resolves the extension's profile on its own; with
# manual signing (CI) the extension gets no profile and `exportArchive` fails
# after the whole build has run.
#
# So a caller may pass its own `--export-options-plist` naming both. Flutter
# refuses that flag together with `--export-method`, so drop ours when it does.
EXPORT_PLIST_GIVEN=0
for arg in "$@"; do
  case "$arg" in
    --export-options-plist | --export-options-plist=*) EXPORT_PLIST_GIVEN=1 ;;
  esac
done

if [ "$EXPORT_PLIST_GIVEN" -eq 0 ]; then
  set -- --export-method "$EXPORT_METHOD" "$@"
else
  EXPORT_METHOD="caller's --export-options-plist"
fi

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

# Version and build number are edited in pubspec.yaml, never passed as a
# flag: `--build-number` ships a build whose version exists nowhere in git.
# So print what is about to go out, and let the number speak for itself.
VERSION=$(grep '^version:' pubspec.yaml | head -1 | cut -d' ' -f2)

step "ios release archive — $TARGET ($ENV_FILE), version $VERSION, export $EXPORT_METHOD"
$FL build ipa \
  --release \
  --dart-define-from-file="$ENV_FILE" \
  "$@"

done_msg "Built $TARGET $VERSION from $ENV_FILE into $IPA_DIR."
done_msg "Upload the .ipa there with Transporter, or from Xcode Organizer."
# Both environments share one bundle id, so both land in the SAME TestFlight
# app and the build number is the only thing telling them apart.
warn "Bump version: in pubspec.yaml before the next build — App Store Connect refuses a build number it has already seen."
