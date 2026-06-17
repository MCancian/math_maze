# Map Overlay (press M)

**Status:** 🔜 Future

Let the player press **M** to see a map of the maze. Reveal is **explored-only (fog of
war)** — only corridors actually visited are drawn — so it aids navigation without
removing the challenge of finding the way.

## Approach

- **Track visited cells:** as the player moves, mark their current maze cell visited
  (reuse the cell↔world mapping in `level_builder.gd`; the player already drops trail
  crumbs every `TRAIL_STEP`, a natural hook). Store the visited set on the level root or
  `GameManager`.
- **Render:** a 2D overlay (CanvasLayer/Control) drawn from the `MazeGen` grid, showing
  only visited cells + the player's position/heading. Door and keys appear only once
  their cell has been visited (consistent with fog of war).
- **Input:** `M` toggles the overlay; pause optional (likely just an overlay, movement
  continues — decide during build). Add the `map_toggle` action to the input map.

## Touches

`scenes/actors/player.gd` (mark visited on move), `scenes/levels/maze_gen.gd` +
`level_builder.gd` (grid + cell mapping for drawing), new map Control (under
`scenes/ui/`), `scenes/ui/hud.gd` (toggle wiring), `project.godot` (input action).

## Open questions

- Overlay pause vs. live (monster from [07-chasing-monster](07-chasing-monster.md) makes
  a full pause attractive).
- Full-screen map vs. corner minimap (or M = fullscreen, always-on minimap later).
