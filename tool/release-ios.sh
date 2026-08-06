#!/bin/sh
# Build the iOS release archive, with the config flag attached.
#
# This exists because Xcode's own Product > Archive cannot work here: the
# app's Firebase and RevenueCat values arrive through
# `--dart-define-from-file`, which Xcode knows nothing about. An archive made
# that way carries empty config, `Firebase.initializeApp` throws, main()
# swallows it, and the app then dies on the first `FirebaseAuth.instance` with
# "No Firebase App '[DEFAULT]' has been created" — a crash that names nothing
# to do with the missing flag.
#
# The assert in main() does NOT catch this: Dart strips asserts from release
# builds, which is exactly where the mistake happens.
set -eu
. "$(dirname "$0")/_common.sh"

ENV_FILE="env/prod.json"

# Existence only — never the contents (hard rule 13).
if [ ! -f "$ENV_FILE" ]; then
  warn "$ENV_FILE is missing. Run: melos run set-up"
  exit 1
fi

step "ios release archive"
$FL build ipa --release --dart-define-from-file="$ENV_FILE"

done_msg "Upload build/ios/ipa/*.ipa with Transporter, or open the archive in Xcode Organizer."
