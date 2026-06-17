# Door Wall Placement

**Status:** 🔜 Future (bug fix)

On generated levels past the tutorial the exit door appears free-standing in the middle
of an open area instead of set into a wall, so it doesn't read as "the way out." Cause:
`MazeGen` picks the exit as the BFS-farthest cell, which on braided/open mazes is often
an interior cell with no adjacent wall.

## Fix (decided)

Force the **exit cell onto the maze perimeter** so the door sits flush in an **outer
wall**:

- In `MazeGen.generate`, restrict exit selection to **boundary cells** and pick the
  farthest such cell from the entrance (still using the `dist` map for "farthest").
- In `LevelBuilder.build`, place + orient the door in the outer wall face of that
  perimeter cell (open the wall segment there), facing outward.
- Verify the door's trigger + barrier shapes (the polish-pass two-shape setup) still
  line up against an outer wall, not a free corridor.

## Touches

`scenes/levels/maze_gen.gd` (boundary-constrained exit selection),
`scenes/levels/level_builder.gd` (door placement/orientation in the outer wall),
`scenes/actors/door.tscn` (confirm hitbox vs. wall).

## Validation

Headless: assert the exit cell is on the boundary for every `gen_*` seed and that the
maze stays fully connected; spot-check the door visually for a few levels. Keep the
hand-built tutorial (`level_01`) unaffected.
