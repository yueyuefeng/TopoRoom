cmake_minimum_required(VERSION 3.22)
project(toporoom_android_jni LANGUAGES CXX)

set(TOPOROOM_BUILD_TESTS OFF CACHE BOOL "Host JNI does not run gtest" FORCE)

if(NOT TARGET toporoom::core)
  add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/../../core ${CMAKE_CURRENT_BINARY_DIR}/toporoom_core)
endif()

add_library(toporoom_jni SHARED src/main/cpp/toporoom_jni.cpp)
target_link_libraries(toporoom_jni PRIVATE toporoom::core)
target_compile_features(toporoom_jni PRIVATE cxx_std_20)
