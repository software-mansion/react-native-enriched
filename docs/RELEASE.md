# Release guide

This document describes the steps to release the library.

## Quick overview

1. Create a release branch following convention: `@your_username/release-x.y.z`.
2. Update version number in `package.json`.
3. Run example apps to verify everything works. You will notice that iOS example app `Podfile.lock` has been updated. Remember to commit this change.
   ```sh
   cd apps/example/ios
   pod install
   cd ../../../
   yarn example ios
   yarn example android
   ```
4. Commit changes, push branch, and open a pull request.
5. Once PR is approved and merged, run `publish` GitHub action. First run should be a dry run.
6. If everything looks fine (included files, library version and size), run the `publish` action again without dry run.
7. Install the new version from npm and verify everything works as expected.
8. After publishing, create a GitHub release with release notes.
