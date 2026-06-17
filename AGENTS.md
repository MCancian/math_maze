# Repo

`math_maze` is a **Godot 4.6 first-person 3D math maze for grade-school kids**: the
player walks a maze, touches a glowing orb, solves an arithmetic problem to earn a
key, collects the required keys, and opens the exit door to win. Levels are a
**hybrid** of procedurally generated mazes (seeded, reproducible) and optional
hand-placed set-pieces.

**Design spine:** autoloads are the backbone — `GameManager` owns run state and all
scene transitions, `SaveManager` owns persistence. *Everything routes through the
autoloads; actors and screens never call each other or change scenes directly.* When
adding a feature, prefer a signal on `GameManager` over a direct node reference.

# Agent Guidelines (style)

You terse like caveman. Technical substance exact. Only fluff die. Drop: articles,
filler (just/really/basically), pleasantries, hedging. Fragments OK. Pattern: [thing]
[action] [reason]. [next step]. **Exception:** does not apply to prose under `docs/`
or in plan files — documentation should read as normal English.

# Git Workflow

Solo repo, remote `https://github.com/MCancian/math_maze.git`. History stays **lean
and linear**.

- **Commit directly to `main`** for normal work. Branch only for large/risky/parallel
  work; integrate with `--ff-only` / rebase / `--squash`. **Never `--no-ff`.**
- One commit per logical change; squash WIP noise before it lands.
- **Done = committed AND pushed.** `git push origin main` must land and `git status`
  report up to date.
- **`.tscn` gotcha:** scenes use **path-based** `ext_resource` (no uid headers, to
  match existing style). Moving or renaming any `res://` file means **hand-rewriting
  the referencing paths** — git won't catch a dangling path, but a headless boot will.

# Testing & Verification (headless Godot)

Binary: `~/.local/bin/godot` (4.6.3). Always verify headless before calling work done.

```
# Register class_name scripts + import (run ONCE after adding/renaming a class_name script)
~/.local/bin/godot --headless --editor --quit --path .
# Clean-boot check — expect exit 0, no parse/script errors
~/.local/bin/godot --headless --path .
```

- **GOTCHA — global classes:** a new `class_name` script must be registered via the
  `--editor --quit` import above, or normal boot fails *"Could not find type X"* and
  autoloads fail to instantiate.
- **GOTCHA — `-s` script mode:** `godot --headless -s res://foo.gd` (SceneTree mode)
  does **not** load global classes **or register autoload singletons**. Scripts that
  reference `GameManager`/`SaveManager`/`class_name` types fail with *"Identifier not
  found"* even though they work in a real boot — these are **false negatives**.
  - Unit-test pure scripts (e.g. `SaveManager`, `LevelData`) with `load("res://…").new()`
    + duck typing, never `class_name` refs.
  - Validate that autoload-using scenes *compile* via the `--editor --quit` import
    (full global context), not via `-s` scene instancing.

# Think Before Coding

State assumptions; ask if uncertain — don't silently pick between interpretations.
Name what's unclear. Push back when warranted.

# Simplicity & Surgical Changes

Solve the problem; nothing speculative. Touch only what's requested. Remove orphans
*your* change creates; leave pre-existing dead code. Convert "fix bug" into a
verifiable goal (a failing headless check, then make it pass).

# Runtime layout

Single repo, no external services. Run from repo root: `~/.local/bin/godot --path .`.
Boot scene = `scenes/ui/main_menu.tscn` (set in `project.godot`). Folder layout:
`autoload/` · `scenes/{ui,levels,actors}/` · `scripts/` · `data/{levels,math,maze}/`
· `materials/` · `tools/` (dev-only scripts, not shipped).

# Task Guide (where to look)

| Goal | Doc | Primary code |
| :--- | :--- | :--- |
| Architecture / growth direction | [DESIGN.md](DESIGN.md) | `autoload/game_manager.gd` |
| Scene flow & run state (menu→level→win/lose) | [docs/technical/scene-flow.md](docs/technical/scene-flow.md) | `autoload/game_manager.gd` (`start_level`/`win`/`next_level`/`goto_*`) |
| Save, profiles, unlocks, stars | [docs/technical/save-format.md](docs/technical/save-format.md) | `autoload/save_manager.gd`, `LevelData.stars_for` |
| Maze generation & building | [docs/technical/maze-gen.md](docs/technical/maze-gen.md) | `scenes/levels/maze_gen.gd`, `level_builder.gd`, `level_generated.gd` |
| Levels (hybrid data) | [docs/technical/maze-gen.md](docs/technical/maze-gen.md) | `data/levels/*.tres`, `data/levels/level_data.gd` |
| Difficulty configs (math + maze) | [docs/technical/difficulty.md](docs/technical/difficulty.md) | `data/math/`, `data/maze/`, `GameManager.MATH_CONFIGS`/`MAZE_CONFIGS` |
| Plan / track next features | [docs/plans/README.md](docs/plans/README.md) | — |

Docs are brief and **point to code** — read the symbol for signatures. If prose
reproduces a signature, treat it as stale and fix or delete it.

# Documentation Structure

`docs/` is a wiki-linked technical reference; keep docs short, machine-readable, and
cross-linked with relative links. Start from [docs/README.md](docs/README.md).
`docs/technical/` holds code-facing writeups; `docs/plans/` tracks future work;
`DESIGN.md` (repo root) is the high-level architecture.

# Plan lifecycle

`docs/plans/` is the design backlog. Keep it tidy:

- **Numbered files**: `NN-name.md`. Next id = highest existing + 1; reserve the
  table row before writing the file.
- **Status vocabulary**, one of: `🔜 Future` → `🚧 In progress` → `✅ Implemented`.
  The table in [docs/plans/README.md](docs/plans/README.md) is the **source of
  truth**; each plan file's `**Status:**` header must match its row.
- The table is split into **Active** and **Shipped** — move a row between them when
  status changes so the active list stays short.
- **On ship:** set `✅ Implemented` (+ date) and record what shipped + the code
  symbol it produced, so the plan stays a useful record of the code.
- Don't relocate shipped plan files — they're cross-linked. Only archive a file when
  it's superseded, leaving a one-line tombstone pointing to its replacement.
