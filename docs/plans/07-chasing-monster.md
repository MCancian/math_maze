# Chasing Monster

**Status:** 🔜 Future

Add a monster that chases the player on more **open** (braided) mazes at harder
difficulty, to give those levels tension that the maze layout alone doesn't.

## Behavior (decided)

- **On catch:** the player must **answer a math question** (reuse the existing
  `math_problem` UI + `GameManager.math`). On a correct answer the monster goes away
  for **2 minutes**, then **respawns far from the player** (farthest reachable cell via
  `MazeGen` `dist`/BFS). Catch is *not* a loss — it's an interruption + a math beat.

## Design to settle

- **Gating:** spawn only when the level is open enough — e.g. `MazeConfig.braid_factor`
  above a threshold and/or `maze_hard`, or an explicit `LevelData.has_monster` flag.
  (Easy/tutorial levels never spawn it.)
- **Movement:** `NavigationAgent3D` over a baked nav mesh vs. a simple grid BFS pursuit
  toward the player's cell. Grid pursuit is lighter and fits the existing cell model.
- **Speed:** slightly slower than the player so it's escapable; tune per difficulty.
- **Wrong answer on catch:** retry, re-catch immediately, or a small penalty? (open)
- Surface state on the HUD (monster active / cooldown timer).

## Touches

New `scenes/actors/monster.tscn/.gd`, spawned by `level_builder.gd` /
`level_generated.gd` when gated on; `scenes/ui/math_problem.gd` (reused for the catch
prompt); `scenes/levels/maze_gen.gd` (`dist` for far-respawn); `scenes/ui/hud.gd`
(monster/cooldown indicator); `data/maze/maze_config.gd` or `level_data.gd` (gating).

## Relation to other plans

Pairs with [04-lose-conditions](04-lose-conditions.md) but is **independent** — catch is
a math interrupt, not a lose trigger. Heavier on open mazes, which interacts with
[05-performance](05-performance.md).
