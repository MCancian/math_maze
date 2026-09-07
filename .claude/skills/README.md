# math_maze skill library

Procedures for agents. **Facts live in code and `design/`**; skills say how to act and where the
traps are. Workflow rules: `CLAUDE.md`, `AGENTS.md`, `.claude/REVIEWERS.md`.

## Task → skill

| About to… | Read |
|---|---|
| Make ANY code/data/doc change (classify, gate, commit) | `mm-change-control` |
| Gate green, PR open, need review coverage | `mm-review` |
| Pick reviewer, judge whether a return counts, diagnose a flake | `.claude/REVIEWERS.md` (not a skill; the tool is `revue`) |
| Drive a milestone issue→PR→review→merge with subagents | `mm-orchestrate` |
| Brief a subagent, integrate its return | `mm-delegate` |

## Maintaining

- One skill = one job; link, don't duplicate. Each SKILL.md ≤ ~5 KB, caveman style.
- Skills are code: a stale one is fixed in the same commit as the change that staled it.
- Frontmatter `description` = trigger.
