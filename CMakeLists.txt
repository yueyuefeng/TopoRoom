cmake_minimum_required(VERSION 3.20)
project(toporoom LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(TOPOROOM_BUILD_TESTS "Build GoogleTest suite" ON)

if(TOPOROOM_BUILD_TESTS)
  enable_testing()
  include(CTest)
endif()

add_subdirectory(core)


if(TOPOROOM_BUILD_TESTS AND TARGET toporoom_tests)
  add_test(NAME toporoom_tests COMMAND $<TARGET_FILE:toporoom_tests>)
endif()
