cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

set(LIB_LITERAL RNEnrichedTextInputViewSpec)
set(LIB_TARGET_NAME react_codegen_${LIB_LITERAL})

set(LIB_ANDROID_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../..)
set(LIB_ANDROID_GENERATED_JNI_DIR ${LIB_ANDROID_DIR}/generated/jni)
set(LIB_ANDROID_GENERATED_COMPONENTS_DIR ${LIB_ANDROID_GENERATED_JNI_DIR}/react/renderer/components/${LIB_LITERAL})

file(GLOB LIB_MODULE_SRCS CONFIGURE_DEPENDS *.cpp react/renderer/components/${LIB_LITERAL}/*.cpp)
file(GLOB LIB_CODEGEN_SRCS CONFIGURE_DEPENDS ${LIB_ANDROID_GENERATED_COMPONENTS_DIR}/*.cpp)

add_library(
        ${LIB_TARGET_NAME}
        SHARED
        ${LIB_MODULE_SRCS}
        ${LIB_CUSTOM_SRCS}
        ${LIB_CODEGEN_SRCS}
)

target_include_directories(
        ${LIB_TARGET_NAME}
        PUBLIC
        .
        ./react/renderer/components/${LIB_LITERAL}
        ${LIB_ANDROID_GENERATED_JNI_DIR}
        ${LIB_ANDROID_GENERATED_COMPONENTS_DIR}
        ${LIB_CPP_DIR}
)

find_package(fbjni REQUIRED CONFIG)
find_package(ReactAndroid REQUIRED CONFIG)

target_link_libraries(
        ${LIB_TARGET_NAME}
        fbjni::fbjni
        ReactAndroid::jsi
        ReactAndroid::reactnative
)

if(ReactAndroid_VERSION_MINOR GREATER_EQUAL 80)
  target_compile_reactnative_options(${LIB_TARGET_NAME} PRIVATE)
else()
  target_compile_options(
          ${LIB_TARGET_NAME}
          PRIVATE
          -DLOG_TAG=\"ReactNative\"
          -fexceptions
          -frtti
          -Wall
          -std=c++20
  )
endif()

target_include_directories(
        ${CMAKE_PROJECT_NAME}
        PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)
