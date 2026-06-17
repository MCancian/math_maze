# More Levels

**Status:** ✅ Implemented (2026-06-16)

The game shipped with a single generated level (one fixed seed). Add a sequence
of generated levels so there's progression.

## Approach

- Each level is a `LevelData` `.tres` with a distinct `maze_seed`, no `scene`
  (so it routes through the generator).
- Maze *shape* varies per level (seed); maze *size/braid/keys* still come from
  the player-chosen `MazeConfig`, so the chosen difficulty applies to the whole
  run while each level feels fresh.
- `GameManager.LEVELS` lists them in order; `next_level()` walks the list and
  the Win screen's "Next Level" button advances until the last one.

## Shipped

- `data/levels/gen_01.tres … gen_05.tres` — seeds 1337 / 4242 / 9001 / 271828 /
  161803, display names "Level 1"…"Level 5".
- `GameManager`: `LEVELS = [GEN_01 … GEN_05]`, `FIRST_LEVEL = GEN_01`. Defaults,
  `current_level`, and Difficulty Select all start at `FIRST_LEVEL`.
- Removed the old single `level_02.tres`. Hand-built `level_01.tres` stays as
  `TEST_LEVEL` (dev only).

## Future tweaks

- Could scale `maze_size`/`braid` upward across levels for built-in ramp,
  independent of the player's difficulty pick — deferred (would interact with
  the difficulty choice; revisit with [save-and-progression](03-save-and-progression.md)).
