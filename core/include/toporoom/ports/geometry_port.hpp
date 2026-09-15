#pragma once

#include <optional>
#include <string>
#include <vector>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::ports {

enum class FaultCode {
  NotManifold,
  InvalidGeometry,
  TooComplex,
  Cancelled,
  Timeout,
  NotClosed,
  OpeningOutOfBounds
};

inline const char* to_string(FaultCode code) {
  switch (code) {
    case FaultCode::NotManifold:
      return "NotManifold";
    case FaultCode::InvalidGeometry:
      return "InvalidGeometry";
    case FaultCode::TooComplex:
      return "TooComplex";
    case FaultCode::Cancelled:
      return "Cancelled";
    case FaultCode::Timeout:
      return "Timeout";
    case FaultCode::NotClosed:
      return "NotClosed";
    case FaultCode::OpeningOutOfBounds:
      return "OpeningOutOfBounds";
  }
  return "Unknown";
}

struct GeometryFault {
  FaultCode code = FaultCode::InvalidGeometry;
  std::string message;
  std::vector<std::string> entity_ids;
};

struct MeshSolid {
  std::string solid_id;
  std::string storey_id;
  std::string kind;
  std::string entity_id;
  std::string node_hint;
  std::vector<double> vertices_mm;
  std::vector<int> indices;
};

struct MeshProjection {
  std::vector<MeshSolid> solids;
};

struct SolidOpeningSemantics {
  std::string id;
  double width_mm = 0;
  double height_mm = 0;
  double offset_mm = 0;
  double sill_height_mm = 0;
};

struct SolidWallSemantics {
  std::string id;
  double start_x = 0;
  double start_y = 0;
  double end_x = 0;
  double end_y = 0;
  double thickness_mm = 0;
  double height_mm = 0;
  std::vector<SolidOpeningSemantics> openings;
};

struct SolidRoomSemantics {
  std::string id;
  std::vector<std::string> wall_ids;
};

struct SolidStoreySemantics {
  std::string id;
  double height_mm = 0;
  double elevation_mm = 0;
  std::vector<SolidWallSemantics> walls;
  std::vector<SolidRoomSemantics> rooms;
};

struct FloorPlanSolidSemantics {
  std::string document_id;
  int revision = 0;
  std::vector<SolidStoreySemantics> storeys;
};

struct BuildRequest {
  int document_rev = 0;
  int rebuild_generation = 0;
  bool dirty = true;
  FloorPlanSolidSemantics semantics;
};

struct RebuildResult {
  bool ok = false;
  MeshProjection meshes;
  GeometryFault fault;
};

enum class GeometryStatus { NoError, Fault, Dirty, Unknown };

class GeometryPort {
 public:
  virtual ~GeometryPort() = default;
  virtual RebuildResult rebuild(const BuildRequest& request) = 0;
  virtual RebuildResult ensure_built(
      int document_rev, std::optional<std::string> storey_id = std::nullopt,
      std::optional<std::string> solid_id = std::nullopt) = 0;
  virtual GeometryStatus status(std::optional<std::string> solid_id,
                                std::optional<std::string> storey_id) = 0;
  virtual void clear_cache() = 0;
};

FloorPlanSolidSemantics semantics_from_scene_ir(const domain::SceneIR& scene);

}  // namespace toporoom::ports
