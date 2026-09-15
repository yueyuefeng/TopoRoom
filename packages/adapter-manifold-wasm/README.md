# adapter-manifold-wasm

P0 placeholder. Geometry compilation in this milestone uses `FakeGeometryPort`
(`@toporoom/ports/fakes`).

Real adapter (not in this slice):

- `CrossSection → Extrude → Boolean(Subtract openings)`
- WASM worker runtime (NFR-019)
- **Only this package** may import `manifold` / `manifold-3d` (I2 / NFR-015)

Do not leak `Manifold`, `CrossSection`, or `MeshGL` into domain aggregates.
