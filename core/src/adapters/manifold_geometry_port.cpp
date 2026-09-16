#include "toporoom/adapters/manifold_geometry_port.hpp"

#include <cmath>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include <manifold/cross_section.h>
#include <manifold/manifold.h>

namespace toporoom::adapters {
namespace {

using manifold::CrossSection;
using manifold::Manifold;
using manifold::SimplePolygon;

ports::GeometryFault make_fault(ports::FaultCode code, std::string message,
                                std::vector<std::string> ids) {
  return {code, std::move(message), std::move(ids)};
}

ports::RebuildResult fail(ports::GeometryFault fault) {
  ports::RebuildResult result;
  result.ok = false;
  result.fault = std::move(fault);
  return result;
}

ports::FaultCode map_manifold_error(Manifold::Error error) {
  switch (error) {
    case Manifold::Error::NotManifold:
      return ports::FaultCode::NotManifold;
    case Manifold::Error::Cancelled:
      return ports::FaultCode::Cancelled;
    case Manifold::Error::ResultTooLarge:
      return ports::FaultCode::TooComplex;
    default:
      return ports::FaultCode::InvalidGeometry;
  }
}

std::optional<ports::GeometryFault> manifold_problem(const Manifold& solid,
                                                     const std::string& entity_id,
                                                     const char* stage) {
  if (solid.Status() != Manifold::Error::NoError) {
    return make_fault(map_manifold_error(solid.Status()),
                      std::string(stage) + " failed", {entity_id});
  }
  if (solid.IsEmpty() || solid.Volume() <= 0) {
    return make_fault(ports::FaultCode::InvalidGeometry,
                      std::string(stage) + " produced an empty solid", {entity_id});
  }
  return std::nullopt;
}

bool finite_wall(const ports::SolidWallSemantics& wall) {
  return std::isfinite(wall.start_x) && std::isfinite(wall.start_y) &&
         std::isfinite(wall.end_x) && std::isfinite(wall.end_y) &&
         std::isfinite(wall.thickness_mm) && std::isfinite(wall.height_mm);
}

ports::MeshSolid mesh_from_manifold(const Manifold& solid,
                                    const ports::SolidStoreySemantics& storey,
                                    const ports::SolidWallSemantics& wall) {
  const auto mesh = solid.GetMeshGL();
  ports::MeshSolid out;
  out.solid_id = "solid_" + wall.id;
  out.storey_id = storey.id;
  out.kind = "wall";
  out.entity_id = wall.id;
  out.node_hint = "Wall_" + wall.id;
  out.volume_mm3 = solid.Volume();
  out.vertices_mm.reserve(static_cast<size_t>(mesh.NumVert()) * 3);
  for (size_t i = 0; i < mesh.NumVert(); ++i) {
    const size_t offset = i * static_cast<size_t>(mesh.numProp);
    out.vertices_mm.push_back(mesh.vertProperties[offset]);
    out.vertices_mm.push_back(mesh.vertProperties[offset + 1]);
    out.vertices_mm.push_back(mesh.vertProperties[offset + 2]);
  }
  out.indices.reserve(mesh.triVerts.size());
  for (auto index : mesh.triVerts) {
    out.indices.push_back(static_cast<int>(index));
  }
  return out;
}

ports::RebuildResult build_wall(const ports::SolidStoreySemantics& storey,
                                const ports::SolidWallSemantics& wall) {
  const double dx = wall.end_x - wall.start_x;
  const double dy = wall.end_y - wall.start_y;
  const double length = std::hypot(dx, dy);
  if (!finite_wall(wall) || !(length > 0) || !(wall.thickness_mm > 0) ||
      !(wall.height_mm > 0)) {
    return fail(make_fault(ports::FaultCode::InvalidGeometry,
                           "empty or invalid wall cross-section", {wall.id}));
  }

  const double ux = dx / length;
  const double uy = dy / length;
  const double hx = -uy * (wall.thickness_mm * 0.5);
  const double hy = ux * (wall.thickness_mm * 0.5);
  const SimplePolygon contour = {
      {wall.start_x - hx, wall.start_y - hy},
      {wall.end_x - hx, wall.end_y - hy},
      {wall.end_x + hx, wall.end_y + hy},
      {wall.start_x + hx, wall.start_y + hy},
  };
  const CrossSection section(contour, CrossSection::FillRule::NonZero);
  if (section.IsEmpty() || !(section.Area() > 0)) {
    return fail(make_fault(ports::FaultCode::InvalidGeometry,
                           "CrossSection is empty", {wall.id}));
  }

  Manifold body = Manifold::Extrude(section.ToPolygons(), wall.height_mm);
  if (auto problem = manifold_problem(body, wall.id, "Extrude")) {
    return fail(*problem);
  }

  for (const auto& opening : wall.openings) {
    const bool in_bounds =
        opening.width_mm > 0 && opening.height_mm > 0 && opening.offset_mm >= 0 &&
        opening.sill_height_mm >= 0 &&
        opening.offset_mm + opening.width_mm <= length + 1e-3 &&
        opening.sill_height_mm + opening.height_mm <= wall.height_mm + 1e-3;
    if (!in_bounds) {
      return fail(make_fault(ports::FaultCode::OpeningOutOfBounds,
                             "opening does not fit host wall", {opening.id, wall.id}));
    }

    constexpr double kCutThroughMm = 1.0;
    const double chx = -uy * (wall.thickness_mm * 0.5 + kCutThroughMm);
    const double chy = ux * (wall.thickness_mm * 0.5 + kCutThroughMm);
    const double ax0 = wall.start_x + ux * opening.offset_mm;
    const double ay0 = wall.start_y + uy * opening.offset_mm;
    const double ax1 = wall.start_x + ux * (opening.offset_mm + opening.width_mm);
    const double ay1 = wall.start_y + uy * (opening.offset_mm + opening.width_mm);
    const SimplePolygon cutter_contour = {
        {ax0 - chx, ay0 - chy},
        {ax1 - chx, ay1 - chy},
        {ax1 + chx, ay1 + chy},
        {ax0 + chx, ay0 + chy},
    };
    const CrossSection cutter_section(cutter_contour, CrossSection::FillRule::NonZero);
    if (cutter_section.IsEmpty()) {
      return fail(make_fault(ports::FaultCode::InvalidGeometry,
                             "opening cutter CrossSection is empty", {opening.id}));
    }
    Manifold cutter = Manifold::Extrude(cutter_section.ToPolygons(), opening.height_mm)
                          .Translate({0, 0, opening.sill_height_mm});
    body = body - cutter;
    if (auto problem = manifold_problem(body, wall.id, "Boolean")) {
      return fail(*problem);
    }
  }

  if (storey.elevation_mm != 0) {
    body = body.Translate({0, 0, storey.elevation_mm});
  }

  ports::RebuildResult result;
  result.ok = true;
  result.meshes.solids.push_back(mesh_from_manifold(body, storey, wall));
  return result;
}

}  // namespace

ports::RebuildResult ManifoldGeometryPort::rebuild(const ports::BuildRequest& request) {
  ports::RebuildResult combined;
  combined.ok = true;
  for (const auto& storey : request.semantics.storeys) {
    for (const auto& wall : storey.walls) {
      auto piece = build_wall(storey, wall);
      if (!piece.ok) {
        last_status_ = ports::GeometryStatus::Fault;
        cached_rev_.reset();
        cached_ = piece;
        return piece;
      }
      for (auto& solid : piece.meshes.solids) {
        combined.meshes.solids.push_back(std::move(solid));
      }
    }
  }
  last_status_ = ports::GeometryStatus::NoError;
  cached_rev_ = request.document_rev;
  cached_ = combined;
  return combined;
}

ports::RebuildResult ManifoldGeometryPort::ensure_built(int document_rev,
                                                        std::optional<std::string>,
                                                        std::optional<std::string>) {
  if (cached_rev_ && *cached_rev_ == document_rev) {
    return cached_;
  }
  return fail(make_fault(ports::FaultCode::InvalidGeometry,
                         "nothing built for revision " + std::to_string(document_rev),
                         {}));
}

ports::GeometryStatus ManifoldGeometryPort::status(std::optional<std::string>,
                                                   std::optional<std::string>) {
  return last_status_;
}

void ManifoldGeometryPort::clear_cache() {
  cached_rev_.reset();
  cached_ = {};
  last_status_ = ports::GeometryStatus::Unknown;
}

}  // namespace toporoom::adapters
