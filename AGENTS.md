# AGENTS.md — math_maze agent guide

`math_maze` = **Godot 4 first-person 3D math maze for grade-school kids**: walk the maze, touch a
glowing orb, solve an arithmetic problem, earn a key, collect the required keys, open the exit door,
win. Levels = seeded procedural mazes (reproducible) plus optional hand-placed set-pieces. Solo
hobby project, one machine, no deployment. USER = non-coding parent-designer; design intent from
USER, code from agents. Workflow (issues, PRs, review, delegation): `CLAUDE.md`.

**Design spine:** autoloads are the backbone — `GameManager` owns run state and every scene
transition, `SaveManager` owns persistence, `AudioManager` owns sound. *Everything routes through
the autoloads; actors and screens never call each other or change scenes directly.* New feature →
a signal on `GameManager` before a direct node reference.

## Style

You terse like caveman. Technical substance exact. Only fluff die. Drop articles, filler
(just/really/basically), pleasantries, hedging. Fragments OK. Pattern: [thing] [action] [reason].
[next step]. **Exception:** `design/` reads as plain English for a non-coding reader — no code
symbols, paths or jargon there.

## Orientation — one home per fact

| Need | Go |
|---|---|
| Open work | GitHub issues (`gh issue list`); campaigns = milestones (`gh api repos/MCancian/math_maze/milestones`) |
| Pre-2026-09-07 plans (01–14) and the old technical notes | `git show plans-v1:docs/plans/<path>`, `git show plans-v1:docs/technical/<path>` (tag) |
| What the game must do, and why | `design/` — requirements, then decisions, per feature area |
| How a subsystem works | the code — start from the Task guide below |
| Change class, gate, commit policy | `.claude/skills/mm-change-control` |
| Review a PR, coverage, caps | `.claude/skills/mm-review`; the tool is `revue`, math_maze's half `.claude/REVIEWERS.md` |
| Brief a subagent | `.claude/skills/mm-delegate` |
| Standing USER rulings | the doc of record for the rule they change (`CLAUDE.md` § Loop 9) |

## Git workflow

- `main` PR-only (`tools/protect_main.sh`). Branch per issue; push branches freely.
- Sync a branch with `git rebase origin/main`, never `git merge origin/main`; check the resolution
  with `tools/rebase_scope_check.sh` (`CLAUDE.md` § Loop 7).
- History **lean and linear**: `tools/merge_pr.sh N <sha>` (a `gh pr merge --rebase
  --delete-branch` pinned to the reviewed sha, after `revue clearance`). Never `--no-ff`, no
  "Merge branch…" commits. One commit per logical change; squash WIP before it lands.
- Done = merged. Local-only commits and ephemeral worktrees evaporate.
- **Work in your own worktree.** `tools/session_worktree.sh <slug>` branches off `origin/main` into
  `../math_maze-wt/<slug>` and leaves `.mm-session` naming the branch; `tools/gate.sh` refuses
  (exit 4) if that tree stops being on it. Plain `git worktree add` stays legal — the marker is
  what matters. The shared checkout (`~/Projects/math_maze`) is for reading, merging, and the
  fresh-clone gate.
- **Shared checkout, several sessions.** HEAD moves under you; a green suite goes red from a
  peer's commit. Gate result changed without your change → `git log --oneline -1` before
  diagnosing. `ListAgents` names live sessions; `SendMessage` reaches them. Never push over an
  inherited red.
- **Subagent worktrees** start at the session's OPENING head, not the tip. First action in any
  worktree: `git log --oneline -1; git merge-base --is-ancestor <expected-tip> HEAD; echo $?`; not
  an ancestor → `git reset --hard <expected-tip>` (tree empty, safe). The orchestrator names the
  expected tip in the brief.

## Testing & verification (headless Godot)

Binary: `~/.local/bin/godot` = the **flatpak**, 4.7.2 (the project declares 4.6 features; it
runs). Always gate before calling work done.

```
rtk proxy tools/gate.sh                 # full: editor import → -s harness → runtime scene, ~2 min
rtk proxy tools/gate.sh _test_music     # one test by name (a key of _tests() in tools/test_*.gd)
```

- The gate runs the editor import first (`--editor --quit`). **GOTCHA — global classes:** a new
  `class_name` script must be registered by that import, or a normal boot fails *"Could not find
  type X"* and autoloads fail to instantiate. The gate does it every run; `SCRIPT ERROR` /
  `Parse Error` during the import = red.
- **GOTCHA — `-s` script mode:** `godot --headless -s res://foo.gd` (SceneTree mode) does **not**
  register autoload singletons. Scripts that reference `GameManager` / `SaveManager` /
  `AudioManager` fail with *"Identifier not found"* even though they work in a real boot — these
  are **false negatives**. Unit-test pure scripts (`SaveManager`, `LevelData`) with
  `load("res://…").new()` + duck typing in `tools/test_save_and_level.gd`; anything needing
  autoloads, scenes, groups or signals goes in `tools/test_runtime.gd` (a scene, full context).
  Validate that autoload-using scenes compile via the import step, never via `-s` instancing.
- **`user://` is isolated by the gate:** it sets `MM_USER_DIR` to a temp dir and
  `autoload/user_dir.gd` routes `save.json` and `settings.cfg` there. `XDG_DATA_HOME` does NOT
  work — the flatpak sandbox overrides it with its own (measured 2026-09-07). A bare `godot` run
  reads and writes the live saves in `~/.var/app/org.godotengine.Godot/data/godot/app_userdata/math_maze/`.
  Any new save-side file goes through `user_dir.gd`; a test that needs a save writes its own.
  The gate's temp dir lives under `~/.cache/math_maze-gate/` (override `MM_GATE_TMP`), not `/tmp`:
  the flatpak's `/tmp` is PRIVATE, so a project or file under it is invisible to godot — a clone
  to gate must sit under `$HOME`.
- **Harness contract:** each test in `_tests()` runs standalone (own setup, no reliance on an
  earlier test); names unique across both harnesses; a failure prints `FAIL: <test>: <message>`
  on stdout (revue's `mutation` seat reads exactly that line); finish line `<harness>: N
  failure(s)`. A run without a finish line, or with a `SCRIPT ERROR`, is red even on exit 0: a
  runtime script error aborts the test function it is in and its remaining checks never run
  (measured 2026-09-07, a false green).
- Capture the exit code; never gate through a pipe (`CLAUDE.md` § Loop 6). Every godot call in
  the gate is bounded by `timeout 300`. A PARSE ERROR in a harness script is the slow red: the
  scene loads without its script, nothing calls quit(), and the timeout is what ends it.
- Red-proof a new test by watching it fail once (`FAIL:` line, `gate: RED`) and quoting that in
  the commit body. There is no redcheck harness here.
- No CI, no pre-push hook: discipline is manual, with three automatic exceptions in
  `tools/gate.sh`. **Exit 3** on a `main` ahead of `origin/main` (`main` is PR-only and
  `gh pr merge` leaves you standing on it); escape `MM_ALLOW_MAIN_COMMITS=1`. **Exit 4** on a
  tree that left its `.mm-session` branch. **Exit 5** on a branch carrying 8+ SCOPE commits since
  its merge-base with `origin/main`, warning at 6 (`CLAUDE.md` § Work unit); a `Review-fix:`
  trailer exempts a commit; escape `MM_ALLOW_LONG_BRANCH=1`. All silent on a detached HEAD.
- Round dirs are reaped by `revue reap`, not automatically; run it when a PR merges.
- Comments citing `file:NNNN` in their OWN file rot on the next edit. Name the symbol, not the line.

## Think before coding

State assumptions; ask if uncertain — don't silently pick between interpretations. Name what's
unclear. Push back when warranted. Convert tasks to verifiable goals: "fix bug" → a failing test
first.

## Simplicity & surgical changes

Solve the problem; nothing speculative. Touch only what's requested; remove orphans *your* change
creates; leave pre-existing dead code.

## Runtime layout

Single repo, no external services. Run from repo root: `~/.local/bin/godot --path .`. Boot scene
= `scenes/ui/main_menu.tscn` (set in `project.godot`). Folder layout: `autoload/` ·
`scenes/{ui,levels,actors,actors/visuals}/` · `data/{levels,math,maze}/` · `materials/` ·
`textures/` · `assets/` · `design/` (requirements, plain English) · `tools/` (dev-only scripts and
the test harnesses, not shipped). `mcp_interaction_server.gd` at the root is a dev-harness
autoload, not game logic.

## Task guide

| Goal | Primary code |
| :--- | :--- |
| Scene flow & run state (menu→level→win/lose), music per screen | `autoload/game_manager.gd` (`start_level` / `win` / `lose` / `next_level` / `goto_*`) |
| Save, profiles, unlocks, stars; where the files live | `autoload/save_manager.gd`, `autoload/user_dir.gd`, `LevelData.stars_for` |
| Sound effects, music, mute | `autoload/audio_manager.gd` |
| Maze generation & building | `scenes/levels/maze_gen.gd`, `level_builder.gd`, `level_generated.gd` |
| Levels (hybrid data) | `data/levels/*.tres`, `data/levels/level_data.gd` |
| Difficulty configs (math + maze) | `data/math/`, `data/maze/`, `GameManager.MATH_CONFIGS` / `MAZE_CONFIGS` |
| Monster, visuals by name | `scenes/actors/monster.gd`, `scenes/actors/visuals/<name>.tscn` |
| Player, flashlight, breadcrumb trail | `scenes/actors/player.gd` |
| Math prompt, problem generation | `scenes/ui/math_problem.gd`, `data/math/math_config.gd` |
| Tests | `tools/test_runtime.gd`, `tools/test_save_and_level.gd` |

Read the symbol for signatures. Prose reproducing one is stale: fix or delete.
