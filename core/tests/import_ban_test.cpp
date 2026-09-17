#include <filesystem>
#include <fstream>
#include <regex>
#include <string>

#include <gtest/gtest.h>

#ifndef TOPOROOM_CORE_SOURCE_DIR
#error TOPOROOM_CORE_SOURCE_DIR is required
#endif

namespace fs = std::filesystem;

namespace {

bool is_domain_source(const fs::path& path) {
  const auto ext = path.extension().string();
  if (ext != ".hpp" && ext != ".h" && ext != ".cpp" && ext != ".cc") return false;
  const auto text = path.generic_string();
  return text.find("/domain/") != std::string::npos ||
         text.find("\\domain\\") != std::string::npos;
}

}  // namespace

TEST(ImportBan, DomainMustNotImportManifoldThreeOrGodot) {
  const std::regex forbidden(
      R"(^\s*#\s*include\s*[<"][^>"]*(manifold|three|godot|nlohmann/json|orbbec|realsense|libuvc|android/bluetooth|nimble|esp_gatt))",
      std::regex::icase);
  int scanned = 0;
  for (const auto& entry :
       fs::recursive_directory_iterator(std::string(TOPOROOM_CORE_SOURCE_DIR))) {
    if (!entry.is_regular_file()) continue;
    const auto path = entry.path();
    if (!is_domain_source(path)) continue;
    std::ifstream in(path);
    ASSERT_TRUE(in) << path;
    std::string line;
    int line_no = 0;
    while (std::getline(in, line)) {
      ++line_no;
      if (std::regex_search(line, forbidden)) {
        FAIL() << path << ":" << line_no << " forbidden include: " << line;
      }
    }
    ++scanned;
  }
  EXPECT_GT(scanned, 0);
}
