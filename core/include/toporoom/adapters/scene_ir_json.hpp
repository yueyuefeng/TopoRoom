#pragma once

#include <string>
#include <vector>

#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::adapters {

domain::SceneIR load_scene_ir_json(const std::string& json_text);
domain::SceneIR load_scene_ir_file(const std::string& path);
std::string scene_ir_to_json(const domain::SceneIR& scene);
std::vector<std::string> validate_scene_ir_json(const std::string& json_text);

}  // namespace toporoom::adapters
