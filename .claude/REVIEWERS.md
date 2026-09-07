# Reviewers — math_maze's use of `revue`

Independent model seats examine the PR after gate green; USER cannot judge code. The review tool is
**`revue`** (MCancian/revue): two stages, one ROLE per reviewer, a per-review roster that says
which model fills which role and can be edited mid-flight.

**Doc of record for what revue DOES: `revue --help`, `revue VERB --help`, and revue's README.**
Not this file. This file is math_maze's half: the route, the config, the disposition rule, the
caps. When the two disagree, revue wins — it is the code.

## Two stages, and which PRs get them

**Stage 1** — one seat per derived role, in parallel where the backend allows. Roles are DERIVED
from the PR's labels (`revue plan`); `revue coverage --pr N` says whether every derived role is
covered AT THE CURRENT HEAD, and exits 1 naming the gap. A role is covered by a
`verdict=substantive` return at the head; execution roles also need `restored=yes`, matching tree
hashes and an `exit`, and `mutation` needs a `failing-test` (the harness's `FAIL: <test>:` line).
A force-push voids coverage by construction.

**USER ruling 2026-09-07 — every PR takes the LIGHT route, `independent-derivation` +
`reproduction`, and merges on clean stage-1 coverage. Stage 2 runs ONLY on a PR labelled
`risk-bearing`, and ONLY USER applies that label.** This is the ruling's one home. The
orchestrator and every driver never apply it; a Contract commit (save-file shape, `.tres` schema,
`project.godot` autoloads or input map — `mm-change-control`) SUGGESTS it in the PR body and
waits. `risk-bearing` adds `coverage-analysis`, `adversarial-analysis`, `adversarial-probes` and
`mutation` to stage 1 and owes a stage-2 `MERGE` at the merge sha.

Stage 2 is one cold reader with a shell returning `MERGE`, `MINOR FIX`, `MAJOR FIX` or
`REDESIGN` at a sha, and **MERGING NOTHING**. `revue verdict --pr N --check <sha>` exits 0 only
for a `MERGE` read at that sha; `MINOR` (exit 3) names fixes judged small enough to merge unread —
§ Disposition. Two reads per PR. A dead seat with its one `fallback` spent → PARK.

`quick` / `docs-only` PRs skip both stages: they derive no roles and no round, and `clearance`
clears them on their own record. Those two labels are the whole skip list.

**The merge precondition is one unconditional `revue clearance --pr N --check <sha>`**: coverage
on every PR, plus that stage-2 `MERGE` on `risk-bearing`. `tools/merge_pr.sh N <sha>` asks it
FIRST and refuses on any nonzero exit. `revue plan` writes the derived classification into
`round.json` and `clearance` compares it against the PR's live labels, refusing (exit 2) when they
moved apart — so a label added after the round is unanswerable, never a pass. **Clearance is a
procedural gate, not a GitHub one**: branch protection requires a PR but 0 approvals and no status
checks, so the web merge button still works. `tools/merge_pr.sh` is the ONLY sanctioned merge
path; it pins `--match-head-commit <sha>` to the sha clearance checked, so a push between the two
is refused.

## `revue.toml` — math_maze's config, walked through

At the repo root, committed. Every verb takes `--config`, so no verb depends on where it runs.
**This table names SEATS and BACKENDS, never model ids**: an id retyped here drifts the day the
model changes upstream. `revue.toml` and the generated block below hold the ids.

| Key | math_maze's value | What it decides |
|---|---|---|
| `round_root` | `~/.cache/math_maze-rounds` | Where round dirs live. `--root` / `$REVUE_ROUND_ROOT` override. |
| `roles_dir` | *unset* | revue's shipped roles; no per-repo overrides. |
| `gate` | `tools/gate.sh` | Named in the execution preamble — never a bare `godot`. |
| `gate_targeted` | `tools/gate.sh <_test_name>` + the full form + the output contract | Quoted VERBATIM into every execution preamble in place of revue's pytest-shaped default. Its one home. |
| `failing_test_re` | `^FAIL:\s+([^:\s]+):` | How `mutation` finds the failing test's name in the gate output; the harnesses print exactly that line. |
| `gate_exclusive` | `false` | One headless Godot is ~2 min and does not saturate the box; two seats gating at once is fine. |
| `context` | *the solo-hobby-game sentence* | Goes into every brief VERBATIM: no adversary, no deployment; obfuscation-only and hostile-save findings are out of scope. |
| `decoy_env` | `MM_USER_DIR` | Forced to an EMPTY DECOY dir in every sandbox. The GAME honours it (`autoload/user_dir.gd`), so a seat running `godot` by hand still writes its save and settings into the decoy, never the live ones. `XDG_DATA_HOME` would not work under the flatpak. A decoy, not a jail. |
| `safety_invariant` | *"write nothing outside this repo clone, the gate's own temp dir, and revue's round cache; never unset or repoint `MM_USER_DIR`"* | Goes into every brief VERBATIM. |
| `clearance.max_fix_lines` | `40` (revue's default, chosen knowingly) | A fully trailered `Review-fix:` delta this size or smaller clears without a re-sweep. |
| `labels.risk` | `risk-bearing` | The PR label that adds the risk roles and owes stage 2. USER only. |
| `labels.skip` | `quick`, `docs-only` | No round at all. |
| `labels.stage2_label` | *empty* | Stage 2 is owed on `labels.risk`; a second label would only be another way to not launch. |
| `roles.always` | `independent-derivation`, `reproduction` | Every PR. This IS the light set. |
| `roles.risk` | `coverage-analysis`, `adversarial-analysis`, `adversarial-probes`, `mutation` | Added by `risk-bearing`. |
| `roles.path_rules` | `[]` | No path adds a role. |
| `roles.light` | *disabled* (`confined_to = []`) | Deliberate: `always` is already the light pair, and a path-confined light rule would make a PR touching one file outside its list silently HEAVIER. |
| `roles.no_code` | `*.md`, `design/`, `=LICENSE` → drop `mutation` | A prose-only range cannot cover `mutation`. The light pair is never dropped. |
| `defaults.seats` | `* = claude` | Every stage-1 role on the implementer's own family (USER 2026-09-07, accepted knowingly). |
| `defaults.fallback` | `claude:sonnet` | ONE launch a dead seat falls to. A second death is a dead seat → PARK. |
| `defaults.stage2` | *unset* | The cold reader: revue's shipped `pi` seat, so the id lives upstream only. |
| `backends` | `claude` 3 × 25 min, `pi` 2 × 35 min | Concurrency is MACHINE-WIDE (one lock dir, shared with every revue repo on this box); an undeclared backend has no bound. |

### The resolved roster

GENERATED — `revue seats --config revue.toml --check .claude/REVIEWERS.md` must exit 0; run
`revue seats --config revue.toml --format md --write .claude/REVIEWERS.md` after any `revue.toml`
change. Never hand-edit between the markers. The `model` column is resolved through the adapter a
launch would use, which is why an inherited seat still shows its id.

<!-- revue-seats:begin -->
| role | spec | model | conc | timeout | note |
|---|---|---|---|---|---|
| * | claude | sonnet | 3 | 25m | every role with no seat of its own |
| cold-read | pi:openai-codex/gpt-6-astra | openai-codex/gpt-6-astra | 2 | 35m | stage 2 |
| fallback | claude:sonnet | sonnet | 3 | 25m | one launch a dead seat falls to |
<!-- revue-seats:end -->

**Same family, and today the same model.** Every stage-1 seat is claude-family, the implementer's
family: agreement with the implementing session is one opinion measured twice. The claude
adapter's default id and the `claude:sonnet` fallback resolve to the SAME model (the table shows
it), so a fallback launch is the same model retried, not a second opinion. Seated knowingly (USER
2026-09-07); the stage-2 cold reader on `pi` is another family, so a `risk-bearing` PR is still
read by two. Changing either is one line in `revue.toml` and a regenerate.

## Disposition — what a finding earns

Findings are cheap; head-moving fixes are not.

- **Severity on every finding, and only WRONG earns a commit on this PR.** Wrong = the code is
  incorrect, the test proves nothing it claims, or the evidence is fabricated. Everything else —
  weak assertion, unpinned edge case, style — is refuted or filed as a `backlog` issue and picked
  up when a PR next touches the file. A reviewer asked for numbered findings WILL number some; the
  count is not the signal.
- **A SMALL batch voids nothing.** Every commit carries a `Review-fix:` body line and the delta
  from the covered sha to the new head is ≤ 40 added+deleted lines (`clearance.max_fix_lines`):
  `revue clearance --check <new head>` computes it, clears, and prints the delta it accepted —
  READ that diffstat before `READY`, it is what went unreviewed. Over the cap, or one untrailered
  commit, and the re-sweep is owed: `plan --base <covered sha>` → re-answer → launch → coverage.
  Never `revue plan` after a push you mean to clear this way — a new round moves the covered head.
  Refuting a finding is free; batch every fix into ONE push. A stale comment is doc-rot, not
  WRONG, unless THIS PR made it false.
- **Tooling findings** (about revue, `revue.toml`, the gate, a skill) → a `backlog` issue, never a
  fix on the PR under review. A revue bug goes to MCancian/revue.

## Caps

1. **TWO stage-1 rounds per submission.** Sweep 1 → fix batch (append-only `Review-fix:` commits,
   gate each) → `clearance` clears a SMALL batch on the old coverage (§ Disposition); else ONE
   re-sweep on the fix delta, pinned with `revue plan --base <the covered sha>`. Still uncovered
   after the second round → PARK. On `risk-bearing` the budget is per SUBMISSION to stage 2: a
   stage-2 `FIX` opens a fresh two (cap 3). **revue does not enforce this count** — it will open
   `r3` without complaint. Count the round dirs under `~/.cache/math_maze-rounds/pr<N>/` before
   planning.
2. A seat that returns short is re-run once by revue, then stands as flaked. A seat that dies gets
   ONE launch on the roster `fallback`. A second death is a dead seat: `revue status` exits 1 and
   names it → PARK. Never a third launch, no model swap, no degrading an execution role into a
   reading one, no partial merge.
3. **Stage 2 (`risk-bearing` only).** `MINOR` → ONE fix batch, gate each, push, NO re-plan /
   re-sweep / reread: `revue clearance --check <new head>` clears the small delta over the MINOR at
   the read sha, or names why not — then treat it as `FIX`. A `MERGE` clears its own sha only.
   `FIX` resets cap 1: two more stage-1 rounds on the delta (`plan --base`, same pin), then ONE
   reread (`launch --stage 2 --reread`). Second `FIX` → PARK `second-FIX`. `REDESIGN` → PARK.
   revue caps the READS at 2, so at most one `FIX` cycle exists.
4. Reviewers never implement. The cold seat holds `gh`; the prompt refuses the merge. The session
   that owns the PR merges it, with `tools/merge_pr.sh N <sha>`, which asks `revue clearance
   --check` first.

## Safety

Execution roles run in a disposable clone, `HOME` inherited, `MM_USER_DIR` forced to an empty decoy
directory: the game's save and settings land there, so no reviewer run reads or writes the live
saves under `~/.var/app/org.godotengine.Godot/data/godot/app_userdata/math_maze/`. The gate keeps
its own temp dir. No real save file is ever a fixture: a test that needs one writes its own under
`MM_USER_DIR`. What is refused is the LIVE DATA, not the shell.
