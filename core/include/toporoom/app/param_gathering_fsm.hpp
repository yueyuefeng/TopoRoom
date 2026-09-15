#pragma once

#include <functional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace toporoom::app {

struct ToolStep {
  std::string name;
  std::function<void(const std::string& raw, std::unordered_map<std::string, std::string>& out)>
      parse;
};

class ParamGatheringFSM {
 public:
  explicit ParamGatheringFSM(std::string tool_id, std::vector<ToolStep> steps)
      : tool_id_(std::move(tool_id)), steps_(std::move(steps)) {}

  std::string state() const {
    if (index_ >= steps_.size()) return "complete";
    return "awaiting_" + steps_[index_].name;
  }

  bool complete() const { return index_ >= steps_.size(); }

  const std::unordered_map<std::string, std::string>& params() const { return collected_; }

  void provide(const std::string& step_name, const std::string& raw) {
    if (index_ >= steps_.size()) {
      throw std::runtime_error(tool_id_ + " is already complete");
    }
    const ToolStep& step = steps_[index_];
    if (step.name != step_name) {
      throw std::runtime_error(tool_id_ + " is awaiting '" + step.name + "', not '" +
                               step_name + "'");
    }
    step.parse(raw, collected_);
    ++index_;
  }

 private:
  std::string tool_id_;
  std::vector<ToolStep> steps_;
  std::unordered_map<std::string, std::string> collected_;
  std::size_t index_ = 0;
};

}  // namespace toporoom::app
