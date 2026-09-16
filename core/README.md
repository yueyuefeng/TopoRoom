# TopoRoom core

C++20 static library: SceneIR domain, ports, application services, C API.

Production geometry is `ManifoldGeometryPort` (CrossSection → Extrude →
Boolean). Domain sources must not `#include` manifold — see
`core/adapters/STUBS.md` and NFR-015.

Hardware adapters (depth / laser / IMU) are not in this milestone.
