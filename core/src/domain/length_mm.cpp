#include "toporoom/domain/length_mm.hpp"

// Header-only value object; this TU exists so the library always lists the
// domain module in the build graph.
namespace toporoom::domain {
int length_mm_module() { return 0; }
}  // namespace toporoom::domain
