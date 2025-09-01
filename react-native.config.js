/**
 * @type {import('@react-native-community/cli-types').UserDependencyConfig}
 */
module.exports = {
  dependency: {
    platforms: {
      android: {
        cmakeListsPath: '../android/src/main/new_arch/CMakeLists.txt',
        componentDescriptors: ['EnrichedTextInputComponentDescriptor'],
      },
    },
  },
};
