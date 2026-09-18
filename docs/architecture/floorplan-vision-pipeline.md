# Floor-plan vision pipeline (户型图识别)

Godot **拍户型图 / 从相册导入** copies a raster into `user://imports/`, then the
C API runs `FloorPlanRasterAnalyzer` (not Fake 4000×3000). Pixels never become
SceneIR millimetres directly: the analyzer emits wall centerlines + openings,
and `FloorPlanDocument` commands write the 方案.

**Scheme decision (paper trail):** [ADR-003](./ADR-003-floorplan-vision-no-ocr-p0.md)
— P0 is raster heuristics + `stb_image` only; **no OCR library**.

## Decision log

| Date | Decision | Notes |
|------|----------|--------|
| 2026-09-17 | P0 = `FloorPlanRasterAnalyzer` geometric heuristics; **no OCR** | ADR-003. Decode with `stb_image`. No OpenCV, Tesseract, PaddleOCR, cloud API. FakeVision kept only for `fixture:photo`. |
| 2026-09-17 | Golden fixture `apt-plan-user-01.png` | User CAD-like apartment plan. Scale = 200 mm shear-bar thickness. Room-name / mm-string OCR deferred P1. |
| 2026-09-17 | Real gallery/camera files → raster C API | `Session.import_photo_vision` → `toporoom_vision_import_image`. Tiny Fake path unchanged. |
| 2026-09-17 | Closed envelope + window subtypes | Merge collinear (T-junctions block room-scale joins), snap corners, split T-nodes for the graph, close outer/bbox degree-1 gaps. Additive SceneIR `opening.subtype`: `bay` (飘窗) / `floorCeiling` (落地窗). Golden: enclosed 3D (flood-fill interior ≥ 2 m²), ≥1 bay, ≥1 floor-ceiling. |

## Stages

1. **Load** — PNG/JPEG via `stb_image` (grayscale classification on RGB).
2. **Preprocess** — classify pixels: near-black structural ink, low-saturation
   mid-gray partition ink, ignore floor fills and labels. Crop to the
   structural bounding box (deskew/OCR are P1).
3. **Scale** — median thickness of black bars is treated as **200 mm**
   (typical 剪力墙). Dimension-string OCR is P1; the golden fixture
   (`apt-plan-user-01.png`) is calibrated this way. Tick-span detection can
   refine later.
4. **Structural** — extract axis-aligned rectangles from black blobs
   (run-length merge). Long bars → `shearWall`. Nearly square bars → short
   shear segments (columns in plan).
5. **Partition** — same extractor on gray ink inside the plan bbox, dropping
   1 px dimension ticks. → `masonry`.
6. **Doors** — collinear centerline gaps in the ~700–1000 mm band, plus
   interior gaps up to a double-leaf width. `OpeningKind::Door` on the nearest
   host wall. Quarter-circle swing arcs are **not** fully vectorized (P1).
7. **Windows** — gray bars on the outer bbox, and wider exterior gaps.
   `OpeningKind::Window` with additive `WindowSubtype`:
   - **bay / 飘窗** — U-pocket (parallel walls + connector; short stub is the
     extrusion), typically sill 400 mm
   - **floorCeiling / 落地窗** — width ≥ 1500 mm or sill≈0 and height≈storey
   - **standard** — sill 900 mm / height 1400 mm
8. **Envelope close** — `merge_collinear_segments` (do not join across a
   T-junction), `snap_endpoints`, `split_at_nodes`, `close_exterior_loop`
   (extend to hits, outer-cycle fills, bbox degree-1 L-fills). Prefer fewer
   long host walls; openings sit on them. Enclosure is tested by a flood-fill
   of the wall raster (interior pocket ≥ 2 m²).
9. **Rooms / OCR** — 主卧/客餐厅 labels are **not** OCR’d in P0. Flood-fill
   room labels remain P1.
10. **Emit** — `add_wall` / `add_opening` → SceneIR 0.2 → Manifold rebuild →
   Godot 2D canvas and 3D extrusions.

## Golden fixture

`core/fixtures/vision/apt-plan-user-01.png` (also `godot/fixtures/`):

| Ink | Meaning |
|-----|---------|
| Thick solid black | 承重/剪力墙 and columns |
| Thinner gray | 砌体/隔墙 |
| Door swing arcs | 门洞 (heuristic gaps in P0) |
| Parallel light bars on the envelope | 窗洞 |
| 主卧/次卧/… + m² | room names (P1 OCR) |
| Perimeter mm strings | scale (P1 OCR; P0 uses 200 mm bar thickness) |

C API: `toporoom_vision_import_image(doc, path, &counts, err, errlen)` runs the
raster analyzer and writes walls/openings. Godot calls
`TopoRoomHost.import_vision_image`.

## Accuracy

Not survey-grade. Laser / typed commands remain millimetre truth for critical
edges. Vision is a topology prior that users confirm (承重 vs 砌体) before 3D.

Regression floor: `--gtest_filter='FloorPlanRaster*'`
(`core/tests/floor_plan_raster_vision_test.cpp`) reading
`core/fixtures/vision/apt-plan-user-01.expected.json`.

| Metric | Test floor (`expected.json`) | This iteration (raster apply) | Prior SceneIR file |
|--------|------------------------------|-------------------------------|---------------------|
| Shear walls | ≥ 12 | 22 | 22 |
| Masonry walls | ≥ 8 | 14 | 20 |
| Doors | ≥ 3 | 6 | 6 |
| Windows | ≥ 3 | 9 | 7 |
| Bay / 飘窗 | ≥ 1 | 3 detected / 3 in SceneIR | (unspecified) |
| Floor-ceiling / 落地窗 | ≥ 1 | 2 detected / ≥1 in SceneIR | (unspecified) |
| Columns | ≥ 2 | in shear set | in shear set |
| Walls applied | ≥ 18 | 36 | 42 |
| Openings applied | ≥ 4 | 15 | 13 |
| Exterior gap | ≤ 150 mm (flood interior ≥ 2 m²) | 0 (closed) | open envelope |
| mm/px | 12–28 | 200 mm / median black bar | 200 mm / median black bar |
| Plan bbox | width 7000–20000 mm, not Fake 4000 | ≈ 9600 × 8663 mm | ≈ 9600 × 8663 mm |
| Rebuild | StatusGate `ok` | `ok` | `ok` |

Tests: `FixtureLoadsPng`, `GoldenApartmentHasShearMasonryDoorsWindows`,
`ApplyAndSceneIrRoundTripRebuildOk`, `GoldenSceneIrFileRoundTrip`,
`AdapterRejectsMissingFile`, `MissingPathCApiFails`,
`GoldenExteriorIsClosedLoop`, `GoldenHasBayAndFloorCeilingWindows`,
plus `RasterGeom.*` (`MergeCollinearJoinsFragments`, `SnapEndpointsJoinsCornerGap`,
`CloseExteriorLoopFillsDegreeOneGap`, `CloseExteriorLoopFillsLCorner`,
`SplitAtNodesMakesTeeNotAGap`, `ClassifyWindowSubtypeBayAndFloorCeiling`).

## How to run

```bash
cmake -S . -B build -DTOPOROOM_BUILD_TESTS=ON && cmake --build build --parallel
./build/core/toporoom_tests --gtest_filter='FloorPlanRaster*'
# or: ctest --test-dir build --output-on-failure
```

Godot: gallery/camera copies into `user://imports/`, then
`import_vision_image` → review (承重 vs 砌体, 门窗) → **进入 3D**.
`用示例图试试` uses `godot/fixtures/apt-plan-user-01.png`. `fixture:photo`
still uses FakeVision for the old 一室 demo.

## Known gaps (P1)

- OCR of dimension strings and room names
- Explicit quarter-circle swing side
- Photo deskew / perspective of a paper sheet (this fixture is a flat export)
