# Floor-plan vision pipeline (户型图识别)

Godot **拍户型图 / 从相册导入** copies a raster into `user://imports/`, then the
C API runs `FloorPlanRasterAnalyzer` (not Fake 4000×3000). Pixels never become
SceneIR millimetres directly: the analyzer emits wall centerlines + openings,
and `FloorPlanDocument` commands write the 方案.

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
   `OpeningKind::Window` (sill 900 mm / height 1400 mm).
8. **Rooms / OCR** — 主卧/客餐厅 labels are **not** OCR’d in P0. Flood-fill
   room close is optional later.
9. **Emit** — `add_wall` / `add_opening` → SceneIR 0.2 → Manifold rebuild →
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
