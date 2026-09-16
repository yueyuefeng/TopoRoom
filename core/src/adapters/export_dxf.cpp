#include "toporoom/adapters/export_dxf.hpp"

#include <cmath>
#include <sstream>
#include <string>
#include <utility>

namespace toporoom::adapters {
namespace {

void line(std::ostringstream& out, const char* layer, double x1, double y1, double x2,
          double y2) {
  out << "0\nLINE\n8\n" << layer << "\n10\n"
      << round_mm(x1) << "\n20\n"
      << round_mm(y1) << "\n30\n0\n11\n"
      << round_mm(x2) << "\n21\n"
      << round_mm(y2) << "\n31\n0\n";
}

void text(std::ostringstream& out, const char* layer, double x, double y,
          const std::string& value) {
  out << "0\nTEXT\n8\n" << layer << "\n10\n"
      << round_mm(x) << "\n20\n"
      << round_mm(y) << "\n30\n0\n40\n150\n1\n"
      << value << "\n";
}

std::pair<double, double> normalize(double dx, double dy) {
  const double length = std::hypot(dx, dy);
  if (!(length > 0)) return {1.0, 0.0};
  return {dx / length, dy / length};
}

}  // namespace

std::string export_dxf(const domain::SceneIR& scene) {
  std::ostringstream out;
  out << "0\nSECTION\n2\nHEADER\n9\n$ACADVER\n1\nAC1009\n9\n$INSUNITS\n70\n4\n0\n"
         "ENDSEC\n"
         "0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n3\n"
         "0\nLAYER\n2\nWALLS\n70\n0\n62\n7\n6\nCONTINUOUS\n"
         "0\nLAYER\n2\nOPENINGS\n70\n0\n62\n4\n6\nCONTINUOUS\n"
         "0\nLAYER\n2\nDIMS\n70\n0\n62\n2\n6\nCONTINUOUS\n"
         "0\nENDTAB\n0\nENDSEC\n"
         "0\nSECTION\n2\nENTITIES\n";

  for (const auto& storey : scene.storeys) {
    for (const auto& wall : storey.walls) {
      line(out, "WALLS", wall.start.x, wall.start.y, wall.end.x, wall.end.y);
      const double dx = wall.end.x - wall.start.x;
      const double dy = wall.end.y - wall.start.y;
      const auto [ux, uy] = normalize(dx, dy);
      const double length = std::hypot(dx, dy);
      const double mx = (wall.start.x + wall.end.x) / 2.0;
      const double my = (wall.start.y + wall.end.y) / 2.0;
      const double nx = -uy;
      const double ny = ux;
      text(out, "DIMS", mx + nx * 250.0, my + ny * 250.0,
           std::to_string(round_mm(length)) + " " + wall.id);

      for (const auto& opening : wall.openings) {
        const double x0 = wall.start.x + ux * opening.offset_mm;
        const double y0 = wall.start.y + uy * opening.offset_mm;
        const double x1 = wall.start.x + ux * (opening.offset_mm + opening.width_mm);
        const double y1 = wall.start.y + uy * (opening.offset_mm + opening.width_mm);
        line(out, "OPENINGS", x0, y0, x1, y1);
        const double jx = nx * (wall.thickness_mm * 0.5);
        const double jy = ny * (wall.thickness_mm * 0.5);
        line(out, "OPENINGS", x0 - jx, y0 - jy, x0 + jx, y0 + jy);
        line(out, "OPENINGS", x1 - jx, y1 - jy, x1 + jx, y1 + jy);
        text(out, "DIMS", (x0 + x1) / 2.0 + nx * 180.0, (y0 + y1) / 2.0 + ny * 180.0,
             std::to_string(round_mm(opening.width_mm)) + " " + opening.id);
      }
    }
  }
  for (const auto& measurement : scene.measurements) {
    text(out, "DIMS", 200, -400.0 - 200.0 * static_cast<double>(measurement.id.size() % 5),
         std::to_string(round_mm(measurement.value_mm)) + " " + measurement.id);
  }

  out << "0\nENDSEC\n0\nEOF\n";
  return out.str();
}

}  // namespace toporoom::adapters
