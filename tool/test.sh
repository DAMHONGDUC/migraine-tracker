#!/bin/sh
# Run the Flutter test suite.
set -eu
. "$(dirname "$0")/_common.sh"

step "test"
$FL test
