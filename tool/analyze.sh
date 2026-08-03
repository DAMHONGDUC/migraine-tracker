#!/bin/sh
# Analyze every package. Must pass with zero findings — this is what CI runs.
set -eu
. "$(dirname "$0")/_common.sh"

step "analyze"
$FL analyze --fatal-infos
