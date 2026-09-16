#include "toporoom/adapters/p1_stubs.hpp"

namespace toporoom::adapters {

ports::P1Status NotImplementedMepAdapter::add_point(const ports::MepPoint&) {
  return ports::not_in_p0("MEP");
}

ports::P1Status NotImplementedMepAdapter::add_polyline(const ports::MepPolyline&) {
  return ports::not_in_p0("MEP");
}

ports::P1Status NotImplementedFurnishingAdapter::list_catalog(
    std::vector<ports::FurnishingItem>& out) {
  out.clear();
  return ports::not_in_p0("soft furnishing library");
}

ports::P1Status NotImplementedFurnishingAdapter::place(const std::string&,
                                                      const std::string&) {
  return ports::not_in_p0("soft furnishing library");
}

ports::P1Status NotImplementedCloudSyncAdapter::push_document(const std::string&) {
  return ports::not_in_p0("cloud sync");
}

ports::P1Status NotImplementedCloudSyncAdapter::pull_document(const std::string&) {
  return ports::not_in_p0("cloud sync");
}

ports::P1Status NotImplementedQuoteAdapter::quote_document(const std::string&,
                                                          std::string& quote_json) {
  quote_json.clear();
  return ports::not_in_p0("auto quoting");
}

}  // namespace toporoom::adapters
