# Plans Index

Each plan is a numbered markdown file in this directory describing one initiative.
**This table is the source of truth** — each plan file's `**Status:**` header must
match its row here. Keep the Active list short; move a row to Shipped when it lands.

**Legend:** 🔜 Future · 🚧 In progress · ✅ Implemented

**Next plan id** = highest existing + 1 (reserve the row before writing the file).

## Active

| # | Plan | Status | Summary |
| --- | --- | --- | --- |
| 04 | [lose-conditions](04-lose-conditions.md) | 🔜 Future | Timer / lives and a real Lose trigger |
| 05 | [performance](05-performance.md) | 🔜 Future | Merge wall geometry (GridMap / single mesh) for large mazes |
| 06 | [wall-textures-and-objects](06-wall-textures-and-objects.md) | 🔜 Future | Varied wall textures + decorative props on generated mazes |
| 07 | [chasing-monster](07-chasing-monster.md) | 🔜 Future | Monster on open/hard mazes; catch = math question, then far respawn |
| 08 | [map-overlay](08-map-overlay.md) | 🔜 Future | Press-M fog-of-war map (explored cells only) |
| 09 | [door-wall-placement](09-door-wall-placement.md) | 🔜 Future | Fix: put the exit door on the perimeter, flush in an outer wall |
| 10 | [bonus-problems-and-coins](10-bonus-problems-and-coins.md) | 🔜 Future | Scattered bonus word problems award a separate coins currency |

## Shipped

| # | Plan | Status | Summary |
| --- | --- | --- | --- |
| 01 | [foundation](01-foundation.md) | ✅ Implemented | Reorg, autoloads, screen flow, math/maze configs, procedural generation, door/trail polish |
| 02 | [more-levels](02-more-levels.md) | ✅ Implemented | Multiple generated levels (seed-varied) with progression |
| 03 | [save-and-progression](03-save-and-progression.md) | ✅ Implemented | 3-slot profiles, SaveManager, Level Select; persist unlocks + per-level best time/stars |

See also the high-level architecture in [`../../DESIGN.md`](../../DESIGN.md) and the
agent orientation in [`../../AGENTS.md`](../../AGENTS.md).
