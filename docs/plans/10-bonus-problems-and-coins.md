# Bonus Problems & Coins

**Status:** 🔜 Future

Scatter optional **bonus word problems** around the maze. Solving one awards **coins** —
a new currency **separate from stars** — to seed a future shop / upgrades economy
(stars track level mastery; coins are spendable).

## Approach

- **Bonus pickups:** placed at maze cells not used by required keys/door/entrance
  (e.g. some dead-ends or off-path cells from `MazeGen` `deadends`/`dist`), seeded for
  reproducibility. Optional — they don't count toward `keys_required`.
- **Word problems:** a word-problem variant of the math generator (a `MathConfig` mode
  or a sibling generator) producing short story problems with whole-number answers.
- **Reward:** correct answer → coins (amount per problem, maybe scaled by difficulty);
  wrong answer → no coins, pickup consumed or retryable (decide on build).
- **Persist coins** on the profile via `SaveManager` (new `coins` field + a
  `add_coins(n)` mutator, parallel to stars/`total_stars`). Show a coin counter on the
  HUD.

## Touches

New `scenes/actors/bonus_problem.tscn/.gd` (placed by `level_builder.gd`), word-problem
generation in `data/math/math_config.gd` (or a new config), `autoload/save_manager.gd`
(`coins` + `add_coins`), `scenes/ui/hud.gd` (coin counter), reuse `math_problem` UI.

## Open questions

- Word problems as a `MathConfig.Mode` vs. a separate generator (they're bonus content,
  not the level's chosen math difficulty).
- Coins per problem / difficulty scaling; pickup respawn on replay.
- Ties into the deferred **star/coin spend system** noted in
  [03-save-and-progression](03-save-and-progression.md) — coins are the spendable half.
