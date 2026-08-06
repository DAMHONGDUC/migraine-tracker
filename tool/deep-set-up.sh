#!/bin/sh
# Everything `set-up` wipes, plus Xcode's DerivedData, then set up again.
#
# Reach for this when a build fails in a way the code cannot explain: a
# precompiled module Xcode refuses to reuse ("has been modified since the
# module file was built"), a header that resolves to a version you no longer
# depend on, a failure that comes and goes on the same commit. Usually right
# after a native dependency moved — a Firebase plugin bump, a pod, an SPM pin.
#
# The cost is a full cold build afterwards, which is why `set-up` does not do
# this by default.
set -eu

# Read by tool/_clean.sh, which set-up.sh runs.
MELOS_CLEAN_DERIVED=1
export MELOS_CLEAN_DERIVED

sh "$(dirname "$0")/set-up.sh"
