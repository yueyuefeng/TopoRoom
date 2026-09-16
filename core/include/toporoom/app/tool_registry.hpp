#pragma once

#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace toporoom::app {

class ToolRegistry {
 public:
  void register_tool(const std::string& id) {
    if (tools_.contains(id)) {
      throw std::runtime_error("Tool '" + id + "' is already registered");
    }
    tools_[id] = true;
    order_.push_back(id);
  }

  bool has(const std::string& id) const { return tools_.contains(id); }

  std::vector<std::string> list() const { return order_; }

 private:
  std::unordered_map<std::string, bool> tools_;
  std::vector<std::string> order_;
};

}  // namespace toporoom::app
