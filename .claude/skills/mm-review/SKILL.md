---
name: mm-review
description: Pointer — review of a math_maze PR runs on revue and is driven by the per-issue driver in mm-orchestrate. `revue --help` is the doc of record for the tool; math_maze's route, disposition and caps are .claude/REVIEWERS.md.
---

# Review a PR → `revue`, driven by `mm-orchestrate`

The tool is **`revue`** (MCancian/revue). **`revue --help` and `revue VERB --help` are the doc of
record** for what it does; when a math_maze doc disagrees, revue wins.

Every PR is on the LIGHT route (`independent-derivation` + `reproduction`); stage 2 only on
`risk-bearing`, which USER alone applies (`.claude/REVIEWERS.md`). The loop is the per-issue
DRIVER in `.claude/skills/mm-orchestrate/SKILL.md`, steps 5–7:

    revue plan --pr N                    # derive the roles, write stubs → answer → roster + brief
    revue launch --pr N                  # stage 1, detached, under the machine slot (75 = busy)
    revue status --pr N                  # seat states; exit 1 when a seat is dead
    revue post --pr N                    # one PR comment per return
    revue coverage --pr N                # every derived role covered at the head? exit 1 names the gap
    revue launch --pr N --stage 2        # the cold read — `risk-bearing` only
    revue verdict --pr N --check <sha>   # exit 0 only for a MERGE read at that sha
    revue clearance --pr N --check <sha> # exit 0 only when the record satisfies the PR's route
    tools/merge_pr.sh N <sha>            # asks clearance first, and refuses on any nonzero exit

Run every verb from the session worktree (it finds `revue.toml` there) or pass `--config`.
Caps: two stage-1 rounds per submission (a small trailered fix batch ≤ 40 lines clears without a
re-sweep); one fallback launch per dead seat; two cold reads; then PARK. Docs-only / `quick`:
gate green, own-diff read, no round — `tools/merge_pr.sh N <sha>` clears them on their own record.
