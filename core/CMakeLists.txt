cmake_minimum_required(VERSION 3.20)

include(FetchContent)

set(TOPOROOM_CORE_SOURCES
  src/domain/error.cpp
  src/domain/kinds.cpp
  src/domain/length_mm.cpp
  src/domain/point_mm.cpp
  src/domain/opening.cpp
  src/domain/wall.cpp
  src/domain/storey.cpp
  src/domain/floor_plan_document.cpp
  src/ports/semantics.cpp
  src/app/session_isolate.cpp
  src/app/param_gathering_fsm.cpp
  src/app/wall_draw_tool.cpp
  src/app/tool_registry.cpp
  src/app/document_io.cpp
  src/app/add_wall_handler.cpp
  src/app/add_opening_handler.cpp
  src/app/set_measurement_handler.cpp
  src/app/rebuild_policy.cpp
  src/app/status_gate.cpp
  src/app/export_app_service.cpp
  src/adapters/fake_geometry_port.cpp
  src/adapters/manifold_geometry_port.cpp
  src/adapters/in_memory_document_store.cpp
  src/adapters/export_scene_graph.cpp
  src/adapters/export_glb.cpp
  src/adapters/export_dxf.cpp
  src/adapters/export_pdf.cpp
  src/adapters/scene_ir_json.cpp
  src/adapters/laser_adapters.cpp
  src/adapters/depth_adapters.cpp
  src/adapters/android_whitelist.cpp
  src/adapters/imu_adapters.cpp
  src/app/laser_capture_service.cpp
  src/app/depth_capture_service.cpp
  src/c_api/toporoom_c_api.cpp
)

add_library(toporoom_core STATIC ${TOPOROOM_CORE_SOURCES})
add_library(toporoom::core ALIAS toporoom_core)


find_package(Threads REQUIRED)

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

FetchContent_Declare(
  nlohmann_json
  URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(nlohmann_json)


# JSON is an adapter concern (SceneIR files / scene-graph). Domain sources
# must not include nlohmann/json.hpp.
target_link_libraries(toporoom_core PRIVATE nlohmann_json::nlohmann_json)

# Manifold is the GeometryKernel ACL only (I2 / NFR-015). Never PUBLIC.
set(MANIFOLD_TEST OFF CACHE BOOL "" FORCE)
set(MANIFOLD_CBIND OFF CACHE BOOL "" FORCE)
set(MANIFOLD_PYBIND OFF CACHE BOOL "" FORCE)
set(MANIFOLD_JSBIND OFF CACHE BOOL "" FORCE)
set(MANIFOLD_PAR OFF CACHE BOOL "" FORCE)
set(MANIFOLD_CROSS_SECTION ON CACHE BOOL "" FORCE)
set(MANIFOLD_USE_BUILTIN_CLIPPER2 ON CACHE BOOL "" FORCE)
set(MANIFOLD_DOWNLOADS ON CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF)

FetchContent_Declare(
  manifold
  GIT_REPOSITORY https://github.com/elalish/manifold.git
  GIT_TAG v3.5.3
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(manifold)
target_link_libraries(toporoom_core PRIVATE manifold)

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
    tests/floor_plan_document_test.cpp
    tests/measurement_test.cpp
    tests/import_ban_test.cpp
    tests/ports_test.cpp
    tests/fake_geometry_port_test.cpp
    tests/manifold_geometry_port_test.cpp
    tests/session_isolate_test.cpp
    tests/param_gathering_fsm_test.cpp
    tests/tool_registry_test.cpp
    tests/handlers_test.cpp
    tests/status_gate_test.cpp
    tests/export_scene_graph_test.cpp
    tests/export_deliverables_test.cpp
    tests/sceneir_fixture_test.cpp
    tests/c_api_test.cpp
    tests/laser_port_test.cpp
    tests/depth_port_test.cpp
    tests/android_whitelist_test.cpp
    tests/imu_port_test.cpp
  )

  target_link_libraries(toporoom_tests
    PRIVATE
      toporoom::core
      GTest::gtest_main
      nlohmann_json::nlohmann_json
      manifold
  )
  target_compile_definitions(toporoom_tests
    PRIVATE
      TOPOROOM_FIXTURE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/fixtures"
      TOPOROOM_CORE_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
      TOPOROOM_REPO_DIR="${CMAKE_CURRENT_SOURCE_DIR}/.."
  )

  add_executable(toporoom_write_godot_fixture tools/write_godot_fixture.cpp)
  target_link_libraries(toporoom_write_godot_fixture PRIVATE toporoom::core manifold)
  target_compile_definitions(toporoom_write_godot_fixture PRIVATE
    TOPOROOM_FIXTURE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/fixtures"
  )
  target_compile_features(toporoom_write_godot_fixture PRIVATE cxx_std_20)
  if(NOT MSVC)
    target_compile_options(toporoom_tests PRIVATE -Wall -Wextra -Wpedantic -Werror)
  endif()
endif()
