# Foundation

**Status:** ✅ Implemented (2026-06-15 → 2026-06-16)

The structural groundwork the rest of the game builds on. Full architecture
lives in [`../../DESIGN.md`](../../DESIGN.md); this is the shipped summary.

## What shipped

- **Folder reorg:** `autoload/ scenes/{actors,ui,levels} data/{math,maze,levels} materials/ textures/ tools/`.
- **Autoloads:** `GameManager` (run state + scene flow), `SaveManager` (stub), `AudioManager` (stub). Dev-only `McpInteractionServer` still autoloaded.
- **Screen flow:** Main Menu → Difficulty Select → Loading (threaded) → Level → Win / Lose. `GameManager` owns the transitions; actors talk to it via signals (`keys_changed`, `level_won`, `level_lost`).
- **Independent difficulty configs:**
  - `MathConfig` (`data/math/`): Addition, Multiplication, Fractions ("n/d of W"). Whole-number answers.
  - `MazeConfig` (`data/maze/`): `maze_size`, `braid_factor`, `keys_required`. Easy / Medium / Hard.
  - Chosen separately on the difficulty screen.
- **Procedural generation:** `MazeGen` (seeded recursive backtracker, optional braiding for loops) + `LevelBuilder` (CSG floor/walls, door at the farthest cell, keys at far spots, player at entrance). Generated levels are reproducible per seed.
- **Polish:** reliable door trigger (separate trigger/barrier shapes), textured door, breadcrumb floor trail.

## Key decisions / gotchas

- Scenes use path-based `ext_resource` (no UID) — moving files means rewriting `res://` paths by hand. Not a git repo.
- New `class_name` scripts need one `godot --headless --editor --quit` pass to register in the global class cache before a normal boot resolves them.
