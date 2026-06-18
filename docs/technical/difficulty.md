# Difficulty configs

Math difficulty and maze difficulty are **two independent axes**, chosen separately on
the Difficulty Select screen and held on `GameManager.math` / `GameManager.maze`.

## Math — `MathConfig` (`data/math/math_config.gd`, `data/math/*.tres`)

Controls only the arithmetic. `enum Mode { ADD, MUL, FRACTION_OF }`, `max_digit`,
`fraction_denoms`. `make_problem() -> {"text", "answer"}` — answer is always a whole
number. Read by `scenes/ui/math_problem.gd` via `GameManager.math`.

Configs: `addition.tres` (ADD), `multiplication.tres` (MUL), `fractions.tres`
("n/d of W", denoms 2–4).

## Maze — `MazeConfig` (`data/maze/maze_config.gd`, `data/maze/*.tres`)

Controls only the maze. `maze_size` (cells per side → grid `2*(size+3)+1`),
`braid_factor` (0 = perfect maze, higher = more loops), `keys_required`, plus monster
spawn/tuning fields (`monster_enabled`, `monster_braid_threshold`, `monster_speed`,
`monster_cooldown_seconds`, `monster_bee_visual`, `monster_scary_visual`,
`monster_sound_enabled`). Read by `LevelBuilder` + `level_generated.gd` via
`GameManager.maze`.

Configs: `maze_easy` (size1 → 4×4 cells, braid0, keys1, slow friendly bee monster, no
sound), `maze_medium` (size4 → 7×7 cells, braid0.5, keys2, monster enabled above
braid0.45, slime visual, no sound), `maze_hard` (size6 → 9×9 cells, braid0.7, keys3,
monster enabled above braid0.65, faster animated horror visual, procedural rumble
sound).

## Registration

Canonical lists live on `GameManager`: `MATH_CONFIGS` / `MAZE_CONFIGS` (and
`DEFAULT_MATH` / `DEFAULT_MAZE`). The Difficulty Select buttons index into these, so a
new config is added in one place. See [maze-gen.md](maze-gen.md) for how `MazeConfig`
feeds generation.
