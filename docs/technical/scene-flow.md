# Scene flow & run state

`GameManager` (`autoload/game_manager.gd`) is the spine: it holds run state and is the
**only** place scenes change. Actors and screens call it via methods/signals — they
never change scenes or reference each other directly.

## Flow

```
MainMenu ─New Game→ NewGame(name+slot) → DifficultySelect → LevelSelect → Loading → Level → Win
        └Continue→ ProfileSelect → resume_active() ───────────────────────→ Loading → Level → Win
                                                                              Level → Lose
```

- **`goto_*()`** — direct scene changes (`goto_menu`, `goto_new_game`,
  `goto_profile_select`, `goto_difficulty_select`, `goto_level_select`).
- **`start_level(math, maze, level_data)`** — sets active configs, asks SaveManager to
  record the level as `current`, calls `reset_run`, then routes through the **Loading**
  screen via `pending_scene_path` (hand-built `scene` if present, else `GENERATED_SCENE`).
- **`win()`** — clocks the run (`elapsed_time` from `run_start_ms`), computes stars via
  `current_level.stars_for()`, records the result + unlocks the next level, then changes
  to the Win scene after `WIN_DELAY` (door tween plays).
- **`next_level()` / `has_next_level()`** — walk `GameManager.LEVELS` in order.

## Run state & timing

- `reset_run(required)` zeroes keys/time and emits `keys_changed`. Called tentatively in
  `start_level`, then authoritatively when the level scene is ready (it knows the real
  key count).
- `start_run_timer()` is called from the level root's `_ready`
  (`scenes/levels/level_generated.gd`, `level_root.gd`) so best times are honest.

## Signals

`keys_changed(collected, required)` (HUD listens) · `level_won` · `level_lost`.

See [save-format.md](save-format.md) for what `win()` persists.
