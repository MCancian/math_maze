# Monster visuals by name

**Status:** ✅ Implemented (2026-09-06)

Monster looks were selected by two mutually-exclusive booleans on `MazeConfig`
(`monster_bee_visual`, `monster_scary_visual`) with all three models baked as sibling
nodes in `monster.tscn` and toggled by `visible`. A fourth creature would have meant a
fourth boolean, a fourth `and not ...` clause, and more geometry in a scene that was
already 170 lines.

## Shipped

- `MazeConfig.monster_visual: StringName` replaces both booleans;
  `MazeConfig.DEFAULT_VISUAL` is `&"slime"`.
- One scene per creature in `scenes/actors/visuals/`: `slime`, `bee`, `shadow`, `cat`.
  `monster.gd` `_apply_visual_style()` instantiates `visuals/<name>.tscn` under
  `$Visual`, warning and falling back to the default if the name is unknown.
  `monster.tscn` is down to the Area3D, its collision shape, `Visual`, and `HardSound`.
- A visual scene may define `animate(delta, moving)` to drive its own idle motion;
  `monster.gd` `_animate_visual` falls back to the previous shared bob when it does
  not. `bee.gd` hovers and flaps while chasing; `cat.gd` stays grounded, trots its
  legs in diagonal pairs, and sways its tail and head.
- Easy uses the new cat (`maze_easy.tres`), Hard uses `&"shadow"`. The bee scene is
  intact and selectable but no config currently names it.
- The cat is built from primitives like the bee's `FriendlyOverlay`, so it adds no
  asset and no licensing.

## Decisions recorded

- **Name over booleans:** adding a creature is one scene plus one string in a `.tres`,
  with no code change — the same shape as the other `MazeConfig` knobs.
- **Per-scene animation:** the one hardcoded bob in `_move_toward_player` suited a
  flying bee and nothing else. Ownership of the motion moved to the creature.

## Follow-ups

- Per-level visual override (`LevelData`) so one difficulty can mix creatures.
- Swap the procedural cat for a rigged model (Quaternius CC0 animals) if animation
  quality matters more than repo size.
