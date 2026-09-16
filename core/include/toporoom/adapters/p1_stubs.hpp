#pragma once

#include <string>
#include <vector>

#include "toporoom/ports/cloud_sync_port.hpp"
#include "toporoom/ports/furnishing_port.hpp"
#include "toporoom/ports/mep_port.hpp"
#include "toporoom/ports/takeoff_quote_port.hpp"

namespace toporoom::adapters {

class NotImplementedMepAdapter : public ports::MepPort {
 public:
  ports::P1Status add_point(const ports::MepPoint& point) override;
  ports::P1Status add_polyline(const ports::MepPolyline& polyline) override;
};

class NotImplementedFurnishingAdapter : public ports::FurnishingLibraryPort {
 public:
  ports::P1Status list_catalog(std::vector<ports::FurnishingItem>& out) override;
  ports::P1Status place(const std::string& document_id, const std::string& sku) override;
};

class NotImplementedCloudSyncAdapter : public ports::CloudSyncPort {
 public:
  ports::P1Status push_document(const std::string& document_id) override;
  ports::P1Status pull_document(const std::string& document_id) override;
};

class NotImplementedQuoteAdapter : public ports::TakeoffQuotePort {
 public:
  ports::P1Status quote_document(const std::string& document_id,
                                 std::string& quote_json) override;
};

}  // namespace toporoom::adapters
