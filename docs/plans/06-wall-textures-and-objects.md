# Wall Textures & Objects

**Status:** 🔜 Future

Generated mazes currently use one wall material on uniform `CSGBox3D` walls, so they
read as flat and repetitive. Add visual variety: alternate wall textures and scattered
decorative objects on/along walls (torches, banners, pipes, vines, etc.).

## Approach

- **Texture variety:** a small set of wall materials chosen per-wall (seeded off the
  level's `maze_seed` so it stays reproducible). Optionally a per-level *theme*
  (`LevelData` could gain a `theme` field selecting a material palette).
- **Decorative objects:** spawn small props against wall faces during build — pick wall
  cells from the grid, place a prop scene flush to the face with outward orientation.
  Density driven by a constant or a `LevelData` field; seeded placement.
- Purely cosmetic — no collision changes, no gameplay effect, no key/door interference.

## Touches

`scenes/levels/level_builder.gd` (wall loop — vary material, spawn props), `materials/`
(new wall variants), new `scenes/props/*.tscn`, `data/levels/level_data.gd` (optional
`theme`). Reuses the existing `MazeGen` grid + seed for deterministic placement.

## Open questions

- Themed palettes per level, or one shared varied set?
- Prop budget — keep low to avoid the CSG perf concern in
  [05-performance](05-performance.md) (props add nodes too).
