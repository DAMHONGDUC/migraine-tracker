#!/bin/sh
# Regenerate localizations and build_runner output.
set -eu
. "$(dirname "$0")/_common.sh"

step "localizations"
$FL gen-l10n

step "code generation"
$DT run build_runner build --delete-conflicting-outputs
