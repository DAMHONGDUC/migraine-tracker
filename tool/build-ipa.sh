#!/bin/sh
# Build an iOS release archive for one environment, with its config attached.
set -eu
. "$(dirname "$0")/_common.sh"

TARGET="${1:-}"
[ $# -gt 0 ] && shift

# Both go to TestFlight, so both export app-store — it is the only method App Store Connect accepts. Override with --export-method to sideload one.
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

# `--export-method` makes Flutter generate the ExportOptions.plist itself, and that generator maps the MAIN bundle id only.
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

# Gitignored, and a build input of the Runner target rather than a runtime lookup.
GSP="ios/Runner/GoogleService-Info.plist"
if [ ! -f "$GSP" ]; then
  warn "$GSP is missing — download it from the Firebase console (iOS app)."
  warn "On CI it is written from the GOOGLE_SERVICE_INFO_PLIST secret."
  exit 1
fi

# Both environments write to the same folder under the same filename, so a stale IPA from the other one is indistinguishable from this build's.
IPA_DIR="build/ios/ipa"
rm -rf "$IPA_DIR"

# Version and build number are edited in pubspec.yaml, never passed as a flag: `--build-number` ships a build whose version exists nowhere in git.
VERSION=$(grep '^version:' pubspec.yaml | head -1 | cut -d' ' -f2)

step "ios release archive — $TARGET ($ENV_FILE), version $VERSION, export $EXPORT_METHOD"
$FL build ipa \
  --release \
  --dart-define-from-file="$ENV_FILE" \
  "$@"

done_msg "Built $TARGET $VERSION from $ENV_FILE into $IPA_DIR."
done_msg "Upload the .ipa there with Transporter, or from Xcode Organizer."
# Both environments share one bundle id, so both land in the SAME TestFlight app and the build number is the only thing telling them apart.
warn "Bump version: in pubspec.yaml before the next build — App Store Connect refuses a build number it has already seen."
