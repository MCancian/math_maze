# Docs

Technical reference for `math_maze`, aimed at agent legibility. Docs are **brief and
point to code** — read the named symbol for exact signatures. If prose reproduces a
signature, it's stale; fix or delete it.

## Technical reference (`docs/technical/`)

| Doc | Covers |
| --- | --- |
| [scene-flow.md](technical/scene-flow.md) | Autoload spine, run state, menu→level→win/lose transitions |
| [save-format.md](technical/save-format.md) | `user://save.json`, 3-slot profiles, unlocks, stars |
| [maze-gen.md](technical/maze-gen.md) | Seeded maze generation + level building (hybrid data) |
| [difficulty.md](technical/difficulty.md) | Independent math + maze difficulty configs |
| [testing.md](technical/testing.md) | Headless test suite and test locations |

## Other

- [../DESIGN.md](../DESIGN.md) — high-level architecture & locked decisions.
- [plans/README.md](plans/README.md) — numbered plan backlog (source-of-truth table).
- [../AGENTS.md](../AGENTS.md) — agent workflow, testing, conventions.
