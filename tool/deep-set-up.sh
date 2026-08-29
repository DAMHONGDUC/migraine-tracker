#!/bin/sh
# Everything `set-up` wipes, plus Xcode's DerivedData, then set up again.
set -eu

# Read by tool/_clean.sh, which set-up.sh runs.
MELOS_CLEAN_DERIVED=1
export MELOS_CLEAN_DERIVED

sh "$(dirname "$0")/set-up.sh"
