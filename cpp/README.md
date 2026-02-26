# C++ – Gumbo HTML Normalizer

## Gumbo-parser setup

The normalizer depends on a single amalgamation file `GumboParser/GumboParser.h`.

This file was created from the [gumbo-parser](https://codeberg.org/gumbo-parser/gumbo-parser) repository — an actively maintained fork of the original Google gumbo-parser.

### Updating gumbo-parser

If you want to upgrade to a newer version:

1. Clone the repository:
   ```bash
   git clone https://codeberg.org/gumbo-parser/gumbo-parser.git
   ```
2. Create a new amalgamation from the cloned source files.
3. Replace the existing `cpp/GumboParser/GumboParser.h` with the newly generated amalgamation.

## Building and running tests

Prerequisites: **CMake ≥ 3.14** and a C/C++ compiler (Clang or GCC).

```bash
cd cpp

# Configure (only needed once, or after editing CMakeLists.txt)
cmake -B build -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

## Upgrading Google Test

GTest is fetched automatically by CMake via `FetchContent`. To change the
version, edit the `GIT_TAG` in `cpp/CMakeLists.txt`:

```cmake
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.17.0   # ← change this to the desired version/tag
)
```

Then re-configure and rebuild:

```bash
cd cpp
rm -rf build
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

Available tags can be found at https://github.com/google/googletest/tags.
