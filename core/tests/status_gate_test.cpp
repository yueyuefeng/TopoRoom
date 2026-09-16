#include <gtest/gtest.h>

#include "toporoom/app/status_gate.hpp"
#include "toporoom/ports/geometry_port.hpp"

using toporoom::app::ExportRejectedError;
using toporoom::app::StatusGate;
using toporoom::ports::FaultCode;
using toporoom::ports::RebuildResult;

TEST(StatusGate, RejectsFault) {
  StatusGate gate;
  RebuildResult result;
  result.ok = false;
  result.fault = {FaultCode::NotManifold, "non-manifold solid", {"wall_s"}};
  EXPECT_THROW(gate.assert_exportable(result), ExportRejectedError);
}

TEST(StatusGate, AllowsOk) {
  StatusGate gate;
  RebuildResult result;
  result.ok = true;
  EXPECT_NO_THROW(gate.assert_exportable(result));
}
