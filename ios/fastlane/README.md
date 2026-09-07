fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build through packages/system_design/tool/build-ipa.sh and upload to TestFlight. flavor: dev|prod, bump: true|false, notes: a line for What to Test

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Upload an IPA that is already in build/ios/ipa, without rebuilding. flavor: dev|prod. For a build that succeeded and an upload that did not.

### ios preflight

```sh
[bundle exec] fastlane ios preflight
```

Everything a release depends on except the build. flavor:dev|prod also checks the config in the tree. Rehearse the runner with CI=true.

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Create or renew the distribution certificate and every profile. Local only. force:true regenerates them.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
