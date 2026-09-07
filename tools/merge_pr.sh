#!/usr/bin/env bash
# The merge step, from a session worktree, in one command.
#
# Usage: tools/merge_pr.sh N SHA [--worktree DIR] [--keep-worktree]
#
#   N        the pull request; SHA the 40-hex head the record was read at (the pin).
#   --worktree DIR   the session worktree to remove afterwards (default: the registered worktree
#                    whose branch is the PR's head branch, if any); --keep-worktree leaves it.
#
# Exit: 0 merged (remote branch gone; the worktree and local branch removed, or — when the script
#       runs FROM the session worktree, the documented case — left with the exact follow-up printed);
#       1 not merged — nothing deleted, including a refused clearance; 2 bad arguments, or
#       the main checkout sitting on the branch.
#
# WHY. `gh pr merge N --rebase --delete-branch --match-head-commit SHA` MERGES and then tries to
# check the base branch out locally before deleting the head branch — and from a worktree that
# step dies with `fatal: 'main' is already used by worktree at <the shared checkout>`, gh exits
# nonzero, and the REMOTE BRANCH IS LEFT BEHIND (measured 2026-09-02 in the sibling project this
# script came from). CLAUDE.md § Loop 2 tells every session to work in its own
# worktree, so that is the normal case, not an edge. This script asks the PR whether it merged
# rather than trusting gh's exit status, deletes the remote branch itself when gh could not, and
# tidies the worktree registration `git worktree list` was filling up with.
#
# THE PIN IS NOT RELAXED. `--match-head-commit SHA` is what makes a stage-2 verdict falsifiable: a
# head that moved after the read is refused by GitHub, and this script refuses a SHA that is not
# 40 hex so a short or mistyped pin cannot be passed through. It merges nothing on its own
# authority — it runs the one documented line and reports what the PR says happened.
#
# THE RECORD IS ASKED, NOT ASSUMED. `revue clearance --pr N --check SHA` exits 0 only
# when revue's record satisfies the route the PR is NOW on — clean stage-1 coverage on every PR, a
# stage-2 `MERGE` read AT THAT SHA on `risk-bearing` — so the same 40 hex characters gate the check
# and `--match-head-commit`, and no session's word stands in for the record on the PR. The call is
# unconditional: revue holds the label rule, not this script, and a classification that moved under
# an existing record is unanswerable (exit 2), never a pass. There is no operator bypass to answer
# for — a `quick` / `docs-only` PR derives no roles and has no `round.json`, so coverage is
# trivially clean and clearance exits 0 on the non-risk route by itself.
set -u

die() { echo "merge_pr: $*" >&2; exit 2; }

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
# BEFORE the positional shift: `tools/merge_pr.sh --help` has no N and no SHA to shift past, so
# asking for help used to die on the usage line instead of printing the help.
case "${1:-}" in -h|--help) sed -n '2,13p' "$0" | cut -c3-; exit 0 ;; esac
pr="${1:-}"; sha="${2:-}"; shift 2 2>/dev/null || die "usage: tools/merge_pr.sh N SHA [--worktree DIR] [--keep-worktree]"
worktree=""; keep=0
while [[ $# -gt 0 ]]; do
	case "$1" in
		--worktree)      [[ $# -ge 2 && "${2}" != -* ]] || die "--worktree needs a directory, got '${2:-}'"
		                 worktree="$2"; shift 2 ;;
		--keep-worktree) keep=1; shift ;;
		-h|--help)       sed -n '2,13p' "$0" | cut -c3-; exit 0 ;;
		*)               die "unknown argument '$1'" ;;
	esac
done
[[ "$pr" =~ ^[0-9]+$ ]] || die "N must be digits, got '$pr'"
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || die "SHA must be the 40-hex head the record was read at, got '$sha' — the pin is the mechanism, a short sha is not passed through"
command -v gh >/dev/null 2>&1 || die "gh is not on PATH"

# THE MERGE PRECONDITION. Before anything is asked of gh: does the record satisfy the route?
command -v revue >/dev/null 2>&1 || {
	echo "merge_pr: revue is not on PATH, so clearance cannot be checked — nothing merged." >&2
	exit 1
}
# The repo's own config, named — not whatever `revue.toml` the caller's cwd happens to walk up to.
revue_cfg=(); [[ -f "$repo_root/revue.toml" ]] && revue_cfg=(--config "$repo_root/revue.toml")
clearance_rc=0
revue clearance --pr "$pr" --check "$sha" "${revue_cfg[@]}" >&2 || clearance_rc=$?
if [[ "$clearance_rc" -ne 0 ]]; then
	echo "merge_pr: revue clearance --pr $pr --check $sha exit $clearance_rc — the record does not satisfy the route the PR is on (1 blocked: a coverage gap, or no stage-2 MERGE at that sha nor MINOR at a covered ancestor within the fix cap; 2 unanswerable: the classification moved under the record). Nothing merged." >&2
	exit 1
fi

branch=$(gh pr view "$pr" --json headRefName -q .headRefName) || die "gh pr view $pr failed"
[[ -n "$branch" ]] || die "PR #$pr has no head branch"

# THE ONE DOCUMENTED LINE, verbatim. Its exit status is NOT the verdict on the merge (see WHY).
gh pr merge "$pr" --rebase --delete-branch --match-head-commit "$sha" 2>&1 | sed 's/^/gh: /' >&2

state=$(gh pr view "$pr" --json state,mergeCommit -q '"\(.state) \(.mergeCommit.oid // "-")"') \
	|| die "gh pr view $pr failed after the merge call; check the PR by hand"
merged_state="${state%% *}"; merge_commit="${state#* }"
if [[ "$merged_state" != "MERGED" ]]; then
	echo "merge_pr: PR #$pr is $merged_state, not merged — nothing deleted. A refused pin means the head moved after the cold read; re-read before merging." >&2
	exit 1
fi
echo "merged: PR #$pr -> $merge_commit"

git -C "$repo_root" fetch -q origin 2>/dev/null || echo "merge_pr: WARNING — git fetch origin failed; the remote branch check below may be stale" >&2
if git -C "$repo_root" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
	if git -C "$repo_root" push origin --delete "$branch" >/dev/null 2>&1; then
		echo "remote branch deleted: $branch (gh could not — the worktree shape)"
	else
		echo "merge_pr: WARNING — could not delete remote branch '$branch'; delete it by hand: git push origin --delete $branch" >&2
	fi
else
	echo "remote branch already gone: $branch"
fi

if [[ "$keep" -eq 0 ]]; then
	if [[ -z "$worktree" ]]; then
		# The registered worktree on the PR's branch, if one exists — never the shared checkout,
		# which is on `main` and is not on this branch.
		worktree=$(git -C "$repo_root" worktree list --porcelain | awk -v b="refs/heads/$branch" '
			/^worktree / { wt = substr($0, 10) }
			/^branch / && $2 == b { print wt; exit }')
	fi
	# THE TREE THIS SCRIPT STANDS IN CANNOT BE REMOVED BY IT — and that is the DOCUMENTED case: the
	# merge is run from the session worktree of the PR branch, so `repo_root` (from BASH_SOURCE) IS
	# that worktree. A stage-2 cold read caught it: the first version `die`d here, so a MERGED PR
	# exited 2 with the tidy-up silently skipped — the exact lie this script was built to end,
	# with a different number. Now: say so, name the follow-up, leave the branch (it is checked out
	# here), and exit 0 — the merge happened and the remote branch is gone.
	skip_local=0
	if [[ -n "$worktree" && -d "$worktree" ]]; then
		wt_real=$(cd "$worktree" && pwd -P)
		if [[ "$wt_real" == "$repo_root" ]]; then
			git_dir=$(git -C "$repo_root" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
			common_dir=$(git -C "$repo_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
			if [[ -n "$git_dir" && "$git_dir" != "$common_dir" ]]; then
				shared_root=$(dirname "$common_dir")
				echo "worktree NOT removed: $wt_real is the tree this script ran from. From the shared checkout:"
				echo "  git -C $shared_root worktree remove --force $wt_real && git -C $shared_root branch -D $branch"
				skip_local=1
			else
				die "refusing to remove the main checkout '$repo_root': it is on '$branch', which is the PR branch — move it to main first (git -C $repo_root checkout main)"
			fi
		elif git -C "$repo_root" worktree remove --force "$wt_real" 2>/dev/null; then
			echo "worktree removed: $wt_real"
		else
			echo "merge_pr: WARNING — could not remove worktree '$wt_real'; git worktree remove --force it by hand" >&2
		fi
	fi
	if [[ "$skip_local" -eq 0 ]] && git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
		git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1 && echo "local branch deleted: $branch" \
			|| echo "merge_pr: WARNING — could not delete local branch '$branch' (checked out somewhere?)" >&2
	fi
	git -C "$repo_root" worktree prune 2>/dev/null || true
fi
exit 0
