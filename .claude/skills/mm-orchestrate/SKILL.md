---
name: mm-orchestrate
description: Drive a milestone issue→PR→review→merge with one opus subagent per issue. Orchestrator half (intake, spawn, merge, report) and the per-issue driver half (the subagent brief). Review runs on revue; math_maze's route, disposition and caps live in .claude/REVIEWERS.md; this file is the loop.
---

# Orchestrate a milestone

One session = the ORCHESTRATOR. One `opus` subagent per issue, each in its own worktree, runs the
whole per-issue driver below — spike, implement, PR, stage-1 sweep, fix batch, one re-sweep, and
the cold read only when USER has labelled the PR `risk-bearing` — and returns ONE line. The
orchestrator merges. Nothing here asks USER anything; everything undecidable is PARKED with a
comment. **The orchestrator never applies `risk-bearing`.**

## Return lines (the whole contract)

- `READY <pr> <sha>` — the record clears the merge at `<sha>`, i.e. `revue clearance --pr <pr>
  --check <sha>` exits 0: clean stage-1 coverage, plus a stage-2 `MERGE` at that sha on
  `risk-bearing`. (Docs-only / `quick`: the full gate is green on the pushed tree, and clearance
  clears them with no round at all.)
- `PARKED <pr> <reason>` — PR left `gh pr ready` + ONE comment; reason ∈ `no-acceptance-test`,
  `design`, `gate-red`, `dead-seat:<role>`, `uncovered:<role>`, `flake-twice:<role>`,
  `second-FIX`, `redesign`, `cap:<what>`, `contract` (a Contract commit awaiting USER's label call).
- `SPLIT <pr>` — scope-cap WARNING (6 commits) hit and the acceptance test is more than one PR's
  worth; successor issues filed in the milestone.
- `GO? <pr> <stage1|resweep|cold|reread>` — ready to launch a review; the orchestrator continues
  it with `SendMessage` `REVIEW GO` when no other review is running. Context intact, it resumes at
  the launch.

## Hard caps — the brief carries them

1. **Stage 1**: sweep 1 → fix batch (append-only `Review-fix:` commits, gate each) → a SMALL batch
   (≤ 40 lines, every commit trailered) keeps its coverage and `revue clearance` says so; else ONE
   fix-delta re-sweep. TWO stage-1 rounds per submission (revue enforces none of it: count the
   round dirs under `~/.cache/math_maze-rounds/pr<N>/` yourself). Batch every fix into one push,
   refute what does not need fixing — `.claude/REVIEWERS.md` § Disposition owns the rule.
2. **Flaked seat**: revue re-runs a short return once by itself, then it stands as flaked. Never
   re-launch the sweep for one seat. Still uncovered → PARK `flake-twice:<role>`.
3. **Stage 2** (`risk-bearing` only): `MINOR` → one small fix batch → `clearance` at the new head,
   no reread. `FIX` → fix → narrow stage-1 pass on the delta → ONE reread. Second `FIX` → PARK
   `second-FIX`. `REDESIGN` → PARK.
4. **Dead seat** (a death, then its one `fallback` launch also dead — `revue status` exits 1 and
   names it): PARK `dead-seat:<role>`. No third launch, no model swap.
5. **Tooling findings** (about revue, `revue.toml`, the gate, the skill): a `backlog` issue, never
   a fix on this PR. A revue bug goes to MCancian/revue.
6. **Scope cap**: at the 6-commit WARNING finish when the acceptance test is one PR's worth, else
   file successors and return `SPLIT`. The refusal at 8 is never negotiated
   (`MM_ALLOW_LONG_BRANCH` is not for subagents).
7. **Gate red after two focused tries** → PARK `gate-red`. **Design question** → issue comment +
   label `design` → PARK `design`. **Contract commit** (save-file shape, `.tres` schema,
   `project.godot`) → PR body names it and suggests `risk-bearing`; the PR still goes through the
   light route and returns `READY` — the orchestrator holds the merge and reports it to USER, who
   decides the label (§ Orchestrator 5).
8. **Serialization**: implementation is parallel; review sweeps and cold reads run ONE AT A TIME
   machine-wide — `revue launch` takes the slot itself and exits 75 having run nothing when it is
   busy. The subagent returns `GO? <pr> <stage>` before every launch and resumes on `REVIEW GO`.

## Orchestrator

1. Pick the milestone. `rtk proxy gh issue list --milestone "<name>" --state open --json number,title,labels,body`.
2. **Intake.** Skip any issue whose `## Blocked by #N` names a tracking issue that still carries
   `design` (USER has not answered). Size each remaining issue (§ Splitting). Order by dependency
   (files touched; a shared file = sequential). Read the tracking issue for the stated order.
3. **`revue probe` once at the start of a session** — every backend as a table, exit 0 when every
   row is `up`. Not per PR. `revue plan` seats from `revue.toml`; do not hand-seat.
4. **Spawn** one `Agent` per issue: `subagent_type: general-purpose`, `model: opus`, prompt = the
   § Driver below verbatim, plus issue number, slug, milestone name, expected `origin/main` tip
   (`git -C ~/Projects/math_maze rev-parse --short origin/main`), the trailer block, and the file
   list siblings own. Parallel spawns for disjoint files; `REVIEW GO` one at a time via
   `SendMessage`.
5. **On `READY N <sha>`**: verify, never trust — `revue clearance --pr N --check <sha>` must exit
   0; a PR whose body names a Contract commit is NOT merged: report it to USER (label call), leave
   it ready. Otherwise from the MAIN checkout (never the worktree):
   `tools/merge_pr.sh N <sha> --worktree ~/Projects/math_maze-wt/<slug>` (which asks that same
   question again and refuses on its own); `revue reap`; fresh-clone gate on `main` — **clone the
   REMOTE, and check the sha**: `git clone -q "$(git -C ~/Projects/math_maze remote get-url
   origin)" $S/main && git -C $S/main log --oneline -1` must show the merge commit BEFORE the gate
   is worth anything, then `rtk proxy $S/main/tools/gate.sh > $S/gate.log 2>&1`. Cloning the local
   checkout gates whatever was last pulled and fails success-shaped. Red on main → stop merging,
   file an issue, report.
6. **On `PARKED` / `SPLIT`**: record; on `SPLIT` re-brief the successors when their turn comes;
   move on. Never re-spawn on the same PR to "try again".
7. **End**: ONE comment on the milestone's tracking issue, in plain words — merged (issue, PR,
   sha), parked (PR, reason), held for USER's label call, split, issues filed. Outcomes only.

## Splitting (at intake and at the warning)

Split when the acceptance test needs more than one PR, or the work is more than ~6 scope commits,
or it spans two subsystems. Successors: one acceptance test, one PR each, filed in the milestone,
label `plan` or `backlog`; the parent is the `plan` tracking issue whose `## Successors` lists
them. A subagent that hits the warning does the same and returns `SPLIT`.

## Driver — the subagent brief (existing scripts only, in this order)

You work ONE issue start to finish in YOUR OWN worktree. `git -C <abs path>` on every git command.
Never touch `~/Projects/math_maze` (the shared checkout) except `tools/session_worktree.sh` from
it, and never edit `$R/tree` (a round's frozen worktree). No `AskUserQuestion`; no question to
USER. Never apply `risk-bearing`.

1–4. **Issue → worktree → spike → test first → implement → gate → PR.** `CLAUDE.md` § Loop steps
   1–7 IS this, unabridged; follow it there. What differs for a subagent: the worktree is
   `W=~/Projects/math_maze-wt/<slug>` from `tools/session_worktree.sh <slug>`, and `git -C $W log
   --oneline -1` must show the expected tip (else `git -C $W fetch origin && git -C $W reset --hard
   origin/main`); a missing acceptance test is `PARKED N no-acceptance-test`, never a question to
   USER; docs-only / `quick` skips to step 8 with `READY N <sha>` after a full gate on the pushed
   tree. Gate through `rtk proxy tools/gate.sh` from `$W`; never a bare `godot`.
5. **Stage 1.** `revue plan --pr N` derives the roles from the PR's labels and writes the roster,
   `brief.md` and one prompt per seat. Pass NO `--targets`: `$T` is revue's own default home.
   Run it once and it writes a STUB `$T/<role>.md` per seated role and exits 0 having written no
   round dir — that is the role list, handed to you. Answer every stub, deleting its
   `<< UNFILLED >>` line, and run it again; a stub left unfilled exits 2 by name. Answer each
   question yourself first; execution files also demand NUMBERED findings. Do NOT restate the
   targeted run in a targets file: `gate_targeted` in `revue.toml` is its one home. Fill every
   TODO in the brief. Return `GO? N stage1`, resume on `REVIEW GO`, then `revue launch --pr N`
   (detached; exit 75 = the slot was busy and NOTHING ran — return `GO? N stage1` again). Poll
   `revue status --pr N`; never a foreground wait.
6. **Coverage + fix batch.** `revue post --pr N` puts each return on the PR; `revue coverage --pr
   N` decides, naming the gap. Read EVERY return; accept or refute each finding in ONE disposition
   comment on the PR. Only a WRONG finding earns a commit here (`.claude/REVIEWERS.md`
   § Disposition); the rest is refuted or filed `backlog`. Fix batch: append-only commits with
   `Review-fix: <what>` on a body line of its own, gate each, push. A batch under 40 lines with
   every commit trailered KEEPS its coverage: skip the re-plan, run `revue clearance --pr N
   --check <new head>` — it clears and prints the delta it accepted (read it), or names why not,
   and only then is the re-sweep owed. Never run `revue plan` after a push you mean to clear this
   way. Re-sweep: `revue plan --pr N --base <the head the first sweep covered>` → RE-ANSWER `$T`
   for the head that moved → GO → `revue launch --pr N` → coverage again (`--base` is `plan`'s;
   `launch --base` exits 2). `$T` survives the round, so plan REFUSES a round whose questions are
   byte-identical to the last one's; `--reuse-targets` is the escape hatch, not the default.
   Flaked or dead seat → caps 2 and 4. Uncovered after the second round → PARK.
7. **Stage 2 — only when the PR carries `risk-bearing`** (`rtk proxy gh pr view N --json labels`);
   otherwise skip to 8 with the sha coverage cleared. GO, then `revue launch --pr N --stage 2`
   (detached, under the same slot). Refused while stage 1 is uncovered and refused a model that
   held a stage-1 role on this PR; every refusal only LOGS to the runner log. A dead seat falls to
   the roster `fallback` once, inside revue. Then `revue verdict --pr N`: `MERGE` (exit 0) →
   `READY N <sha>`. `MINOR` (exit 3) → ONE fix batch, gate each, push, NO re-plan / re-sweep /
   reread; `revue clearance --pr N --check <new head>` clears the small delta → `READY N <new
   head>`; refused → treat as `FIX`. `FIX` (exit 1) → fix batch → narrow stage-1 pass on the
   delta → coverage → ONE `revue launch --pr N --stage 2 --reread`. Second `FIX` → PARK
   `second-FIX`. `REDESIGN`, no verdict, or both seats dead → PARK.
8. **Return** the one line, then a report ≤ 10 lines: acceptance test met how; class per commit
   (a Contract commit named as such, with the `risk-bearing` suggestion); what NOT verified;
   issues filed. Findings are acted on, not narrated.

Paths: rounds live at `~/.cache/math_maze-rounds/pr<N>/r<k>` (`revue plan` prints the one it
made); `T=~/.cache/math_maze-rounds/pr<N>/targets`, revue's own default, so name it only when
reading the files, never as `--targets`; `$LOG` under the scratchpad. Run every revue verb from
`$W` so it finds `$W/revue.toml`, or pass `--config`. `rtk proxy` on every `gh`/`git diff`/gate
whose output you read.
