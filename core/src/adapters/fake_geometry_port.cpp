#include "toporoom/adapters/fake_geometry_port.hpp"

namespace toporoom::adapters {

void FakeGeometryPort::fail_with(ports::GeometryFault fault) {
  ok_mode_ = false;
  fault_ = std::move(fault);
  last_status_ = ports::GeometryStatus::Fault;
}

void FakeGeometryPort::succeed() {
  ok_mode_ = true;
  last_status_ = ports::GeometryStatus::NoError;
}

const ports::BuildRequest* FakeGeometryPort::last_build_request() const {
  return last_request_ ? &*last_request_ : nullptr;
}

ports::RebuildResult FakeGeometryPort::rebuild(const ports::BuildRequest& request) {
  last_request_ = request;
  ports::RebuildResult result;
  if (!ok_mode_) {
    last_status_ = ports::GeometryStatus::Fault;
    result.ok = false;
    result.fault = fault_;
    return result;
  }
  last_status_ = ports::GeometryStatus::NoError;
  result.ok = true;
  result.meshes = project_semantics(request.semantics);
  return result;
}

ports::RebuildResult FakeGeometryPort::ensure_built(
    int document_rev, std::optional<std::string>, std::optional<std::string>) {
  if (!last_request_) {
    ports::RebuildResult result;
    result.ok = false;
    result.fault = {ports::FaultCode::InvalidGeometry,
                    "nothing built for revision " + std::to_string(document_rev),
                    {}};
    return result;
  }
  return rebuild(*last_request_);
}

ports::GeometryStatus FakeGeometryPort::status(std::optional<std::string>,
                                               std::optional<std::string>) {
  return last_status_;
}

void FakeGeometryPort::clear_cache() {
  last_request_.reset();
  last_status_ = ports::GeometryStatus::Unknown;
}

ports::MeshProjection project_semantics(const ports::FloorPlanSolidSemantics& semantics) {
  ports::MeshProjection meshes;
  for (const auto& storey : semantics.storeys) {
    for (const auto& wall : storey.walls) {
      ports::MeshSolid solid;
      solid.solid_id = "solid_" + wall.id;
      solid.storey_id = storey.id;
      solid.kind = "wall";
      solid.entity_id = wall.id;
      solid.node_hint = "Wall_" + wall.id;
      solid.vertices_mm = {wall.start_x, 0, wall.start_y, wall.end_x, 0, wall.end_y,
                           wall.end_x, storey.height_mm, wall.end_y, wall.start_x,
                           storey.height_mm, wall.start_y};
      solid.indices = {0, 1, 2, 0, 2, 3};
      meshes.solids.push_back(std::move(solid));
      for (const auto& opening : wall.openings) {
        ports::MeshSolid opening_solid;
        opening_solid.solid_id = "solid_" + opening.id;
        opening_solid.storey_id = storey.id;
        opening_solid.kind = "opening";
        opening_solid.entity_id = opening.id;
        opening_solid.node_hint = "Opening_" + opening.id;
        meshes.solids.push_back(std::move(opening_solid));
      }
    }
    for (const auto& room : storey.rooms) {
      ports::MeshSolid room_solid;
      room_solid.solid_id = "solid_" + room.id;
      room_solid.storey_id = storey.id;
      room_solid.kind = "room";
      room_solid.entity_id = room.id;
      room_solid.node_hint = "Room_" + room.id;
      meshes.solids.push_back(std::move(room_solid));
    }
  }
  return meshes;
}

}  // namespace toporoom::adapters
