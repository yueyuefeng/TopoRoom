cmake_minimum_required(VERSION 3.20)

find_package(Threads REQUIRED)

add_library(toporoom_core STATIC src/core_anchor.cpp)
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
