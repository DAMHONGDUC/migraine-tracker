#!/bin/sh
# Install one environment's Firebase, RevenueCat and Cloud Functions config where each is read, plus the unflavored files both share.
set -eu
. "$(dirname "$0")/_common.sh"

SRC="env_assets"

TARGET="${1:-}"
case "$TARGET" in
  dev | prod) ;;
  *)
    warn "usage: prepare-env.sh <dev|prod>"
    exit 1
    ;;
esac

if [ ! -d "$SRC" ]; then
  warn "$SRC/ is missing. It is gitignored, so a clone never has it —"
  warn "restore your own copy before running this."
  exit 1
fi

# `<source under env_assets>|<destination>`, newline separated so the default IFS splits it; no path here has a space.
PAIRS="
$TARGET.json|env/$TARGET.json
fastlane.env|ios/fastlane/.env
$TARGET-google-services.json|android/app/google-services.json
$TARGET-GoogleService-Info.plist|ios/Runner/GoogleService-Info.plist
$TARGET-Info.plist|ios/Runner/Info.plist
$TARGET-function.env|functions/.env
"

# All checked before anything is written.
MISSING=""
for pair in $PAIRS; do
  SRC_FILE="$SRC/${pair%%|*}"
  [ -f "$SRC_FILE" ] || MISSING="$MISSING $SRC_FILE"
done

if [ -n "$MISSING" ]; then
  warn "Missing in $SRC/:$MISSING"
  warn "Nothing was copied."
  exit 1
fi

step "env config — $TARGET, from $SRC/"
for pair in $PAIRS; do
  SRC_FILE="$SRC/${pair%%|*}"
  DST_FILE="${pair#*|}"
  cp "$SRC_FILE" "$DST_FILE"
  printf '    %s -> %s\n' "$SRC_FILE" "$DST_FILE"
done

done_msg "Installed $TARGET config. Run with --dart-define-from-file=env/$TARGET.json."
# functions/.env is read by the Firebase CLI at deploy time, not by the app.
warn "functions/.env reaches the backend only on the next deploy-firebase-$TARGET."
