#include "toporoom/adapters/export_pdf.hpp"

#include "toporoom/adapters/export_dxf.hpp"

#include <cstdio>
#include <algorithm>
#include <cmath>
#include <sstream>
#include <string>
#include <vector>

namespace toporoom::adapters {
namespace {

std::string pdf_escape(const std::string& text) {
  std::string out;
  out.reserve(text.size());
  for (char ch : text) {
    if (ch == '(' || ch == ')' || ch == '\\') out.push_back('\\');
    out.push_back(ch);
  }
  return out;
}

std::pair<double, double> normalize(double dx, double dy) {
  const double length = std::hypot(dx, dy);
  if (!(length > 0)) return {1.0, 0.0};
  return {dx / length, dy / length};
}

}  // namespace

std::vector<std::uint8_t> export_pdf(const domain::SceneIR& scene) {
  constexpr double kPageW = 842;
  constexpr double kPageH = 595;
  constexpr double kMargin = 48;

  double minx = 0;
  double miny = 0;
  double maxx = 1;
  double maxy = 1;
  bool any = false;
  for (const auto& storey : scene.storeys) {
    for (const auto& wall : storey.walls) {
      for (const auto* p : {&wall.start, &wall.end}) {
        if (!any) {
          minx = maxx = p->x;
          miny = maxy = p->y;
          any = true;
        } else {
          minx = std::min(minx, p->x);
          miny = std::min(miny, p->y);
          maxx = std::max(maxx, p->x);
          maxy = std::max(maxy, p->y);
        }
      }
    }
  }
  const double span_x = std::max(1.0, maxx - minx);
  const double span_y = std::max(1.0, maxy - miny);
  const double scale =
      std::min((kPageW - 2 * kMargin) / span_x, (kPageH - 2 * kMargin) / span_y);

  auto mapx = [&](double x) { return kMargin + (x - minx) * scale; };
  auto mapy = [&](double y) { return kMargin + (y - miny) * scale; };

  std::ostringstream content;
  content << "BT /F1 14 Tf " << kMargin << " " << (kPageH - 36)
          << " Td (TopoRoom unit plan mm) Tj ET\n";

  auto draw_line = [&](double x1, double y1, double x2, double y2, double width) {
    content << width << " w " << mapx(x1) << " " << mapy(y1) << " m " << mapx(x2) << " "
            << mapy(y2) << " l S\n";
  };
  auto draw_text = [&](double x, double y, const std::string& label) {
    content << "BT /F1 9 Tf " << mapx(x) << " " << mapy(y) << " Td (" << pdf_escape(label)
            << ") Tj ET\n";
  };

  for (const auto& storey : scene.storeys) {
    for (const auto& wall : storey.walls) {
      content << "0.1 0.1 0.1 RG\n";
      draw_line(wall.start.x, wall.start.y, wall.end.x, wall.end.y, 2.2);
      const double dx = wall.end.x - wall.start.x;
      const double dy = wall.end.y - wall.start.y;
      const auto [ux, uy] = normalize(dx, dy);
      const double length = std::hypot(dx, dy);
      const double mx = (wall.start.x + wall.end.x) / 2.0;
      const double my = (wall.start.y + wall.end.y) / 2.0;
      draw_text(mx, my, std::to_string(round_mm(length)) + " " + wall.id);
      content << "0.1 0.3 0.7 RG\n";
      for (const auto& opening : wall.openings) {
        const double x0 = wall.start.x + ux * opening.offset_mm;
        const double y0 = wall.start.y + uy * opening.offset_mm;
        const double x1 = wall.start.x + ux * (opening.offset_mm + opening.width_mm);
        const double y1 = wall.start.y + uy * (opening.offset_mm + opening.width_mm);
        draw_line(x0, y0, x1, y1, 1.2);
        draw_text((x0 + x1) / 2.0, (y0 + y1) / 2.0,
                  std::to_string(round_mm(opening.width_mm)) + " " + opening.id);
      }
    }
  }

  const std::string stream = content.str();
  std::vector<std::string> objects;
  objects.push_back("<< /Type /Catalog /Pages 2 0 R >>");
  objects.push_back("<< /Type /Pages /Kids [3 0 R] /Count 1 >>");
  objects.push_back(
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 842 595] /Contents 4 0 R "
      "/Resources << /Font << /F1 5 0 R >> >> >>");
  objects.push_back("<< /Length " + std::to_string(stream.size()) + " >>\nstream\n" +
                    stream + "endstream");
  objects.push_back("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>");

  std::string out = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
  std::vector<std::size_t> offsets(objects.size() + 1, 0);
  for (std::size_t i = 0; i < objects.size(); ++i) {
    offsets[i + 1] = out.size();
    out += std::to_string(i + 1) + " 0 obj\n" + objects[i] + "\nendobj\n";
  }
  const std::size_t xref = out.size();
  out += "xref\n0 " + std::to_string(objects.size() + 1) + "\n";
  out += "0000000000 65535 f \n";
  for (std::size_t i = 1; i <= objects.size(); ++i) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%010zu 00000 n \n", offsets[i]);
    out += buf;
  }
  out += "trailer << /Size " + std::to_string(objects.size() + 1) +
         " /Root 1 0 R >>\nstartxref\n" + std::to_string(xref) + "\n%%EOF\n";
  return {out.begin(), out.end()};
}

}  // namespace toporoom::adapters
