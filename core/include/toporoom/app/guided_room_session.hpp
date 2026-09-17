#pragma once

#include <string>

#include "toporoom/domain/kinds.hpp"
#include "toporoom/domain/scene_ir.hpp"

namespace toporoom::app {

enum class GuidePhase {
  HostCheck,
  DrawWalls,
  MeasureKeys,
  PlaceOpenings,
  Rebuild,
  ExportReady
};

inline const char* to_string(GuidePhase phase) {
  switch (phase) {
    case GuidePhase::HostCheck:
      return "host_check";
    case GuidePhase::DrawWalls:
      return "draw_walls";
    case GuidePhase::MeasureKeys:
      return "measure_keys";
    case GuidePhase::PlaceOpenings:
      return "place_openings";
    case GuidePhase::Rebuild:
      return "rebuild";
    case GuidePhase::ExportReady:
      return "export";
  }
  return "host_check";
}

// Guided one-room 量房会话 (CaptureSession). No independent Survey AR (D6).
// Export is allowed when:
//   host OK, ≥4 walls, ≥1 opening, rebuild OK, and
//   ≥2 laser key edges OR (typed explicit AND ≥2 typed key edges).
class GuidedRoomSession {
 public:
  void mark_host_ok(bool ok);
  void note_wall();
  void note_opening();
  void note_key_measurement(domain::MeasurementSource source, bool typed_explicit);
  void note_rebuild(bool ok);

  // Replace counters from the 方案 document (量房会话 observes FloorPlanDocument).
  void observe_scene(const domain::SceneIR& scene, bool rebuild_ok);

  GuidePhase phase() const;
  bool can_export() const;
  std::string blocking_reason() const;

  int walls() const noexcept { return walls_; }
  int openings() const noexcept { return openings_; }
  int laser_keys() const noexcept { return laser_keys_; }
  int typed_keys() const noexcept { return typed_keys_; }
  bool typed_explicit() const noexcept { return typed_explicit_; }
  bool host_ok() const noexcept { return host_ok_; }
  bool rebuild_ok() const noexcept { return rebuild_ok_; }

 private:
  bool keys_satisfied() const;
  bool walls_satisfied() const { return walls_ >= 4; }
  bool openings_satisfied() const { return openings_ >= 1; }

  bool host_ok_ = false;
  int walls_ = 0;
  int openings_ = 0;
  int laser_keys_ = 0;
  int typed_keys_ = 0;
  bool typed_explicit_ = false;
  bool rebuild_ok_ = false;
};

using CaptureSession = GuidedRoomSession;

}  // namespace toporoom::app
