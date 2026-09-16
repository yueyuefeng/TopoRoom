#include <gtest/gtest.h>

#include "toporoom/app/guided_room_session.hpp"
#include "toporoom/domain/kinds.hpp"

using toporoom::app::GuidePhase;
using toporoom::app::GuidedRoomSession;
using toporoom::domain::MeasurementSource;

namespace {

void complete_geometry(GuidedRoomSession& guide) {
  guide.mark_host_ok(true);
  for (int i = 0; i < 4; ++i) guide.note_wall();
  guide.note_opening();
  guide.note_rebuild(true);
}

}  // namespace

TEST(GuidedRoom, StartsAtHostCheck) {
  GuidedRoomSession guide;
  EXPECT_EQ(guide.phase(), GuidePhase::HostCheck);
  EXPECT_FALSE(guide.can_export());
}

TEST(GuidedRoom, TwoLaserKeysAllowExport) {
  GuidedRoomSession guide;
  complete_geometry(guide);
  guide.note_key_measurement(MeasurementSource::Laser, false);
  EXPECT_FALSE(guide.can_export());
  EXPECT_EQ(guide.phase(), GuidePhase::MeasureKeys);
  guide.note_key_measurement(MeasurementSource::Laser, false);
  EXPECT_TRUE(guide.can_export());
  EXPECT_EQ(guide.phase(), GuidePhase::ExportReady);
}

TEST(GuidedRoom, TypedRequiresExplicitFlag) {
  GuidedRoomSession guide;
  complete_geometry(guide);
  guide.note_key_measurement(MeasurementSource::Typed, false);
  guide.note_key_measurement(MeasurementSource::Typed, false);
  EXPECT_FALSE(guide.can_export());
  EXPECT_NE(guide.blocking_reason().find("typed explicit"), std::string::npos);

  GuidedRoomSession explicit_typed;
  complete_geometry(explicit_typed);
  explicit_typed.note_key_measurement(MeasurementSource::Typed, true);
  explicit_typed.note_key_measurement(MeasurementSource::Typed, true);
  EXPECT_TRUE(explicit_typed.can_export());
}

TEST(GuidedRoom, RebuildMustSucceed) {
  GuidedRoomSession guide;
  guide.mark_host_ok(true);
  for (int i = 0; i < 4; ++i) guide.note_wall();
  guide.note_key_measurement(MeasurementSource::Laser, false);
  guide.note_key_measurement(MeasurementSource::Laser, false);
  guide.note_opening();
  EXPECT_EQ(guide.phase(), GuidePhase::Rebuild);
  guide.note_rebuild(false);
  EXPECT_FALSE(guide.can_export());
  guide.note_rebuild(true);
  EXPECT_TRUE(guide.can_export());
}
