#include "toporoom/app/session_isolate.hpp"

namespace toporoom::app {

std::shared_ptr<std::mutex> SessionIsolate::mutex_for(const std::string& document_id) {
  std::lock_guard<std::mutex> guard(map_mutex_);
  auto& slot = locks_[document_id];
  if (!slot) {
    slot = std::make_shared<std::mutex>();
  }
  return slot;
}

}  // namespace toporoom::app
