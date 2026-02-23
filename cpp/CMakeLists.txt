cmake_minimum_required(VERSION 3.14)
project(lexbor_parser_tests C CXX)

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

# ── Static library: lexbor normalizer + C++ wrapper ──────────────────────────
add_library(lexbor_normalizer_lib STATIC
    parser/lexbor_normalizer.c
    parser/LexborParser.cpp
)

target_include_directories(lexbor_normalizer_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/lexbor
    ${CMAKE_CURRENT_SOURCE_DIR}/parser
)

# Compile the C file as C99, C++ files as C++17
set_source_files_properties(
    parser/lexbor_normalizer.c
    PROPERTIES LANGUAGE C
               COMPILE_FLAGS "-std=c99"
)

target_compile_options(lexbor_normalizer_lib PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
)

# ── Test executable ──────────────────────────────────────────────────────────
enable_testing()

add_executable(lexbor_parser_tests
    tests/LexborParserTest.cpp
)

target_link_libraries(lexbor_parser_tests PRIVATE
    lexbor_normalizer_lib
    GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(lexbor_parser_tests)
