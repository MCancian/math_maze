# CLAUDE.md — Claude harness guide

Read `AGENTS.md` first: repo facts, orientation table, testing traps. This file: workflow.

## Style

Docs terse like caveman. Technical substance exact. Fluff die. No articles, filler, hedging,
pleasantries. Fragments OK. Pattern: [thing] [action] [reason]. No dated incident narration —
`git blame` carries history; doc carries rule only. **Substance never compresses**: paths,
commands, symbols, numbers byte-exact. Exception: `design/` reads as plain English (AGENTS.md
§ Style). Reports to USER in plain words first, IDs after — USER is a non-coding parent-designer.

## Work unit

Intent = GitHub **issue**. Work = **branch + PR**, one session start→finish, in its own worktree.
Commit series = record. PR body = readout. History = `git log`. Campaigns = milestones. Nothing
else tracks work: there is no plan file (pre-2026-09-07 plans live at tag `plans-v1`).

### One issue, one PR

**One acceptance test, one issue.** Enforcement = the commit count.

- **Only SCOPE commits count.** A review-fix commit is exempt and they append freely: trailer
  `Review-fix: <what prompted it>` on a body line of its own, any paragraph, not the subject line.
  A bare `Review-fix:` with no value exempts nothing. Never split a branch mid-review: the
  rebase voids all review coverage.
- **Warn at 6. Hard refusal at 8**, in `tools/gate.sh` (exit 5). Measured against the merge-base
  with `origin/main`, so a branch stacked on another inherits its scope commits.
- `MM_ALLOW_LONG_BRANCH=1` warns and continues — for the commit that ENDS the branch. Never for a
  subagent.

**At the warning (6) — consider splitting.** The warning is advisory: a branch whose acceptance
test is one PR's worth finishes. Otherwise get to a stopping point, then:

1. Finish the smallest coherent thing that stands on its own and passes its own acceptance test.
2. **File every successor issue** — spec, acceptance test, labels — into the milestone (create
   the milestone if the issue has none).
3. **Write a brief for a milestone orchestrator** and hand off.

### The milestone orchestrator → `mm-orchestrate`

One session orchestrates a milestone: one `opus` subagent per issue, each in its own worktree,
runs the per-issue driver (spike, implement, PR, stage-1 sweep, ONE re-sweep, stage 2 only on
`risk-bearing`) and returns `READY <pr> <sha>` / `PARKED <pr> <reason>` / `SPLIT <pr>`; the
orchestrator merges with `tools/merge_pr.sh N <sha>` from the main checkout, never on a
subagent's word — `revue clearance --pr N --check <sha>` must exit 0, and the merge script asks
it. Implementation runs in parallel; review sweeps serialize machine-wide on revue's own slot.
Caps and PARK rules: the skill.

**Size at intake.** The orchestrator splits an issue whose acceptance test needs more than one PR,
or more than ~6 scope commits, or two subsystems: successor issues (one acceptance test, one PR
each) in the milestone; the parent is the `plan` tracking issue listing them. Intake SKIPS any
issue whose `## Blocked by` names a tracking issue still labelled `design`. A subagent that hits
the 6-commit WARNING finishes when the acceptance test is one PR's worth, else files successors and
returns `SPLIT`. The refusal at 8 is never negotiated.

Labels: `plan` (tracking issue, or real feature work), `backlog` (tracked, unscheduled; also review
residue and tooling findings), `quick`, `docs-only` (skip both review stages), `design` (USER
question; the orchestrator parks), `risk-bearing` (**applied by USER only**, on a PR: adds the
risk roles and requires a stage-2 MERGE). That is the whole list.

## Loop

1. **Issue.** `rtk proxy gh issue view N --json title,body,author,state,labels,comments`.
   Acceptance test in one sentence. Missing → ask USER via issue comment, label `design`. No
   guessing. A brief from another agent is a MAP, never the spec; on conflict the issue wins.
2. **Branch — in your own worktree.** `tools/session_worktree.sh <slug>` (worktree off
   `origin/main` at `../math_maze-wt/<slug>`, plus the `.mm-session` marker the gate checks).
   `main` PR-only; never push to it, never COMMIT on it. `git branch --show-current` before every
   commit; work landed on `main` moves off with
   `git branch -f <slug> HEAD && git reset --hard origin/main`. `tools/gate.sh` refuses (exit 3) on
   a `main` ahead of `origin/main`. Issue without a milestone → `gh issue edit N --milestone <name>`.
3. **Spike if unsure.** Approach/number unknown → throwaway worktree, run it, post numbers to the
   issue. Never merge a spike. Reasoning about what code "probably does" = signal to spike.
4. **Test first.** Failing test = spec, SEEN failing (`FAIL: <test>: …`, `gate: RED`) and quoted
   in the commit body. Add it to `_tests()` in `tools/test_runtime.gd` (needs autoloads, scenes,
   groups, signals) or `tools/test_save_and_level.gd` (pure data, no autoloads); the key is the
   selector: `tools/gate.sh _test_name`. Owed by Additive / Behavioral / Contract commits;
   Docs-only and `tools/` commits skip it. No NEW test for a gate script unless a failure was
   OBSERVED and the commit body names it.
5. **Implement.** Classify per commit (§ Change class). Smallest verifiable commits, and no more
   than **8 SCOPE commits** on the branch — the gate refuses past that (§ Work unit). Review-fix
   commits carry a `Review-fix:` trailer and do not count. Subagents for parallel mechanical work,
   disjoint file scopes; a delegate given its OWN worktree may commit there (`mm-delegate`).
6. **Gate green.** `rtk proxy tools/gate.sh > "$LOG" 2>&1; GATE=$?; tail -1 "$LOG"; [ "$GATE" -eq 0 ]`.
   Never through a pipe inside `&&` (tail's exit 0 has pushed a red suite). Never a bare `godot`
   run as the verdict. Green on the exact tree you push; one edit after the run voids it.
7. **PR.** **`git rebase origin/main` is the only sync.** Never `git merge origin/main`: a merge
   commit is not replayable by `--rebase` (step 9). Rebase, resolve once, force-push.
   After every rebase, `tools/rebase_scope_check.sh` — a conflict resolved by keeping YOUR side
   silently un-merges a sibling's merged work. Exit 1 → restore the named files before pushing;
   exit 3 → it could not judge (name the pre-rebase tip with `--orig`), which is not a pass.
   Then `git push -u origin <slug>`; `gh pr create --draft` early; `gh pr ready` when gate green.
   PR labels drive the route (`revue plan` reads PR labels, not issue labels): `quick` /
   `docs-only` skip review; `risk-bearing` is USER's alone — a Contract commit SUGGESTS it in the
   PR body and waits. Body: what, why, class per commit, what NOT verified.
8. **Review — `revue`.** Every PR takes the light route (`independent-derivation` +
   `reproduction`); stage 2 only on `risk-bearing`. The loop's shape: plan → launch → post →
   coverage → fix batch → one re-sweep → (stage 2) → `clearance`. `revue --help` is the doc of
   record for the tool; the driver is `mm-orchestrate` steps 5–7. **Which route a PR is on, what
   a finding earns, and every cap live in `.claude/REVIEWERS.md`.**
9. **Merge.** `tools/merge_pr.sh N <sha>` from the main checkout. It asks
   `revue clearance --pr N --check <sha>` FIRST and refuses on any nonzero exit, then runs
   `gh pr merge N --rebase --delete-branch --match-head-commit <sha>`, asks the PR whether it
   merged, deletes the remote branch gh leaves behind from a worktree, and removes the session
   worktree. Linear history, no merge bubbles — USER standing rule; the pin refuses a head that
   moved after the read. Then `revue reap` and a fresh-clone gate on `main`. GitHub does NOT block
   the web merge button (0 approvals, no status checks): `tools/merge_pr.sh` is the ONLY sanctioned
   merge path.

   USER ruling or behaviour change → same PR edits **the** doc of record, the ONE place that fact
   lives: `CLAUDE.md` for the loop and the work unit, `.claude/REVIEWERS.md` for review routes and
   seating, `.claude/skills/mm-orchestrate/SKILL.md` for the driver and caps, `design/<area>.md`
   for what the game must do, the script's header comment for a subsystem. A USER ruling is
   written INTO the rule it changes; there is no second copy.

Stop and ask USER: design decision, gate red after two focused tries, anything destructive, any
change to the save-file shape (Contract). Under the orchestrated loop (USER asleep) a stop is a
PARK: issue comment + `design` label, PR left ready and unmerged. An idea → issue, not a branch.

## Change class → gate

Per commit, by runtime EFFECT, before writing. Unsure → higher. Details: `mm-change-control`.

| Class                                                  | Gate                                                        | Reviews                                  |
| ------------------------------------------------------ | ----------------------------------------------------------- | ---------------------------------------- |
| Docs-only, `quick`                                     | gate green; review own diff                                 | 0 — merge                                |
| Additive / Behavioral                                  | gate green + the new or targeted test                       | light pair                               |
| Contract (save-file shape, `.tres` schema, `project.godot` autoloads / input map) | gate green + back-compat evidence (an old save still loads) + consumer grep | light pair; USER may add `risk-bearing` → four risk roles + stage-2 MERGE |

Reviews column = stage-1 ROLE COVERAGE, not a count — `revue coverage --pr N` decides it, and the
roles are derived from the PR labels in `revue.toml` (`.claude/REVIEWERS.md`).

## Delegation

- **Per-issue drivers and subagents** — `mm-orchestrate` (one `opus` subagent per issue: it
  commits, opens the PR, runs the review; the orchestrator merges) and `mm-delegate` (mechanical
  work, disjoint file scopes). Their gate verdict is a claim; the merge step re-gates. Brief names
  the expected tip — a fresh worktree starts at the session's OPENING head. Five isolation rules,
  every kind:
  1. **Own worktree, always** — `tools/session_worktree.sh <slug>` or `isolation: "worktree"`.
     Never the shared main checkout.
  2. **`git -C <absolute path>` on every git command.** Never rely on cwd; a failed `cd` has run
     `amend`/`reset` against a shared checkout before.
  3. **Own branch only.** Never commit on `main`, never push to `main`, never
     `amend`/`reset`/`rebase` or force-push anything the delegate did not create.
  4. **The delegate gates its own tree** (`tools/gate.sh` tests the tree holding the script);
     **the orchestrator re-gates on `main` after merging.**
  5. **No merging, ever, by a delegate.**
  `revue launch` takes the machine-wide slot itself and exits 75 having run nothing when it is
  busy. An orchestrator ALSO grants `REVIEW GO` one at a time, so a queued driver waits as a
  returned turn, not as a blocked process.
- Reviewers RUN THINGS: a stage-1 execution role holds a shell in a disposable clone with
  `MM_USER_DIR` forced to an empty decoy; the stage-2 seat holds one plus `gh` and merges nothing.
  Reviewers never implement.

## Harness facts

- rtk hook rewrites `git` / `gh` output into summaries. Any diff handed to another party:
  `rtk proxy git diff`, then `grep -c '^diff --git'` before trusting it. `rtk proxy gh issue view`.
  `rtk proxy tools/gate.sh`.
- `~/.local/bin/godot` is the **flatpak** (4.7.2). Its sandbox overrides `XDG_DATA_HOME`; the gate
  isolates `user://` through `MM_USER_DIR` instead (`autoload/user_dir.gd`). A bare `godot` run
  reads and writes the live saves under `~/.var/app/org.godotengine.Godot/data/godot/app_userdata/math_maze/`.
- Worktrees: each session in `../math_maze-wt/<slug>`; `.godot/` is per tree, so the first gate
  there runs the editor import from cold (slow once).
- **`.tscn` gotcha:** scenes use path-based `ext_resource` (no uid headers). Moving or renaming any
  `res://` file means hand-rewriting every referencing path — git will not catch a dangling path;
  the gate's import step will.
- Never edit a shell script while it is executing — bash resumes at a stale byte offset.
