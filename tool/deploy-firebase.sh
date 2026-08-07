#!/bin/sh
# Deploy the Firebase side: firestore rules, indexes, and functions.
#
# Optional target argument: `rules` (rules + indexes) or `functions`.
# No argument deploys both.
set -eu
. "$(dirname "$0")/_common.sh"

TARGET="${1:-all}"

case "$TARGET" in
  all | rules | functions) ;;
  *)
    warn "unknown target '$TARGET' — expected: rules, functions, or nothing"
    exit 1
    ;;
esac

if ! command -v firebase >/dev/null 2>&1; then
  warn "firebase CLI not found — https://firebase.google.com/docs/cli"
  exit 1
fi

# env/dev.json and env/prod.json point at the SAME project, so there is no
# dev target to practise on: a rules deploy reaches real users immediately.
step "target"
firebase use

printf 'Deploy %s to that project? [y/N] ' "$TARGET"
# Melos hands the script a piped stdout but leaves stdin alone; /dev/tty is
# the one that survives a `sh tool/... < something`, so try it and fall back.
REPLY=''
# stderr is redirected BEFORE /dev/tty: redirections apply left to right, so
# the other order reports the failure to the original stderr anyway.
read -r REPLY 2>/dev/null </dev/tty || read -r REPLY || true
case "$REPLY" in
  y | Y) ;;
  *)
    warn "aborted"
    exit 1
    ;;
esac

# Rules and indexes are separate deploy targets. A missing composite index
# fails at runtime, not at build, so they always go together.
if [ "$TARGET" = "all" ] || [ "$TARGET" = "rules" ]; then
  step "firestore rules and indexes"
  firebase deploy --only firestore:rules,firestore:indexes
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "functions" ]; then
  # Deploying a build that fails its own tests costs a second deploy to undo.
  step "functions tests"
  (cd functions && npm run build && npm test)

  step "functions"
  firebase deploy --only functions
fi

done_msg "Deployed."
