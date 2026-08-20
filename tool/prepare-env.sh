#!/bin/sh
# Install one environment's Firebase and RevenueCat config where the build
# reads it.
#
#   sh tool/prepare-env.sh <dev|prod>
#
# Sources live in `env_assets/` — the same live keys `env/` holds, so it is
# gitignored and yours alone. This script is the only record of which file
# goes where; by hand it is four `cp`s from memory, and the forgotten one
# fails a build with a Firebase error naming none of this.
#
# It copies bytes and never reads them (hard rule 13).
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

# `<source under env_assets>|<destination>`, newline separated so the default
# IFS splits it; no path here has a space.
#
# Both env/*.json go every time: one destination each, so there is nothing to
# choose. The target picks only the three native files, and their destinations
# carry no dev-/prod- prefix on purpose — those exact paths are what the
# google-services gradle plugin and the Runner target read. A prefixed copy
# beside them is a file nothing opens.
#
# Info.plist is in that list because it carries the Google sign-in URL scheme,
# which is the reversed client id of whichever Firebase project this checkout
# is pointed at — a dev GoogleService-Info.plist beside a prod URL scheme
# builds fine and drops the sign-in callback on the floor at runtime.
PAIRS="
dev.json|env/dev.json
prod.json|env/prod.json
$TARGET-google-services.json|android/app/google-services.json
$TARGET-GoogleService-Info.plist|ios/Runner/GoogleService-Info.plist
$TARGET-Info.plist|ios/Runner/Info.plist
"

# All checked before anything is written: a run that copies two files and dies
# on the third leaves a tree half this environment and half the last one, and
# nothing on disk says so.
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
