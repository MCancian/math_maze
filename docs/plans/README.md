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

## Shipped

| # | Plan | Status | Summary |
| --- | --- | --- | --- |
| 01 | [foundation](01-foundation.md) | ✅ Implemented | Reorg, autoloads, screen flow, math/maze configs, procedural generation, door/trail polish |
| 02 | [more-levels](02-more-levels.md) | ✅ Implemented | Multiple generated levels (seed-varied) with progression |
| 03 | [save-and-progression](03-save-and-progression.md) | ✅ Implemented | 3-slot profiles, SaveManager, Level Select; persist unlocks + per-level best time/stars |

See also the high-level architecture in [`../../DESIGN.md`](../../DESIGN.md) and the
agent orientation in [`../../AGENTS.md`](../../AGENTS.md).
