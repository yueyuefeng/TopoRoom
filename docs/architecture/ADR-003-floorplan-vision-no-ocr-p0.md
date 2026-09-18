# ADR-003 — P0 floor-plan vision: raster heuristics, no OCR

- **Status**: Accepted (product decision 2026-09-17)
- **Date**: 2026-09-17
- **Amends**: photo import path in [ADR-001](./ADR-001-godot-interaction-shell-host.md)
- **Pipeline**: [floorplan-vision-pipeline.md](./floorplan-vision-pipeline.md)
- **Golden fixture**: `core/fixtures/vision/apt-plan-user-01.png`

## Context

After **拍户型图 / 从相册导入**, the host must immediately:

1. Classify **承重/剪力墙 + 柱**, **门/窗**, **砌体/隔墙**
2. Emit walls/openings through C API commands into `FloorPlanDocument`
3. Rebuild 3D from SceneIR (BoxMesh preview / StatusGate solids)

The input is a CAD-like raster (Chinese apartment plan), not a depth scan.
Pixels must never become millimetre truth (I1, I8). Critical edges still come
from **laser / typed** commands.

## Decision

P0 analyzer is `FloorPlanRasterAnalyzer`: geometric heuristics on a decoded
raster. **No OCR library is used.**

| Layer | Choice |
|-------|--------|
| Decode | `stb_image` (`stb_image.h` + `stb_image_impl.cpp`) for PNG/JPEG |
| Vision | axis-aligned run-length blobs, thickness scale, gap heuristics |
| OpenCV | **not** linked |
| Tesseract / PaddleOCR / CN OCR / ML weights | **not** linked |
| Cloud vision API | **not** called |
| FakeVisionAdapter | kept for `fixture:photo` / tiny PNG guided demo only |

C API: `toporoom_vision_import_image` → `add_wall` / `add_opening` → SceneIR.
Godot `Session.import_photo_vision` uses the raster path for real files;
`fixture:photo` stays Fake.

There are **no OCR stubs in C++ or GDScript**. Dimension strings and room
names on the drawing are ignored in P0 (documented as P1 in the pipeline
doc, not as half-wired code).

## Alternatives considered (rejected for P0)

| Option | Why not P0 |
|--------|------------|
| **Tesseract / PaddleOCR / Chinese OCR** for mm labels and 主卧/客餐厅 names | Extra native deps on Android GDExtension, APK size, CJK font/orientation variance, and still would not be survey-grade. Deferred **P1**. |
| **OpenCV** contour / morphology pipeline | Binary size and NDK build complexity next to godot-cpp + Manifold. Raster heuristics cover the golden CAD export without it. Deferred if a later photo-of-paper path needs it. |
| **Cloud vision API** | Conflicts with P0 **offline** host and photo **privacy**. Rejected for P0. |
| **FakeVisionAdapter only** | Fine for the 一室 guided demo; insufficient once the user uploads a real 户型图 (product requirement). |
| **On-device ML detector** | No trained weights in-tree; not reproducible in CI. Out of P0. |

## Accuracy posture

Not survey-grade. The golden fixture (`apt-plan-user-01`) is a **regression
floor**, not a claimed field accuracy.

`./build/core/toporoom_tests --gtest_filter='FloorPlanRaster*'`
(`core/tests/floor_plan_raster_vision_test.cpp` +
`core/tests/floor_plan_raster_geom_test.cpp`) plus
`core/fixtures/vision/apt-plan-user-01.expected.json`:

| Check | Floor (expected.json) | Recorded golden apply (`apt-plan-user-01.sceneir.json`) | This iteration (raster) |
|-------|------------------------|----------------------------------------------------------|-------------------------|
| Shear / 承重 | ≥ 12 | 22 | 42 |
| Masonry / 砌体 | ≥ 8 | 20 | 32 |
| Doors | ≥ 3 | 6 | 8 |
| Windows | ≥ 3 | 7 | 8 |
| Bay / 飘窗 | ≥ 1 | — | 6 |
| Floor-ceiling / 落地窗 | ≥ 1 | — | 1 |
| Columns (nearly-square shear) | ≥ 2 | (counted in shear bars) | (counted in shear bars) |
| Walls applied | ≥ 18 | 42 | 74 |
| Openings applied | ≥ 4 | 13 | 16 |
| Exterior | living + 阳台 enclosed; interior ≥ 45 m² | open fragments | closed hull (this iteration) |
| Scale | 12–28 mm/px (200 mm bar thickness) | bbox ≈ **9600 × 8663 mm** | same |
| Rebuild | StatusGate `ok` | `ok` | `ok` |

Plan width must not collapse to FakeVision’s 4000 mm rectangle.

Additive SceneIR 0.2 `opening.subtype` (`bay` / `floorCeiling` / `standard`);
omitted when unspecified so 0.1 readers stay valid.

**mm source of truth for critical edges remains laser / typed commands.**
Vision places topology (which wall is shear, where a door likely sits).
Users confirm 承重 vs 砌体 in the Godot review screen before 3D.

## Consequences

- Android GDExtension stays `stb_image` + core; no OCR/OpenCV `.so`.
- Misread doors/windows are editable via existing punch / update_opening /
  demolish commands (and 3D gizmos).
- Scale error from assuming 200 mm shear thickness is expected on drawings
  that are not 1:50 CAD exports; P1 OCR of perimeter mm strings can refine.

## P1 (not started)

- OCR of dimension strings and room names
- Quarter-circle swing side
- Photo deskew / perspective of a paper sheet

## Links

- Implementation: `core/src/adapters/floor_plan_raster_analyzer.cpp`
- Port: `RasterVisionAdapter` / `FakeVisionAdapter`
- Fixture: `core/fixtures/vision/apt-plan-user-01.{png,expected.json,sceneir.json}`
