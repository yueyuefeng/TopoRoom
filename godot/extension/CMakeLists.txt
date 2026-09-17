cmake_minimum_required(VERSION 3.20)
project(toporoom_gdextension LANGUAGES CXX)

# The Kotlin JNI host remains an optional legacy path. This shared library is
# the P0 InteractionShell host: Godot UI → C API → FloorPlanDocument.

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(TOPOROOM_BUILD_TESTS OFF CACHE BOOL "GDExtension does not run gtest" FORCE)

if(NOT TARGET toporoom::core)
  add_subdirectory(
    ${CMAKE_CURRENT_LIST_DIR}/../../core
    ${CMAKE_CURRENT_BINARY_DIR}/toporoom_core
  )
endif()

include(FetchContent)

set(GODOT_CPP_SYSTEM_HEADERS ON CACHE BOOL "" FORCE)
set(GODOT_DISABLE_EXCEPTIONS ON CACHE BOOL "" FORCE)

FetchContent_Declare(
  godotcpp
  GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
  GIT_TAG godot-4.3-stable
  GIT_SHALLOW TRUE
)
FetchContent_GetProperties(godotcpp)
if(NOT godotcpp_POPULATED)
  FetchContent_Populate(godotcpp)
  # godot-cpp 4.3 defaults GODOT_GDEXTENSION_DIR to a relative "gdextension"
  # path that breaks include lookup when used as a subdirectory.
  set(GODOT_GDEXTENSION_DIR "${godotcpp_SOURCE_DIR}/gdextension" CACHE STRING "" FORCE)
  add_subdirectory(${godotcpp_SOURCE_DIR} ${godotcpp_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

add_library(toporoom_gdextension SHARED
  src/register_types.cpp
  src/toporoom_host.cpp
)

target_include_directories(toporoom_gdextension PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(toporoom_gdextension PRIVATE godot-cpp toporoom::core)

target_compile_features(toporoom_gdextension PRIVATE cxx_std_20)

if(NOT MSVC)
  target_compile_options(toporoom_gdextension PRIVATE -Wall -Wextra -fexceptions -frtti)
  if(NOT ANDROID)
    target_link_options(toporoom_gdextension PRIVATE -Wl,--no-undefined)
  endif()
endif()

if(ANDROID)
  find_library(log-lib log)
  if(log-lib)
    target_link_libraries(toporoom_gdextension PRIVATE ${log-lib})
  endif()
endif()

if(ANDROID)
  if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(_godot_arch "arm64")
  elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(_godot_arch "arm32")
  elseif(ANDROID_ABI STREQUAL "x86_64")
    set(_godot_arch "x86_64")
  elseif(ANDROID_ABI STREQUAL "x86")
    set(_godot_arch "x86_32")
  else()
    set(_godot_arch "${ANDROID_ABI}")
  endif()
  set(_godot_platform "android")
elseif(WIN32)
  set(_godot_platform "windows")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_godot_arch "x86_64")
  else()
    set(_godot_arch "x86_32")
  endif()
elseif(APPLE)
  set(_godot_platform "macos")
  set(_godot_arch "universal")
else()
  set(_godot_platform "linux")
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(_godot_arch "x86_64")
  else()
    set(_godot_arch "x86_32")
  endif()
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo"
   OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
  set(_godot_target "template_release")
else()
  set(_godot_target "template_debug")
endif()

set(_out_name "toporoom.${_godot_platform}.${_godot_target}.${_godot_arch}")
set(_godot_bin "${CMAKE_CURRENT_LIST_DIR}/../bin")
file(MAKE_DIRECTORY "${_godot_bin}")

set_target_properties(toporoom_gdextension PROPERTIES
  OUTPUT_NAME "${_out_name}"
  PREFIX "lib"
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  LIBRARY_OUTPUT_DIRECTORY "${_godot_bin}"
  RUNTIME_OUTPUT_DIRECTORY "${_godot_bin}"
)

add_custom_command(TARGET toporoom_gdextension POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory "${_godot_bin}"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "$<TARGET_FILE:toporoom_gdextension>"
    "${_godot_bin}/$<TARGET_FILE_NAME:toporoom_gdextension>"
  COMMENT "Install GDExtension to godot/bin for the Godot project"
)

add_library(toporoom::gdextension ALIAS toporoom_gdextension)
