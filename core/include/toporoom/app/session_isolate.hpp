#pragma once

#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>

namespace toporoom::app {

class SessionIsolate {
 public:
  template <typename F>
  auto enqueue(const std::string& document_id, F&& task) -> decltype(task()) {
    auto lock = mutex_for(document_id);
    std::lock_guard<std::mutex> guard(*lock);
    return task();
  }

 private:
  std::shared_ptr<std::mutex> mutex_for(const std::string& document_id);

  std::mutex map_mutex_;
  std::unordered_map<std::string, std::shared_ptr<std::mutex>> locks_;
};

}  // namespace toporoom::app
