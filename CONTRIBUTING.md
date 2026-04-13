# Contributing

Contributions are always welcome, no matter how large or small!

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project. Before contributing, please read the [code of conduct](./CODE_OF_CONDUCT.md).

## Development workflow

This project is a monorepo managed using [Yarn workspaces](https://yarnpkg.com/features/workspaces). It contains the following packages:

- The library package in the root directory.
- An example app in the `apps/example/` directory.

To get started with the project, run `yarn` in the root directory to install the required dependencies for each package:

```sh
yarn
```

> Since the project relies on Yarn workspaces, you cannot use [`npm`](https://github.com/npm/cli) for development.

The [example app](/apps/example/) demonstrates usage of the library. You need to run it to test any changes you make.

It is configured to use the local version of the library, so any changes you make to the library's source code will be reflected in the example app. Changes to the library's JavaScript code will be reflected in the example app without a rebuild, but native code changes will require a rebuild of the example app.

If you want to use Android Studio or Xcode to edit the native code, you can open the `apps/example/android` or `apps/example/ios` directories respectively in those editors. To edit the Objective-C or Swift files, open `apps/example/ios/EnrichedTextInputExample.xcworkspace` in Xcode and find the source files at `Pods > Development Pods > ReactNativeEnriched`.

To edit the Java or Kotlin files, open `apps/example/android` in Android studio and find the source files at `react-native-enriched` under `Android`.

You can use various commands from the root directory to work with the project.

To start the packager:

```sh
yarn example start
```

To run the example app on Android:

```sh
yarn example android
```

To run the example app on iOS:

```sh
yarn example ios
```

To confirm that the app is running with the new architecture, you can check the Metro logs for a message like this:

```sh
Running "EnrichedTextInputExample" with {"fabric":true,"initialProps":{"concurrentRoot":true},"rootTag":1}
```

Note the `"fabric":true` and `"concurrentRoot":true` properties.

Make sure your code passes TypeScript and ESLint. Run the following to verify:

```sh
yarn typecheck
yarn lint
```

To fix formatting errors, run the following:

```sh
yarn lint --fix
```

Remember to add tests for your change if possible. Run the unit tests by:

```sh
yarn test
```

### E2E tests

We use [Maestro](https://maestro.mobile.dev/) for end-to-end testing. Flows live in `.maestro/flows/` and shared subflows in `.maestro/subflows/`.

#### Prerequisites

- **Maestro CLI** (v2.3.0+) - follow the [Getting Started guide](https://github.com/mobile-dev-inc/maestro?tab=readme-ov-file#getting-started). After installing, ensure `~/.maestro/bin` is in your `PATH`.
- **iOS** - Xcode. Ensure `xcrun` is available (it ships with Xcode Command Line Tools).
- **Android** - Android SDK with SDK Command-line Tools, SDK Platform-Tools, Emulator. Set up `ANDROID_HOME` (typically `$HOME/Library/Android/sdk` on macOS) and ensure the following are in your `PATH`:
  - `$ANDROID_HOME/cmdline-tools/latest/bin`
  - `$ANDROID_HOME/platform-tools`
  - `$ANDROID_HOME/emulator`

The target devices are:

| Platform | Device    | OS                            |
| -------- | --------- | ----------------------------- |
| iOS      | iPhone 17 | iOS 26.2                      |
| Android  | Pixel 7   | API 36 "Baklava" (Android 16) |

#### Running E2E tests

Start the Metro packager before running E2E tests:

```sh
yarn example start
```

Each command sets up the device and runs all Maestro flows. The script automatically detects whether the app is already installed and only builds when necessary:

```sh
# Both platforms sequentially
yarn test:e2e:mobile

# Single platform
yarn test:e2e:ios
yarn test:e2e:android
```

You can target specific flows or force a rebuild:

```sh
# Run a single flow
yarn test:e2e:ios .maestro/flows/core_controls_smoke.yaml

# Force a fresh build even if the app is already installed
yarn test:e2e:android --rebuild
```

#### Visual regression tests

Some flows compare a screenshot of the editor against a saved baseline in `.maestro/screenshots/`. By default the baseline is asserted. Pass `--update-screenshots` to capture new baselines instead:

```sh
# Update baselines on both platforms
yarn test:e2e:mobile --update-screenshots

# Single platform
yarn test:e2e:ios --update-screenshots
yarn test:e2e:android --update-screenshots .maestro/flows/inline_styles_visual.yaml
```

Always review newly saved screenshots in `.maestro/screenshots/` before committing them.

#### Troubleshooting: flaky Android tests on macOS

macOS may throttle the Android emulator via **App Nap** when its window is not visible (e.g. minimized or behind other windows), which can cause test timeouts. Two workarounds:

1. **Keep the emulator window visible** while tests are running.
2. **Disable App Nap** for the emulator: `defaults write com.google.android.emulator NSAppSleepDisabled -bool YES` (requires an emulator restart). Note this may drain your battery, so you may want to re-enable it afterwards with `-bool NO`.

### Web E2E tests

We use [Playwright](https://playwright.dev/) for end-to-end testing of the web example. Tests live in `.playwright/tests/`.

#### Prerequisites

- Install Playwright browser binaries once before running web E2E tests:

```sh
yarn playwright install
```

#### Running Web E2E tests

Run the web E2E suite from the root directory:

```sh
yarn test:e2e:web
```

The Playwright config starts the Vite dev server automatically, so you do not need to run `yarn example-web dev` separately.

### Commit message convention

We follow the [conventional commits specification](https://www.conventionalcommits.org/en) for our commit messages:

- `fix`: bug fixes, e.g. fix crash due to deprecated method.
- `feat`: new features, e.g. add new method to the module.
- `refactor`: code refactor, e.g. migrate from class components to hooks.
- `docs`: changes into documentation, e.g. add usage example for the module..
- `test`: adding or updating tests, e.g. add integration tests using detox.
- `chore`: tooling changes, e.g. change CI config.

Our pre-commit hooks verify that your commit message matches this format when committing.

### Linting and tests

[ESLint](https://eslint.org/), [Prettier](https://prettier.io/), [TypeScript](https://www.typescriptlang.org/)

We use [TypeScript](https://www.typescriptlang.org/) for type checking, [ESLint](https://eslint.org/) with [Prettier](https://prettier.io/) for linting and formatting the code, and [Jest](https://jestjs.io/) for testing.

Our pre-commit hooks verify that the linter and tests pass when committing.

### Scripts

The `package.json` file contains various scripts for common tasks:

- `yarn`: setup project by installing dependencies.
- `yarn typecheck`: type-check files with TypeScript.
- `yarn lint`: lint files with ESLint.
- `yarn test`: run unit tests with Jest.
- `yarn example start`: start the Metro server for the example app.
- `yarn example android`: run the example app on Android.
- `yarn example ios`: run the example app on iOS.
- `yarn test:e2e`: run all E2E tests (mobile + web) sequentially.
- `yarn test:e2e:mobile`: run E2E tests on iOS and Android sequentially.
- `yarn test:e2e:android`: run E2E tests on Android.
- `yarn test:e2e:ios`: run E2E tests on iOS.
- `yarn test:e2e:web`: run E2E tests on the web example with Playwright.

### Sending a pull request

> **Working on your first pull request?** You can learn how from this _free_ series: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

When you're sending a pull request:

- Prefer small pull requests focused on one change.
- Verify that linters and tests are passing.
- Review the documentation to make sure it looks good.
- Follow the pull request template when opening a pull request.
- For pull requests that change the API or implementation, discuss with maintainers first by opening an issue.
