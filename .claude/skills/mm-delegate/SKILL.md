---
name: mm-delegate
description: Brief and run harness subagents for parallel mechanical work in math_maze — scope, worktree traps, what a delegate hands back, what the orchestrator re-verifies. Self-report is not evidence.
---

# Delegate to subagents

Subagents buy parallelism on mechanical work with disjoint file scopes.

**A delegate MAY COMMIT**, in its own worktree on its own branch. Under a milestone orchestrator
the one-delegate-per-issue driver — it commits on its own branch, opens the PR, runs the review,
returns `READY` / `PARKED` / `SPLIT` — is `.claude/skills/mm-orchestrate/SKILL.md`; this file is
the brief shape and the isolation rules both kinds share. A delegate never merges and never runs
`godot` outside the gate against a real save.

## Isolation — five rules, every kind

Subagents have run `amend`/`reset` against a SHARED checkout after a failed `cd`. Not malice —
they lost track of which directory they were in. Every rule is about isolation:

1. **Own worktree, always** — `isolation: "worktree"` on the Agent tool, or
   `tools/session_worktree.sh <slug>`. Never the shared main checkout.
2. **`git -C <absolute path>` on every git command.** Never rely on cwd.
3. **Own branch only.** Never commit on `main`, never push to `main`, never `amend`/`reset`/
   `rebase` or force-push anything the delegate did not create.
4. **The delegate gates its own tree** — `tools/gate.sh` tests the tree holding the script and
   isolates `user://` itself. **The orchestrator re-gates before merging.**
5. **No merging, ever, by a delegate.** Merge is the irreversible step pinned to review coverage
   and it stays with the orchestrator, which reads the round returns itself: a delegate's gate
   verdict is a claim.

**Review launches serialize.** `revue launch` takes the machine-wide slot and exits 75 having run
nothing when it is busy; the orchestrator grants `REVIEW GO` one at a time so a queued driver
waits as a returned turn.

**Scope-commit cap.** A delegate's branch is subject to it like any other: 8 scope commits and the
gate refuses, warning at 6 (`CLAUDE.md` § Work unit). Fix commits carry a `Review-fix:` trailer
and are exempt. A delegate that hits the cap hands the overflow back as successor issues; it
never sets `MM_ALLOW_LONG_BRANCH`.

## Brief — what every subagent prompt carries

1. **Issue number + acceptance test** in one sentence. The issue is the spec; the brief is a map.
2. **Exact file list** the delegate may edit. Anything outside → reject the diff.
3. **Read scope**: `file:function` targets, or whole-file with a stated reason.
4. **Expected tip** (`git -C ~/Projects/math_maze rev-parse --short origin/main`) — a worktree
   starts at the session's OPENING head. First action in the worktree:
   `git log --oneline -1; git merge-base --is-ancestor <tip> HEAD || git reset --hard <tip>`.
5. **The gate command**: `rtk proxy tools/gate.sh` (full) or `tools/gate.sh <_test_name>` — never
   a bare `godot`. Log to the scratchpad, quote the last line + exit code.
6. **Evidence discipline**: verbatim quotes with `file:line`; `ABSENT` + the exact search for zero
   hits. A count without its command is a claim.
7. **Hand-back shape**: for a NON-committing delegate, a patch via `rtk proxy git diff > FILE`
   (verify `grep -c '^diff --git'`). For a COMMITTING delegate, the branch name and the sha it
   pushed, plus its own gate line and exit code. Either way: what changed, what was NOT verified,
   any deviation from the brief and why.
8. **Whether it may commit, said explicitly**, and if so the branch name, the absolute worktree
   path it must use with `git -C`, the expected opening tip, and the commit trailer (the harness
   `Co-Authored-By` line plus the session link). Silence reads as "no".
9. **`.tscn` warning** when a file may move: every `res://` path is hand-maintained.

Paste the policy a judgement needs rather than citing where it lives; a delegate cannot follow a
pointer out of its worktree with confidence. One concern per brief.

## Orchestrator after the return

1. Read the whole diff. Every hunk inside the file list? Any test edited to pass → reject.
2. Apply to your tree, or fetch its branch. **Run the gate yourself.** After any delegated unit,
   confirm the shared checkout is untouched: `git -C ~/Projects/math_maze status --short` clean
   and `git log --oneline -1` unmoved.
3. Worktree cleanup: cherry-pick onto the branch (linear), `git worktree remove <path>`,
   `git branch -D <branch>`.
4. Commit. Gate once per pushed tree state.

## Two subagents, never one

A delegate's self-report is not evidence. Brief an **independent verifier that did not write the
code**, separately, on the same diff: does it do what it claims? anything outside the declared
file list? any test edited to pass rather than to pin? any cited line that does not say what the
citation claims? **Catching a self-proving test**: revert each fix one at a time in a scratchpad
clone and name every test that stays GREEN; ask the verifier for this by name.

## Shape rules

- **Reliable**: mechanical transformation with a mechanical check — renames, a `.tres` field
  added to every config, transcribing a pasted policy.
- **Unreliable**: a distinction carried only by prose in the brief; "suite green" without the
  gate's own last line.
- **Dangerous**: evidence citation. Verify every cite.
- **Never `cp -a` a worktree.** A worktree's `.git` is a FILE pointing into the parent repo, so
  the copy SHARES the parent's git dir: a checkout inside the copy moves the ORIGINAL's HEAD. Use
  `git clone` into the scratchpad instead, and never run a ref-moving command in a tree a round is
  reading (`$R/tree`).
