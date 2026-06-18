# Chasing Monster

**Status:** ✅ Implemented (2026-06-17)

Add a monster that chases the player on more **open** (braided) mazes at harder
difficulty, to give those levels tension that the maze layout alone doesn't.

## Shipped

- `scenes/actors/monster.tscn` / `monster.gd`: Quaternius slime chaser that follows
  the player with grid BFS over `MazeGen.links`.
- Catch opens the existing `scenes/ui/math_problem.tscn` prompt. Correct answers hide
  the monster for `MazeConfig.monster_cooldown_seconds` (120 seconds on Medium/Hard),
  then it respawns at the farthest reachable cell from the player.
- Wrong catch answers call `GameManager.lose_key()`; key count clamps at zero and the
  prompt stays open until the player answers correctly.
- `MazeConfig` owns default gating and tuning (`monster_enabled`,
  `monster_braid_threshold`, `monster_speed`, `monster_cooldown_seconds`,
  `monster_bee_visual`, `monster_scary_visual`, `monster_sound_enabled`).
- `LevelData.monster_spawn` can force the monster on or off per level; `Default` uses
  `MazeConfig.allows_monster()`.
- HUD now shows monster active/cooldown state through `GameManager.monster_state_changed`.

## Asset

- Downloaded source pack: `tools/downloads/quaternius/Animated_Monster_Pack_by_Quaternius.zip`.
- Runtime assets used:
  - `assets/monsters/quaternius_slime/slime.obj` + `Slime.mtl`.
  - `assets/monsters/quaternius_bee/bee_enemy.glb` for Easy's friendly bee monster.
- Licenses:
  - `assets/monsters/quaternius_slime/LICENSE.txt` (`CC0 1.0 Universal`).
  - `assets/monsters/quaternius_bee/LICENSE.txt` (`CC0 1.0 Universal`).
- The monster pack contains Bat, Dragon, Skeleton, and Slime in Blend/FBX/OBJ. Slime was
  selected because OBJ imports cleanly and reads as kid-friendly rather than scary.
- Extra asset stash to review later: https://drive.google.com/drive/folders/18m4KpzpEzhC9wl7jzr6dUc0N8Jozr79C

## Decisions recorded

- **Gating:** both gates — Easy/Medium/Hard default on by maze difficulty/braid
  threshold, with per-level override.
- **Movement:** grid BFS pursuit, not `NavigationAgent3D`.
- **Speed:** slower than the player; Easy uses `2.2`, Medium uses `3.0`, Hard uses
  `4.2`, player uses `5.0`.
- **Presentation:** Easy uses a friendly Quaternius bee with no sound; Medium keeps the
  Quaternius slime and no sound; Hard uses shadow body, red emissive eyes, and
  procedural proximity rumble.
- **Wrong answer:** lose one collected key, clamped at zero.
- **HUD:** active/cooldown indicator visible under the key count.

## Relation to other plans

Pairs with [04-lose-conditions](04-lose-conditions.md) but is **independent** — catch is
a math interrupt, not a lose trigger. Heavier on open mazes, which interacts with
[05-performance](05-performance.md).
