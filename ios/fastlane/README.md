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

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload App Store metadata (from repo)

### ios deploy_testflight

```sh
[bundle exec] fastlane ios deploy_testflight
```

Deploy to TestFlight

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy to App Store

### ios build

```sh
[bundle exec] fastlane ios build
```

Build iOS app for release

### ios release_testflight

```sh
[bundle exec] fastlane ios release_testflight
```

Build and deploy to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and deploy to App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
