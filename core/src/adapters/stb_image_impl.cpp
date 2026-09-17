#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wold-style-cast"
#pragma GCC diagnostic ignored "-Wsign-conversion"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wuseless-cast"
#endif

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_JPEG
#define STBI_ONLY_PNG
#include "stb_image.h"

#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#include "toporoom/adapters/floor_plan_vision_adapters.hpp"

#include <fstream>
#include <string>
#include <vector>

namespace toporoom::adapters {
namespace {

void pack_rgb(const unsigned char* src, int w, int h, int n, RasterImage* out) {
  out->width = w;
  out->height = h;
  out->channels = 3;
  out->rgb.resize(static_cast<std::size_t>(w) * static_cast<std::size_t>(h) * 3u);
  for (int i = 0; i < w * h; ++i) {
    const unsigned char* p = src + static_cast<std::size_t>(i) * static_cast<std::size_t>(n);
    unsigned char r = p[0];
    unsigned char g = n >= 2 ? p[1] : p[0];
    unsigned char b = n >= 3 ? p[2] : p[0];
    if (n == 1) {
      g = r;
      b = r;
    }
    const std::size_t o = static_cast<std::size_t>(i) * 3u;
    out->rgb[o] = r;
    out->rgb[o + 1] = g;
    out->rgb[o + 2] = b;
  }
}

}  // namespace

bool load_raster_image(const std::string& path, const std::vector<std::uint8_t>& bytes,
                       RasterImage* out, std::string* error) {
  if (!out) {
    if (error) *error = "null image out";
    return false;
  }
  int w = 0;
  int h = 0;
  int n = 0;
  unsigned char* data = nullptr;
  if (!bytes.empty()) {
    data = stbi_load_from_memory(bytes.data(), static_cast<int>(bytes.size()), &w, &h, &n, 0);
  } else if (!path.empty()) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
      if (error) *error = "image not found: " + path;
      return false;
    }
    data = stbi_load(path.c_str(), &w, &h, &n, 0);
  }
  if (!data || w <= 0 || h <= 0 || n <= 0) {
    if (error) *error = "cannot decode PNG/JPEG image";
    if (data) stbi_image_free(data);
    return false;
  }
  pack_rgb(data, w, h, n, out);
  stbi_image_free(data);
  return true;
}

}  // namespace toporoom::adapters
