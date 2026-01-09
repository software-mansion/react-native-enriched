# Release guide

This document describes the steps to release the library.

## Quick overview
1. Create a release branch following convention: `@your_username/release-x.y.z`.
2. Update version number in `package.json`.
3. Run example apps to verify everything works. You will notice that iOS example app `Podfile.lock` has been updated. Remember to commit this change.
    ```sh
    cd example/ios
    pod install
    cd ../../
    yarn example ios
    yarn example android
    ```
4. Commit changes, push branch, and open a pull request.
5. Once PR is approved and merged, run `publish` GitHub action. First run should be a dry run.
6. After verifying dry run, download newly created package from GitHub artifacts.
7. Downloaded file might be double zipped, unzip until you get to the `.tgz` file. On macOS, you can use:
   ```sh
    unzip -q ~/{source_path}/{file_name}.tgz.zip -d ~/{output_path}/
   ```
8. Verify the package by installing it in a fresh React Native project. Keep in mind to clean cache:
    ```sh
   yarn cache clean
   yarn add ./{output_path}/{file_name}.tgz
   ```
9. If everything works, run the `publish` action again without dry run.
10. Install the new version from npm and verify everything works as expected.
11. After publishing, checkout the `main` branch and pull the latest changes.
12. Tag the new release in GitHub:
    ```sh
    git tag vx.y.z
    git push origin vx.y.z
    ```
13. Create a GitHub release with release notes.
