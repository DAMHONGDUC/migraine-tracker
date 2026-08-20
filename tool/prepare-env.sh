#!/bin/sh
# Install one environment's Firebase and RevenueCat config into the four
# places the build actually reads them from.
#
#   sh tool/prepare-env.sh <dev|prod>
#
# The sources live in `env_assets/`, a folder you keep on your own machine —
# gitignored for the same reason `env/` is (hard rule 13: these are live
# keys). This script is the single place that records which file lands where,
# because doing it by hand is four `cp`s from memory and the one that gets
# forgotten is always the one the current task does not immediately need.
#
# It copies bytes and never reads them. Nothing here prints, greps or diffs a
# config file, and nothing added to it may either.
#
# Both `env/*.json` are written whatever the target is: they have one
# destination each, so there is no choice to make. The target picks only the
# two native files, which have exactly one destination each on the other
# side — `android/app/google-services.json` is the path the google-services
# gradle plugin reads, and `ios/Runner/GoogleService-Info.plist` is the path
# the Runner target has in its Resources build phase. A `dev-` prefixed copy
# sitting next to it is a file the app never opens.
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
  warn "restore it from your own copy, or rebuild it from the Firebase"
  warn "console and RevenueCat before running this."
  exit 1
fi

# `<source under env_assets>|<destination>`, split on the pipe below. Newline
# separated so the default IFS splits it, and no path here has a space in it.
PAIRS="
dev.json|env/dev.json
prod.json|env/prod.json
$TARGET-google-services.json|android/app/google-services.json
$TARGET-GoogleService-Info.plist|ios/Runner/GoogleService-Info.plist
"

# Checked in full before anything is written. A run that copies two files and
# then dies on a missing third leaves a tree that is half this environment and
# half the last one — and nothing on disk says so. Better to name every
# missing file at once and touch nothing.
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
