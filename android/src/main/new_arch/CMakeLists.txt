cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(LIB_LITERAL ReactNativeEnrichedSpec)
set(LIB_TARGET_NAME react_codegen_${LIB_LITERAL})

set(LIB_ANDROID_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../..)
set(LIB_ANDROID_GENERATED_JNI_DIR ${LIB_ANDROID_DIR}/generated/jni)
set(LIB_ANDROID_GENERATED_COMPONENTS_DIR ${LIB_ANDROID_GENERATED_JNI_DIR}/react/renderer/components/${LIB_LITERAL})

set(LIB_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../cpp)

file(GLOB LIB_MODULE_SRCS CONFIGURE_DEPENDS *.cpp react/renderer/components/${LIB_LITERAL}/*.cpp)
file(GLOB LIB_CODEGEN_SRCS CONFIGURE_DEPENDS ${LIB_ANDROID_GENERATED_COMPONENTS_DIR}/*.cpp)
file(GLOB LIB_CPP_SRCS CONFIGURE_DEPENDS ${LIB_CPP_DIR}/parser/GumboParser.cpp ${LIB_CPP_DIR}/parser/GumboNormalizer.c)

set_source_files_properties(${LIB_CPP_DIR}/parser/GumboNormalizer.c PROPERTIES LANGUAGE C COMPILE_FLAGS "-std=c99")

if(NOT DEFINED REACT_NATIVE_MINOR_VERSION)
  set(REACT_NATIVE_MINOR_VERSION ${ReactAndroid_VERSION_MINOR})
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DREACT_NATIVE_MINOR_VERSION=${REACT_NATIVE_MINOR_VERSION}")

add_library(
        ${LIB_TARGET_NAME}
        SHARED
        ${LIB_MODULE_SRCS}
        ${LIB_CUSTOM_SRCS}
        ${LIB_CODEGEN_SRCS}
        ${LIB_CPP_SRCS}
)

target_include_directories(
        ${LIB_TARGET_NAME}
        PUBLIC
        .
        ./react/renderer/components/${LIB_LITERAL}
        ${LIB_ANDROID_GENERATED_JNI_DIR}
        ${LIB_ANDROID_GENERATED_COMPONENTS_DIR}
        ${LIB_CPP_DIR}
        ${LIB_CPP_DIR}/parser
        ${LIB_CPP_DIR}/GumboParser
)

find_package(fbjni REQUIRED CONFIG)
find_package(ReactAndroid REQUIRED CONFIG)

target_link_libraries(
        ${LIB_TARGET_NAME}
        fbjni::fbjni
        ReactAndroid::jsi
        ReactAndroid::reactnative
)

target_compile_reactnative_options(${LIB_TARGET_NAME} PRIVATE)

target_include_directories(
        ${CMAKE_PROJECT_NAME}
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)
