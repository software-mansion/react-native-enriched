cmake_minimum_required(VERSION 3.14)
project(gumbo_parser_tests C CXX)

# ── Fetch Google Test ────────────────────────────────────────────────────────
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.17.0
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# ── Shared library: gumbo normalizer + C++ wrapper ──────────────────────────
add_library(gumbo_normalizer_lib SHARED
    parser/gumbo_normalizer.c
    parser/GumboParser.cpp
)

target_include_directories(gumbo_normalizer_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/gumbo-parser
    ${CMAKE_CURRENT_SOURCE_DIR}/parser
)

# Compile the C file as C99, C++ files as C++17
set_source_files_properties(
    parser/gumbo_normalizer.c
    PROPERTIES LANGUAGE C
               COMPILE_FLAGS "-std=c99"
)

target_compile_options(gumbo_normalizer_lib PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
)

# ── Test executable ──────────────────────────────────────────────────────────
enable_testing()

add_executable(gumbo_parser_tests
    tests/GumboParserTest.cpp
)

target_link_libraries(gumbo_parser_tests PRIVATE
    gumbo_normalizer_lib
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(gumbo_parser_tests)
