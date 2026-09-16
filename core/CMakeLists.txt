cmake_minimum_required(VERSION 3.20)

include(FetchContent)
find_package(Threads REQUIRED)

set(TOPOROOM_CORE_SOURCES
  src/domain/error.cpp
  src/domain/kinds.cpp
  src/domain/length_mm.cpp
  src/domain/point_mm.cpp
  src/domain/opening.cpp
  src/domain/wall.cpp
  src/domain/storey.cpp
)

add_library(toporoom_core STATIC ${TOPOROOM_CORE_SOURCES})
add_library(toporoom::core ALIAS toporoom_core)

target_include_directories(toporoom_core
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
target_compile_features(toporoom_core PUBLIC cxx_std_20)
target_link_libraries(toporoom_core PUBLIC Threads::Threads)

if(MSVC)
  target_compile_options(toporoom_core PRIVATE /W4 /WX)
else()
  target_compile_options(toporoom_core PRIVATE -Wall -Wextra -Wpedantic -Werror)
endif()

if(TOPOROOM_BUILD_TESTS)
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.zip
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  )
  FetchContent_MakeAvailable(googletest)

  add_executable(toporoom_tests
    tests/length_mm_test.cpp
    tests/point_mm_test.cpp
    tests/wall_test.cpp
    tests/opening_test.cpp
  )
  target_link_libraries(toporoom_tests PRIVATE toporoom::core GTest::gtest_main)
  target_compile_definitions(toporoom_tests PRIVATE
    TOPOROOM_CORE_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
  )
  if(NOT MSVC)
    target_compile_options(toporoom_tests PRIVATE -Wall -Wextra -Wpedantic -Werror)
  endif()
endif()
