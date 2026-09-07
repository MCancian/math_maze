#!/usr/bin/env bash
# The gate: run the headless suite against THIS checkout, away from the live saves, and prove it did.
#
# Usage:
#   tools/gate.sh                  # full: editor import, then both harnesses
#   tools/gate.sh <_test_name>     # one test, e.g. tools/gate.sh _test_music
#
# Exits: 0/1 the suite; 2 no such test, bad usage, godot missing, no project.godot;
#        3 commits on local `main`; 4 this tree left the branch its session claimed;
#        5 too many scope commits on the branch.
#
#   GODOT=/path              the binary (default ~/.local/bin/godot, the flatpak wrapper)
#   MM_ALLOW_MAIN_COMMITS=1  exit 3 becomes a warning (the bootstrap commit, a hotfix on main)
#   MM_ALLOW_LONG_BRANCH=1   exit 5 becomes a warning (the commit that ENDS the branch)
#
# Failures print `FAIL: <_test_name>: <message>` on stdout (revue's `failing_test_re`); each harness
# ends with `<harness>: N failure(s)`; the last line of a run is `gate: GREEN` or `gate: RED`.
set -euo pipefail

# PHYSICAL paths (`pwd -P`): the invoked-from warning at the end compares them.
invoked_from=$(pwd -P)
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
GODOT="${GODOT:-$HOME/.local/bin/godot}"
cd "$root"

# ---------------------------------------------------------------------------------------------
# `main` is PR-only (CLAUDE.md § Loop step 2, AGENTS.md § Git workflow), and `gh pr merge` leaves
# you standing ON it — so the branch you hold after every merge is the one you must not commit to.
# The recovery below is cheap only while those commits are the newest thing in the log.
#
# This is the gate and not a `pre-commit` hook DELIBERATELY: a hook needs installing per clone, which
# nothing in this repo does — an uninstalled guard protects the one clone that already remembered.
# The gate is the step no commit series skips.
#
# Every branch below is a NON-refusal except the one that names local commits on `main`: a detached
# worktree (reviewers read one), any other branch, a `main` level with or behind `origin/main` (the
# baseline "is main green" run), and a tree with no `.git` at all.
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
	branch=$(git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null || true)

	# ------------------------------------------------------------------------------------------
	# THE TREE MOVED UNDER THE SESSION. `tools/session_worktree.sh` leaves `.mm-session` naming the
	# branch the session claimed. Where that marker exists, this refuses rather than answering about
	# code the caller is not editing. No marker, no change: the shared checkout and every reviewer
	# worktree behave exactly as before.
	if [[ -f "$root/.mm-session" ]]; then
		# Read the FIRST LINE and trim only its ends (a `tr -d '[:space:]'` would also delete
		# internal spaces and match a branch the marker never named). ONE check, not a `-r` test
		# and then a read: a read that failed AND produced nothing is "the read did not work",
		# which covers a permission failure as well as an I/O one.
		claimed=""
		marker_readable=1
		if ! IFS= read -r claimed <"$root/.mm-session" 2>/dev/null && [[ -z "$claimed" ]]; then
			marker_readable=0
		fi
		claimed="${claimed#"${claimed%%[![:space:]]*}"}"
		claimed="${claimed%"${claimed##*[![:space:]]}"}"
		# Whether HEAD is detached is asked of git, not inferred from an empty `$branch`:
		# `symbolic-ref` also fails on a corrupt repository. THREE states, not two.
		head_state="unknown"
		if git -C "$root" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
			if git -C "$root" symbolic-ref -q HEAD >/dev/null 2>&1; then
				head_state="branch"
			else
				head_state="detached"
			fi
		fi
		if [[ "$marker_readable" -eq 0 ]]; then
			echo "gate: WARNING — could not judge which branch this session claimed:" >&2
			echo "  $root/.mm-session is not readable." >&2
		elif [[ -z "$claimed" ]]; then
			# A warning, and the run CONTINUES: an empty marker is a broken write by our own tool,
			# and refusing every gate run until someone repairs it is the worse failure.
			echo "gate: WARNING — could not judge which branch this session claimed:" >&2
			echo "  $root/.mm-session is empty." >&2
		elif [[ -z "$branch" && "$head_state" != "detached" ]]; then
			echo "gate: REFUSING TO RUN — this tree is not on the branch this session claimed." >&2
			echo "  standing in: $root" >&2
			echo "  claimed:     $claimed" >&2
			echo "  now:         could not be determined — HEAD does not resolve" >&2
			echo "Not a detached HEAD, which has its own message: git could not answer at all." >&2
			echo "Check the repository before trusting any suite run from here." >&2
			exit 4
		elif [[ -z "$branch" ]]; then
			echo "gate: REFUSING TO RUN — this tree is not on the branch this session claimed." >&2
			echo "  standing in: $root" >&2
			echo "  claimed:     $claimed" >&2
			echo "  now:         a detached HEAD" >&2
			echo "A marked tree that went detached did so under the session. Reviewer worktrees are" >&2
			echo "detached on purpose and carry no marker; this one does." >&2
			echo "    git -C $root checkout $claimed" >&2
			exit 4
		elif [[ "$branch" != "$claimed" ]]; then
			echo "gate: REFUSING TO RUN — this tree is not on the branch this session claimed." >&2
			echo "  standing in: $root" >&2
			echo "  claimed:     $claimed" >&2
			echo "  now on:      $branch" >&2
			echo "Another session moved this checkout, or you switched branch and forgot. A suite run" >&2
			echo "from here is evidence about someone else's code, and an edit lands on their branch." >&2
			echo "    git -C $root checkout $claimed" >&2
			echo "Or, if the move was deliberate, update $root/.mm-session." >&2
			exit 4
		fi
	fi

	if [[ "$branch" == "main" ]]; then
		if ! git -C "$root" rev-parse --verify --quiet origin/main >/dev/null; then
			# Cannot judge is not a pass — say so rather than fall silent. A fresh clone always has
			# this ref; a repo without it cannot be asked whether anything landed locally.
			echo "gate: WARNING — could not judge whether commits landed on local 'main':" >&2
			echo "  no origin/main ref in $root. Try: git fetch origin" >&2
		else
			# `|| true` and the shape test together: under `set -euo pipefail` a failing count
			# would take the whole gate down, and an empty `$ahead` reaching `[[ -gt ]]`
			# evaluates as 0 — a silent "all clear" from a question that was never answered.
			ahead=$(git -C "$root" rev-list --count origin/main..HEAD 2>/dev/null || true)
			if [[ ! "$ahead" =~ ^[0-9]+$ ]]; then
				echo "gate: WARNING — could not judge whether commits landed on local 'main':" >&2
				echo "  counting origin/main..HEAD failed in $root" >&2
			elif [[ "$ahead" -gt 0 ]]; then
				noun="commits"
				if [[ "$ahead" -eq 1 ]]; then noun="commit"; fi
				oneline=$(git -C "$root" log --oneline origin/main..HEAD)
				if [[ -n "${MM_ALLOW_MAIN_COMMITS:-}" ]]; then
					echo "gate: WARNING — $ahead $noun on local 'main', allowed by" >&2
					echo "  MM_ALLOW_MAIN_COMMITS. They are still not on a branch:" >&2
					echo "$oneline" | sed 's/^/    /' >&2
				else
					echo "gate: REFUSING TO RUN — commits on local \`main\`." >&2
					echo "  standing in: $root" >&2
					echo "  $ahead $noun ahead of origin/main:" >&2
					echo "$oneline" | sed 's/^/    /' >&2
					echo "'main' is PR-only (CLAUDE.md § Loop step 2). Move them onto a branch:" >&2
					echo "    git branch -f <slug> HEAD && git reset --hard origin/main" >&2
					echo "This is cheap now and expensive after another commit or a pull." >&2
					echo "Deliberate? MM_ALLOW_MAIN_COMMITS=1 tools/gate.sh" >&2
					exit 3
				fi
			fi
		fi
	fi

	# ------------------------------------------------------------------------------------------
	# THE SCOPE-COMMIT CAP (USER 2026-09-07). One issue, one PR. Warn at 6, refuse at 8.
	#
	# ONLY SCOPE COMMITS COUNT. A branch under review grows fix commits, and splitting it mid-review
	# strands work that has already been reviewed — a rebase changes every sha and voids the
	# coverage. So a fix commit is exempt: a body line starting `Review-fix: <what>`, on a line of
	# its own, any paragraph (git treats only the LAST paragraph as trailers and every commit here
	# ends with the harness's Co-Authored-By block, so `%(trailers:...)` would miss it). A mid-line
	# mention is prose and exempts nothing; a bare `Review-fix:` with no value exempts nothing.
	#
	# NOT ON `main` (its history is every branch ever merged) and NOT on a detached HEAD (reviewer
	# worktrees are detached at a branch tip on purpose, and refusing there would stop the REVIEW of
	# an over-cap branch rather than its author).
	if [[ -n "$branch" && "$branch" != "main" ]]; then
		if ! git -C "$root" rev-parse --verify --quiet origin/main >/dev/null; then
			echo "gate: WARNING — could not judge how many scope commits this branch carries:" >&2
			echo "  no origin/main ref in $root. Try: git fetch origin" >&2
		else
			scope_base=$(git -C "$root" merge-base origin/main HEAD 2>/dev/null || true)
			if [[ -z "$scope_base" ]]; then
				echo "gate: WARNING — could not judge how many scope commits this branch carries:" >&2
				echo "  no merge-base between origin/main and HEAD in $root" >&2
			else
				# Counted per commit: a message may carry anything, and a one-commit-per-line
				# format cannot be read back safely once a body contains a newline of its own.
				scope_n=0
				while IFS= read -r _sha; do
					[[ -n "$_sha" ]] || continue
					if git -C "$root" show -s --format='%B' "$_sha" 2>/dev/null \
						| grep -qiE '^Review-fix:[[:space:]]*[^[:space:]]'; then
						continue
					fi
					scope_n=$(( scope_n + 1 ))
				done < <(git -C "$root" rev-list "$scope_base..HEAD" 2>/dev/null || true)

				scope_noun="commits"
				if [[ "$scope_n" -eq 1 ]]; then scope_noun="commit"; fi
				if [[ "$scope_n" -ge 8 ]]; then
					if [[ -n "${MM_ALLOW_LONG_BRANCH:-}" ]]; then
						# The hatch is for gating the commit that ENDS the branch — the stopping
						# point, the successor issues. Without it the recovery the warning asks
						# for is itself ungateable. It never silences the count.
						echo "gate: WARNING — $scope_n scope $scope_noun on '$branch', allowed by" >&2
						echo "  MM_ALLOW_LONG_BRANCH. The cap is 8 (CLAUDE.md § Work unit)." >&2
					else
						echo "gate: REFUSING TO RUN — too many scope commits on '$branch'." >&2
						echo "  standing in: $root" >&2
						echo "  $scope_n scope $scope_noun since $(git -C "$root" rev-parse --short "$scope_base")" >&2
						echo "  (commits with a 'Review-fix: <what>' line in the message are exempt)" >&2
						echo "One issue, one PR (CLAUDE.md § Work unit). Get to a stopping point:" >&2
						echo "  1. finish the smallest coherent thing that passes its own acceptance test" >&2
						echo "  2. file every successor issue — spec, acceptance test, labels — into the milestone" >&2
						echo "  3. write a brief for a milestone orchestrator and hand off" >&2
						echo "Gating that stopping-point commit: MM_ALLOW_LONG_BRANCH=1 tools/gate.sh" >&2
						exit 5
					fi
				elif [[ "$scope_n" -ge 6 ]]; then
					echo "gate: WARNING — this branch is getting long: $scope_n scope $scope_noun on '$branch'." >&2
					echo "  The cap is 8 and it is a hard refusal. Consider a stopping point:" >&2
					echo "  finish the smallest coherent thing, file the successor issues into the" >&2
					echo "  milestone, hand off (CLAUDE.md § Work unit)." >&2
					echo "  Review-fix commits are exempt; only scope commits count." >&2
				fi
			fi
		fi
	fi
fi

[[ -x "$GODOT" ]] || { echo "gate: godot not found at $GODOT (set GODOT=)" >&2; exit 2; }
[[ -f "$root/project.godot" ]] || { echo "gate: $root has no project.godot" >&2; exit 2; }
[[ $# -le 1 ]] || { echo "gate: at most one test name (tools/gate.sh [_test_name])" >&2; exit 2; }
# THIS tree: every godot call below carries --path "$root", so a relative launch cannot test another.
echo "gate: project <- $root/project.godot"

# `$root` comes from BASH_SOURCE, so a relative `tools/gate.sh` typed in the wrong directory picks
# up the wrong tree's gate and then passes its own checks, cleanly and silently. A warning, not a
# refusal: running an absolute `/path/to/tools/gate.sh` from anywhere is legitimate.
case "$invoked_from" in
	"$root" | "$root"/*) ;;
	*)
		echo "gate: WARNING — invoked from outside the tree it is about to test." >&2
		echo "  invoked from: $invoked_from" >&2
		echo "  testing:      $root" >&2
		echo "If you typed a RELATIVE path, your shell's cwd is not where you think it is" >&2
		echo "and this run is evidence about the wrong checkout. Re-run from \$root." >&2
		;;
esac

# user:// ISOLATION. A native Linux Godot resolves user:// under XDG_DATA_HOME — but ~/.local/bin/godot
# here is the flatpak, and the flatpak sandbox FORCES its own XDG_DATA_HOME
# (~/.var/app/org.godotengine.Godot/data), ignoring the caller's and `flatpak run --env`
# (measured 2026-09-07). So the GAME honours MM_USER_DIR (autoload/user_dir.gd): every save-side
# file lands there when it is set. The gate points it at a temp dir; XDG_DATA_HOME is set too, for
# a native binary. The live saves are never read or written by a gate run, and a reviewer sandbox
# forces MM_USER_DIR to a decoy (revue.toml `decoy_env`).
# UNDER ~/.cache, NOT /tmp: the flatpak sandbox has a PRIVATE /tmp (a file the game writes there is
# invisible from the host and gone with the process), while $HOME is shared. A host-visible dir is
# what lets a reviewer inspect the save a test wrote. MM_GATE_TMP overrides the parent.
gate_parent="${MM_GATE_TMP:-$HOME/.cache/math_maze-gate}"
mkdir -p "$gate_parent"
gate_tmp=$(mktemp -d "$gate_parent/run.XXXXXX")
trap 'rm -rf "$gate_tmp"' EXIT
export MM_USER_DIR="$gate_tmp/user"
export XDG_DATA_HOME="$gate_tmp/data"
mkdir -p "$MM_USER_DIR" "$XDG_DATA_HOME"
echo "gate: user:// <- $MM_USER_DIR"

# Bounded: a hung scene never holds the gate. A run whose output lacks the harness finish line
# (`… N failure(s)`) is RED even on exit 0 — a crash before quit() must not read as green.
# 300 s: the full runtime scene is ~100 s here. A PARSE ERROR in a harness script is the slow red:
# the scene loads without its script, nothing calls quit(), and only this timeout ends it.
run() {
	echo "gate: --- $*"
	local rc=0
	set +e
	timeout 300 "$GODOT" --headless --path "$root" "$@" 2>&1 | tee "$gate_tmp/out.txt"
	rc=${PIPESTATUS[0]}
	set -e
	if ! grep -q 'failure(s)$' "$gate_tmp/out.txt"; then
		echo "gate: no finish line from: $* (exit $rc)" >&2
		return 1
	fi
	# A runtime script error ABORTS the test function it happens in, so its remaining checks never
	# run and the harness counts 0 failures — a false green (measured 2026-09-07: a typed-array
	# assignment error skipped every star-threshold check). Any such line is RED.
	if grep -q 'SCRIPT ERROR' "$gate_tmp/out.txt"; then
		echo "gate: script error during: $*" >&2
		return 1
	fi
	return "$rc"
}

# Editor import FIRST: registers class_name scripts and imports assets; a new class_name script
# fails a normal boot with "Could not find type X" until this has run once (AGENTS.md § Testing).
echo "gate: --- --editor --quit (import)"
if ! timeout 300 "$GODOT" --headless --path "$root" --editor --quit >"$gate_tmp/import.out" 2>"$gate_tmp/import.err"; then
	cat "$gate_tmp/import.err" >&2
	echo "gate: editor import failed" >&2
	exit 1
fi
if grep -hE 'SCRIPT ERROR|Parse Error' "$gate_tmp/import.err" "$gate_tmp/import.out" >&2; then
	echo "gate: script errors during import" >&2
	exit 1
fi

if [[ $# -eq 0 ]]; then
	rc=0
	run -s res://tools/test_save_and_level.gd || rc=1
	run res://tools/test_runtime.tscn          || rc=1
	echo "gate: $([[ $rc -eq 0 ]] && echo GREEN || echo RED)"
	exit $rc
fi

name="$1"
[[ "$name" =~ ^_test_[A-Za-z0-9_]+$ ]] || { echo "gate: '$name' is not a _test_ name" >&2; exit 2; }
rc=0
if   grep -qE "\"${name}\":" "$root/tools/test_save_and_level.gd"; then
	run -s res://tools/test_save_and_level.gd -- "--test=$name" || rc=1
elif grep -qE "\"${name}\":" "$root/tools/test_runtime.gd"; then
	run res://tools/test_runtime.tscn -- "--test=$name" || rc=1
else
	echo "gate: no test named '$name' (names are the keys of _tests() in tools/test_*.gd)" >&2
	exit 2
fi
echo "gate: $([[ $rc -eq 0 ]] && echo GREEN || echo RED)"
exit $rc
