# Save & Progression

**Status:** ✅ Implemented (2026-06-16)

Persist player progress as named profiles and surface it through New Game / Continue
and a Level Select screen.

## What shipped

- **3 save profiles** in `user://save.json`. Each profile stores: `name`, chosen `math`
  + `maze` config paths, `unlocked` (highest level reached), `current` (level to
  resume), `total_stars`, and a per-level `best` record `{level_id: {time, stars}}`.
- **Records keyed per level** (not per level × maze difficulty).
- **Stars (1–3)** awarded by finish time vs `LevelData.star_thresholds`
  (`< t[0]` → 3★, `< t[1]` → 2★, else 1★; default `[30, 60]` seconds). `total_stars`
  accumulates the best stars across levels — reserved for a future spend/upgrade system.
- **Real run timer**: `GameManager.start_run_timer()` is called when a level scene is
  ready; `win()` computes `elapsed_time` and records the result, then unlocks the next
  level by `unlock_order`.
- **Main menu**: New Game · Continue (disabled when no profiles) · Quit.

## Flow

```
MainMenu ─New Game→ NewGame(name + slot) → DifficultySelect → LevelSelect → Loading → Level → Win
        └Continue→ ProfileSelect → resume_active() ───────────────────────→ Loading → Level → Win
```

- **New Game**: name a profile into one of 3 slots, choose math + maze difficulty
  (saved to the profile), then pick from unlocked levels (a fresh profile has only
  Level 1).
- **Continue**: pick a saved profile → jump straight into its `current` level with its
  saved difficulty.
- **Win** records best time + stars, unlocks the next level, saves. The "Next Level"
  button still walks `GameManager.LEVELS` as before.

## Files

- `autoload/save_manager.gd` — profiles, load/save JSON, `new_profile`,
  `record_result`, `unlock`, `is_unlocked`, intent-named profile mutators/readers,
  `set_active`, `any_profiles`.
- `autoload/game_manager.gd` — run timer, `win()` recording + unlock, `start_level`
  asks SaveManager to update `current`, `resume_active()`, canonical difficulty config
  lists, new scene routes (`goto_new_game`/`goto_profile_select`/`goto_level_select`).
- `data/levels/level_data.gd` — `star_thresholds` export + `stars_for(elapsed)`.
- `scenes/levels/level_generated.gd`, `level_root.gd` — call `start_run_timer()`.
- `scenes/ui/main_menu.{tscn,gd}` (edited), `difficulty_select.{tscn,gd}` (edited,
  Start→Next routes to Level Select), and new `new_game`, `profile_select`,
  `level_select` `.tscn/.gd`.

## Deferred

- No path to replay an earlier unlocked level once a profile exists (Continue jumps
  straight in; Level Select only appears in the New Game flow). Future: reach Level
  Select from a pause/menu.
- **Star spending / upgrades**: data is tracked; spending UI is future. Add spending
  state deliberately when that feature lands; there is no placeholder score variable.
- Star thresholds are per-level defaults `[30, 60]`; tune with real play data (maze
  difficulty affects times, but records stay per-level by decision).
