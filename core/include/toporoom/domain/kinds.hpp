#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace toporoom::domain {

enum class WallKind { Exterior, Interior, Partition };
enum class OpeningKind { Door, Window };
enum class MeasurementSource { Laser, Typed, DepthFit };
enum class MeasurementKind { Length };

const char* to_string(WallKind kind);
const char* to_string(OpeningKind kind);
const char* to_string(MeasurementSource source);

std::optional<WallKind> wall_kind_from_string(std::string_view value);
std::optional<OpeningKind> opening_kind_from_string(std::string_view value);
std::optional<MeasurementSource> measurement_source_from_string(
    std::string_view value);

bool is_measurement_source(std::string_view value);

}  // namespace toporoom::domain
