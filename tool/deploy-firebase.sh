#!/bin/sh
# Deploy one environment's Firebase side: firestore rules, indexes, functions.
#
#   sh tool/deploy-firebase.sh <dev|prod> [rules|functions]
#
# The environment is a `.firebaserc` alias, not an `env/*.json` file. The alias
# is what the CLI resolves to a project id, and the project id is what picks
# the functions' own config (`functions/.env.<project-id>`) and its secrets —
# so naming the environment here is the whole of the switch. No target after
# it deploys both halves.
set -eu
. "$(dirname "$0")/_common.sh"

ENV_NAME="${1:-}"
case "$ENV_NAME" in
  dev | prod) ;;
  *)
    warn "usage: deploy-firebase.sh <dev|prod> [rules|functions]"
    exit 1
    ;;
esac

TARGET="${2:-all}"
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

# `.firebaserc` is read here rather than left to the CLI so the prompt can name
# the project *before* anything is sent, and so a missing alias fails with the
# command that creates it instead of a CLI error naming neither.
project_id() {
  sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .firebaserc
}

ENV_ID=$(project_id "$ENV_NAME")
if [ -z "$ENV_ID" ]; then
  warn "no '$ENV_NAME' alias in .firebaserc."
  warn "Create it with: firebase use --add   (docs/setup/FIREBASE_PROJECT.md)"
  exit 1
fi

step "target"
printf '    %s -> %s\n' "$ENV_NAME" "$ENV_ID"

# Until prod is its own project both aliases resolve to the same id, and then
# `deploy-firebase-dev` is a production deploy wearing another name — the one
# thing the alias in the prompt would otherwise hide.
# `docs/setup/FIREBASE_PROJECT.md` is the work that ends this.
DEV_ID=$(project_id dev)
PROD_ID=$(project_id prod)
if [ -n "$DEV_ID" ] && [ "$DEV_ID" = "$PROD_ID" ]; then
  warn "dev and prod are the SAME project — this reaches real users."
fi

printf 'Deploy %s to %s (%s)? [y/N] ' "$TARGET" "$ENV_NAME" "$ENV_ID"
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

# Every deploy passes `--project` rather than running `firebase use` first:
# `firebase use` would leave the developer's shell pointed at whatever this
# script deployed last, so the next bare `firebase deploy` by hand would go
# there silently.
#
# Rules and indexes are separate deploy targets. A missing composite index
# fails at runtime, not at build, so they always go together.
if [ "$TARGET" = "all" ] || [ "$TARGET" = "rules" ]; then
  step "firestore rules and indexes — $ENV_NAME"
  firebase deploy --project "$ENV_NAME" --only firestore:rules,firestore:indexes
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "functions" ]; then
  # Deploying a build that fails its own tests costs a second deploy to undo.
  step "functions tests"
  (cd functions && npm run build && npm test)

  step "functions — $ENV_NAME"
  firebase deploy --project "$ENV_NAME" --only functions
fi

done_msg "Deployed $TARGET to $ENV_NAME ($ENV_ID)."
