---
name: mm-change-control
description: How changes are classified, gated, reviewed and merged in math_maze; what counts as a Contract change; non-negotiables. Read before any code, data or doc change.
---

# Change control

Class chooses gate + review route. Classify per commit BEFORE writing, by runtime **effect** — not
by which file, not by whether the code is new. A new field on the save file is Contract, not
Additive; a change to how the maze is carved that leaves the same seed producing a different
layout is Behavioral AND breaks the fixed-layout promise (`design/levels-and-progression.md`).
Unsure → higher. A class written in an issue or brief is a GUESS: re-derive from the code.

## Classes

| Class | Effect (examples) | Gate | Reviews |
|---|---|---|---|
| **Docs-only** / `quick` | no runtime change: `design/`, `*.md`, `.claude/`, comments; one small mechanical PR | gate green; review own diff | 0 — merge (PR label `docs-only` / `quick`) |
| **Additive** | new code paths only; nothing existing rewired (new scene, visual, SFX, test, tool script, HUD label) | gate green + a new test in `_tests()` covering the addition | light pair |
| **Behavioral** | observable play changes; stored formats do not (tuning numbers, a prompt's wording, monster speed, lighting, a tune) | gate green + a targeted test proving the intended change | light pair |
| **Contract** | anything a stored file or another script depends on: the **save-file shape** (`SaveManager` keys), a **`.tres` schema** (`MazeConfig` / `MathConfig` / `LevelData` exports), **`project.godot`** autoloads or input map, a signal signature on `GameManager` | gate green + back-compat evidence (a save written BEFORE the change still loads, shown in the PR body) + grep for every consumer of the changed surface | light pair; the PR body SUGGESTS `risk-bearing` — **only USER applies it** (four risk roles + stage-2 MERGE) |

Gate = `rtk proxy tools/gate.sh` (`AGENTS.md` § Testing). The route binds to the PR's LABELS, so
the class goes in the PR body and, when it is Contract, a one-line suggestion USER can act on.

## Non-negotiables

1. **Everything routes through the autoloads.** Actors and screens never change scenes or call
   each other; a new cross-cutting fact is a signal on `GameManager`.
2. **Save-file shape grows by explicit decision.** New key → default on read for a save that
   lacks it (`load_game` stays tolerant), and every reader named in the same commit.
3. **Save-side files go through `autoload/user_dir.gd`.** A literal `user://` outside it is a
   test that will write the live saves.
4. **Same seed + same maze config = same layout**, every build. A generation change that moves a
   wall is a design decision (`design` label), not a refactor.
5. **Fail loud.** A missing visual, track or config name warns and falls back visibly; it never
   silently spawns nothing.
6. **Every gate must be able to go red.** New test → seen failing once, the `FAIL:` line quoted
   in the commit body.
7. **`.tscn` paths are hand-maintained.** Move or rename a `res://` file → grep every referencing
   `.tscn`/`.gd` in the same commit; the gate's import step is the check.

## Commit & merge policy

- Branch + PR per issue, in a session worktree. Commit each verified unit. Series = record; PR
  body = readout (what, why, class per commit, what NOT verified, back-compat evidence for
  Contract).
- `main` PR-only. Merge after gate green + review coverage with `tools/merge_pr.sh N <sha>`,
  which asks `revue clearance` first. Never merge unreviewed; coverage short → PR stays open,
  tell USER.
- Gate once per pushed tree state; zero edits between the run and the push.
- Fixes append-only, `Review-fix: <what>` on a body line; no history rewrite once a round exists.
- Message `<type>: <what> (#issue)`; harness `Co-Authored-By` trailer.
- Record: the script's header comment (present tense, no dates) for behaviour; `design/<area>.md`
  for what the game must do and why; a USER ruling goes in THE doc of record for that fact
  (`CLAUDE.md` § Loop 9). No second home.
- Surface to USER: design decision (`design` label), gate red after two focused tries, anything
  destructive or irreversible, every Contract change.
