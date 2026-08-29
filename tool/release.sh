#!/bin/sh
# One environment, end to end: install its config, deploy its backend, ship its build to TestFlight.
set -eu
. "$(dirname "$0")/_common.sh"

TARGET="${1:-}"
case "$TARGET" in
  dev | prod) ;;
  *)
    warn "usage: release.sh <dev|prod>"
    exit 1
    ;;
esac

# Checked here rather than 20 minutes in, after the config is installed and the backend is already deployed.
if ! command -v bundle >/dev/null 2>&1; then
  warn "bundler not found — cd ios && bundle install (docs/rules/COMMANDS.md)"
  exit 1
fi

# The order is the point: the native config has to be in the tree before the backend deploy reads functions/.env, and before fastlane's verify_flavor_config compares it against the flavor.
step "release $TARGET — 1/3 env config"
sh tool/prepare-env.sh "$TARGET"

step "release $TARGET — 2/3 firebase"
sh tool/deploy-firebase.sh "$TARGET"

# `notes:` is the flavour line testers see; the lane prefixes it with "<flavor> - <version> (<build>)" either way.
step "release $TARGET — 3/3 testflight"
(cd ios && bundle exec fastlane beta flavor:"$TARGET" bump:true notes:"$TARGET")

done_msg "Released $TARGET: config installed, backend deployed, build uploaded."
# bump:true rewrites pubspec.yaml locally but only CI commits it (`if bump && is_ci`).
warn "Commit the bumped build number in pubspec.yaml — a local run does not."
