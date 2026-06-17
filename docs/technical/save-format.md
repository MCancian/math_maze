# Save format & profiles

`SaveManager` (`autoload/save_manager.gd`) persists progress to `user://save.json` as up
to **3 profile slots**. It owns the save-file shape — other scripts use the intent-named
helpers, never the raw dict keys.

## File shape

```json
{
  "active": 0,
  "profiles": [
    {
      "name": "Matt",
      "math": "res://data/math/addition.tres",   // chosen MathConfig path
      "maze": "res://data/maze/maze_easy.tres",   // chosen MazeConfig path
      "unlocked": 2,                               // highest unlock_order reached
      "current": 2,                                // level to resume (Continue)
      "total_stars": 5,                            // Σ best stars across levels
      "best": { "gen_01": {"time": 12.3, "stars": 3} }
    },
    null, null                                     // 3 fixed slots; null = empty
  ]
}
```

- Records are **keyed per level** (not per level × maze difficulty).
- `load_game()` is tolerant — missing/corrupt JSON resets to empty slots, no crash.

## API (use these, not the dict)

- Slots: `has_profile(slot)`, `any_profiles()`, `has_active_profile()`, `set_active(slot)`,
  `new_profile(slot, name, math_path, maze_path)`, `profile_summary(slot)`.
- Active reads: `active_math_path(default)`, `active_maze_path(default)`,
  `current_order(default)`, `best_for(level_id)`.
- Mutators (each saves): `set_difficulty(math, maze)`, `set_current(order)`,
  `record_result(level_id, time, stars)` (keeps min time, max stars, recomputes
  `total_stars`), `unlock(order)`, `is_unlocked(order)`.

## Stars

1–3 stars from finish time via `LevelData.stars_for(elapsed)` against
`LevelData.star_thresholds` (default `[30, 60]`s). `total_stars` accumulates the best
stars per level — reserved for a future spend/upgrade system (no placeholder score var).

See [03-save-and-progression](../plans/03-save-and-progression.md) for design history.
