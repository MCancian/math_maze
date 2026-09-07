#!/usr/bin/env bash
# Give this session its own worktree, so nothing it does depends on a checkout other sessions move.
#
# Usage:
#   tools/session_worktree.sh <slug>        # branch <slug> off origin/main, in its own tree
#
#   MM_WT_ROOT=DIR   where worktrees live (default: the directory holding the repo);
#                      the tree is <root>/math_maze-wt/<slug>.
#
# WHY THIS EXISTS. In a sibling project (2026-08-27) a session working on a branch in the SHARED main checkout
# had that checkout switched to another session's branch: its next gate run reported about the
# OTHER session's tree, and two of its edits landed on the peer's branch. "HEAD moves under you"
# is a rule about noticing afterwards, and it did not fire.
#
# A worktree is the structural answer: two sessions cannot move each other's HEAD.
#
# This script is a convenience, not a gate. `git worktree add` by hand stays entirely legal; what
# matters is the `.mm-session` marker it leaves, which `tools/gate.sh` reads so a tree that
# changed branch underneath a session is REFUSED rather than answering about someone else's code.
set -euo pipefail

die() { echo "session_worktree: $*" >&2; exit 2; }

MARKER=".mm-session"

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
slug="${1:-}"
case "$slug" in
	"")        die "a slug is required: tools/session_worktree.sh <slug>" ;;
	-h|--help) sed -n '2,12p' "$0" | cut -c3-; exit 0 ;;
esac
[[ "$slug" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] \
	|| die "'$slug' is not usable as a branch name and a directory name"

root="${MM_WT_ROOT:-$(dirname "$repo_root")}"
mkdir -p "$root" || die "cannot create the worktree root '$root'"
root=$(cd "$root" && pwd -P)
# Inside the repo, the worktree is untracked content in the checkout it exists to escape — and it
# would trip the review launcher's contamination check on every round.
case "$root" in
	"$repo_root" | "$repo_root"/*) die "the worktree root '$root' is inside the repository" ;;
esac

# UNDER `math_maze-wt/`, not as a sibling named `math_maze-wt-<slug>`: peer directories beside the
# repo are indistinguishable from it at a glance and never reaped (USER 2026-09-02).
mkdir -p "$root/math_maze-wt" || die "cannot create the worktree folder '$root/math_maze-wt'"
tree="$root/math_maze-wt/${slug//\//-}"
# Branch first, directory second: when both exist the branch is the useful diagnosis — it says the
# slug is taken and names the command for working on it — whereas "that directory exists" leaves
# the reader to work out why. The directory check still catches a stale tree whose branch is gone.
git -C "$repo_root" show-ref --verify --quiet "refs/heads/$slug" \
	&& die "branch '$slug' already exists — pick another slug, or 'git worktree add \"$tree\" $slug' to work on it"
[[ -e "$tree" ]] && die "'$tree' already exists"

git -C "$repo_root" fetch -q origin || die "git fetch origin failed"
git -C "$repo_root" rev-parse --verify --quiet origin/main >/dev/null \
	|| die "no origin/main to branch from"
git -C "$repo_root" worktree add -q -b "$slug" "$tree" origin/main \
	|| die "git worktree add failed"

# The marker is what `tools/gate.sh` reads. Written INSIDE the worktree, so it travels with the
# tree it describes and disappears when the tree does.
printf '%s\n' "$slug" >"$tree/$MARKER"

# Ignored via the common git dir AS WELL AS the tracked `.gitignore` (which this repo carries, for
# fresh clones): the exclude write is what covers a repository whose `.gitignore` predates the
# marker, which is every worktree made from an older checkout.
#
# ABSOLUTE: `git rev-parse --git-common-dir` may answer a path relative to the REPOSITORY, and
# appending `/info/exclude` to that and writing it from another cwd lands the file somewhere else
# entirely (round 1, jarvis 6). `--path-format=absolute` is the fix; the `cd` fallback covers a git
# too old for it.
if ! common=$(git -C "$repo_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
	common=$(cd "$repo_root" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
fi
exclude="$common/info/exclude"
mkdir -p "$(dirname "$exclude")"
if ! grep -qxF "$MARKER" "$exclude" 2>/dev/null; then
	printf '%s\n' "$MARKER" >>"$exclude"
fi

cat <<EOF
worktree: $tree
branch:   $slug  (off origin/main)

Work in it:
  cd $tree

The gate refuses to run there if the tree stops being on '$slug' ($MARKER).
First gate run in a fresh tree also runs the editor import (registers class_name scripts), so it
is slower than the rest.

When the PR is merged:
  git -C $repo_root worktree remove $tree
EOF
