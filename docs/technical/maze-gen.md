# Maze generation & level building

Levels are a **hybrid**: a `LevelData` resource either points at a hand-built `scene`
or (when `scene` is null) is generated at runtime from `maze_seed` + the active
`MazeConfig`.

## Data — `LevelData` (`data/levels/level_data.gd`, `data/levels/*.tres`)

`id`, `display_name`, `unlock_order`, `scene` (null = generated), `maze_seed` (fixed →
reproducible), `set_piece` (optional hand-placed overlay), `star_thresholds` +
`stars_for(elapsed)`. Progression list is `GameManager.LEVELS` (gen_01…gen_05).

## Generation — `MazeGen` (`scenes/levels/maze_gen.gd`)

`MazeGen.generate(n, seed_val, braid=0.0) -> Dictionary`. Seeded recursive-backtracker →
**perfect** maze (single solution); `braid` opens a fraction of dead-ends into loops for
multiple routes. Returns `grid` (1=wall/0=passage, size `(2n+1)²`), `w`/`h`/`n`,
`entrance`, `exit` (BFS-farthest), `deadends`, and `dist` (distance-from-entrance map).

## Building — `LevelBuilder` (`scenes/levels/level_builder.gd`)

`LevelBuilder.build(root, info, maze_cfg, set_piece) -> int` (keys placed). Spawns
CSGBox floor + walls (`CELL=4`, `WALL_H=3`), door at the exit, keys at the farthest
dead-ends (falls back to farthest cells when braiding leaves too few), optional
`set_piece` overlay, player at the entrance (added last so the HUD reads the final count).

## Wiring — `level_generated.gd`

`_ready()`: `n = maze_cfg.maze_size + 3` → `MazeGen.generate` → `LevelBuilder.build` →
`GameManager.reset_run(placed)` → `GameManager.start_run_timer()`. Same seed + config →
identical maze every play (pairs with per-level best times).

> CSGBox-per-wall may be slow at large `maze_size` — see
> [05-performance](../plans/05-performance.md).
