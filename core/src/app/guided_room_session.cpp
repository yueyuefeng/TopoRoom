#include "toporoom/app/guided_room_session.hpp"

namespace toporoom::app {

void GuidedRoomSession::mark_host_ok(bool ok) { host_ok_ = ok; }

void GuidedRoomSession::note_wall() { ++walls_; }

void GuidedRoomSession::note_opening() { ++openings_; }

void GuidedRoomSession::note_key_measurement(domain::MeasurementSource source,
                                             bool typed_explicit) {
  if (source == domain::MeasurementSource::Laser) {
    ++laser_keys_;
  } else if (source == domain::MeasurementSource::Typed) {
    ++typed_keys_;
    if (typed_explicit) typed_explicit_ = true;
  }
}

void GuidedRoomSession::note_rebuild(bool ok) { rebuild_ok_ = ok; }

bool GuidedRoomSession::keys_satisfied() const {
  return laser_keys_ >= 2 || (typed_explicit_ && typed_keys_ >= 2);
}

GuidePhase GuidedRoomSession::phase() const {
  if (!host_ok_) return GuidePhase::HostCheck;
  if (!walls_satisfied()) return GuidePhase::DrawWalls;
  if (!keys_satisfied()) return GuidePhase::MeasureKeys;
  if (!openings_satisfied()) return GuidePhase::PlaceOpenings;
  if (!rebuild_ok_) return GuidePhase::Rebuild;
  return GuidePhase::ExportReady;
}

bool GuidedRoomSession::can_export() const {
  return host_ok_ && walls_satisfied() && keys_satisfied() && openings_satisfied() &&
         rebuild_ok_;
}

std::string GuidedRoomSession::blocking_reason() const {
  if (!host_ok_) return "host not on Android whitelist (or experimental)";
  if (!walls_satisfied()) return "draw at least 4 walls";
  if (!keys_satisfied()) {
    return "need ≥2 laser key edges, or typed explicit with ≥2 typed edges";
  }
  if (!openings_satisfied()) return "place at least one opening";
  if (!rebuild_ok_) return "rebuild must succeed before export";
  return {};
}

}  // namespace toporoom::app
