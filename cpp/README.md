# C++ – Lexbor HTML Normalizer

## Lexbor setup

The normalizer depends on a single amalgamation header `lexbor/lexbor.h`.

```bash
# from the project root
bash scripts/setup-lexbor.sh
```

The script clones the Lexbor repo at the pinned commit, runs the official
`single.pl` amalgamation generator, and writes the header to `cpp/lexbor/lexbor.h`.

### Updating Lexbor

1. Open `scripts/setup-lexbor.sh`.
2. Change `LEXBOR_COMMIT` to the desired commit hash (or tag).
3. Delete the existing header so the script regenerates it.

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
