#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace toporoom::domain {

// WallKind: masonry / shear / partition / … (P0 keeps exterior|interior|partition).
enum class WallKind { Exterior, Interior, Partition, Masonry, ShearWall };

// OpeningKind is required (I3 / I12). UI: 门洞 / 窗洞 / 垭口 — never a bare Opening.
enum class OpeningKind { Door, Window, Archway };

// Additive SceneIR 0.2+ window subtype. Empty/Unspecified keeps 0.1 readers valid.
// UI: 普通窗 / 飘窗 / 落地窗. Kind stays `window`.
enum class WindowSubtype { Unspecified, Standard, Bay, FloorCeiling };

// MeasureSource (industry). UI: 激光实测 / 手工录入 / 深度辅助拟合.
enum class MeasurementSource { Laser, Typed, DepthFit };
using MeasureSource = MeasurementSource;

enum class MeasurementKind { Length };

// FaceDatum: P0 document/session 面层口径 (D9). Wall finish split is P1.
enum class FaceDatum { Structural, Architectural, Finished };

// SpaceType on Room (禁无类型 Space).
enum class SpaceType { Interior, Balcony, Exterior };

// HostedComponent.kind — 梁/柱/烟道. Model exists; not a P0 Done gate (D4).
enum class HostedKind { Beam, Column, Flue };

const char* to_string(WallKind kind);
const char* to_string(OpeningKind kind);
const char* to_string(WindowSubtype subtype);
const char* to_string(MeasurementSource source);
const char* to_string(FaceDatum datum);
const char* to_string(SpaceType space_type);
const char* to_string(HostedKind kind);

std::optional<WallKind> wall_kind_from_string(std::string_view value);
std::optional<OpeningKind> opening_kind_from_string(std::string_view value);
std::optional<WindowSubtype> window_subtype_from_string(std::string_view value);
std::optional<MeasurementSource> measurement_source_from_string(
    std::string_view value);
std::optional<FaceDatum> face_datum_from_string(std::string_view value);
std::optional<SpaceType> space_type_from_string(std::string_view value);
std::optional<HostedKind> hosted_kind_from_string(std::string_view value);

bool is_measurement_source(std::string_view value);
bool is_scene_ir_version_supported(std::string_view value);

// 承重/剪力墙 — demolish / punch / split-out requires an explicit force flag.
inline bool is_shear_wall(WallKind kind) noexcept {
  return kind == WallKind::ShearWall;
}

}  // namespace toporoom::domain
