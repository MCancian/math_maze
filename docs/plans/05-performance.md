# Maze Geometry Performance

**Status:** 🔜 Future

`LevelBuilder` spawns one `CSGBox3D` per wall cell. Fine at current sizes; a
large maze (`maze_size` cranked up) produces hundreds of CSG nodes, which is
heavy to build and render.

## Options

- **GridMap** with a wall MeshLibrary — one node, batched rendering.
- **Single merged ArrayMesh** built from the wall grid (greedy meshing to merge
  runs of adjacent walls into larger boxes).
- **MultiMeshInstance3D** for identical wall blocks + one collision body.

## Trigger to do this

Only when a difficulty/level actually needs bigger mazes and the CSG approach
shows up as a build hitch or frame cost. Until then, not worth the complexity.
