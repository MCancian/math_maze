#!/usr/bin/env bash
# Catch a REBASE conflict resolution that reverted or dropped a sibling's already-merged work.
# Usage: tools/rebase_scope_check.sh [--base REF] [--head REF] [--orig REF] [--expect PATH]...
#                                    [--no-fetch] [-q]
#
# `git rebase origin/main` is this repo's only sync (CLAUDE.md § Loop). A conflict resolved by
# keeping YOUR side un-merges a sibling's work with no announcement, and its predecessor
# `merge_scope_check.sh` could not see it: that check's finding was A minus B (files differing from
# the base, minus files a branch commit touched), and after a rebase the resolution lives INSIDE a
# replayed branch commit, so its files are in B by construction. Measured 2026-08-27 — a rebase
# that dropped a sibling's file printed `no merge commits ... PASS (nothing to revert)`, exit 0.
#
# The rebase-aware question is not "which files did the branch touch" but "did rebasing change the
# branch's NET EFFECT beyond absorbing the base". Four trees:
#   ORIG  = the pre-rebase tip (--orig, else ORIG_HEAD), and OLDBASE = merge-base(ORIG, base)
#   HEAD  = the rebased tip,   and BASE    = the new base
# Every path gets ONE description — its tree entry (mode + oid, or absent) in each of the four —
# and one table decides. "Absent" is a value in that table, never a case of its own:
#   the base did not change it  -> the result must equal ORIG. Else DIVERGED.
#   the branch did not touch it -> the result must equal BASE: a clean absorption, of an edit, a
#                                  deletion or a rename alike. Else: absent -> DROPPED; the fork's
#                                  content -> RESTORED; an older base state -> REVERT; else NOVEL.
#   both changed it             -> result == ORIG == BASE: the base already carries it; silent.
#                                  == ORIG -> KEPT-OURS: resolved by taking the branch's side whole,
#                                  so the base's change is absent. THE shape that loses a sibling's
#                                  work. == BASE -> LOST-OURS: the branch's own work is absent
#                                  instead (a modify/delete resolved by deleting lands here).
#                                  absent -> DROPPED. the fork's content -> RESTORED. an older base
#                                  state -> REVERT. Anything else is a genuine merge of both: silent.
# A base-side RENAME src -> dst is an IDENTITY, not an exception: git's own rebase carries the
# branch's change at src across to dst, so that is where the branch's net effect is expected, the
# pair is judged as ONE path (reported `src -> dst`) and dst is not judged alone. A path is never an
# argument to git here, only a key: handed to git it is a pathspec or a revision, each with a
# grammar that swallows some names.
#
# WHEN TO RUN IT: right after `git rebase`, before further commits. Everything between the
# pre-rebase tip and HEAD is attributed to the rebase, so a commit made afterwards reads as part of
# it. The findings stay true (that content DID leave the branch); only the blame moves.
#
# "The same" is asked of the CONTENT first and of the MODE second, each by the same table: a
# result that kept the branch's mode bit and dropped every byte of its edit is LOST-OURS on the
# bytes; a chmod the resolver undid is a finding on the mode axis alone.
#
# WHAT A PASS DOES NOT MEAN. Bounded, deliberately, like its predecessor: a resolution that merged
# most of the base's change and dropped ONE HUNK of it inside a file the branch also edited is a
# genuine merge of both sides at file granularity and is invisible here. A pass is "the rebase did
# not change the branch's net effect except where the base moved", never "no revert happened".
# REVERT is blob-identity EVIDENCE, not causation: at most 60 base commits are walked per path, and
# that walk does not follow renames (older content under another name reads NOVEL).
# Renames are git's `-M` pairing at its ~50% similarity: below it, both names stand alone, as they
# do for git's own merge. The pairing is followed, never second-guessed: where a deleted file and a
# renamed one are alike, `-M` may pair the other one, and git's own merge may pair differently
# again (it weighs only the files the merge touches) — the branch's change is then judged at the
# paired name, a finding in the conservative direction, or silent when its bytes are already there. Not modelled, stated rather than guessed: the branch renaming a file to a
# DIFFERENT name than the base did (each name is judged alone; a kept pair is a finding); the
# branch adding a file under a directory the base renamed whole (git relocates it, this reads it
# as two DIVERGED names); the base deleting a file the branch edited and the resolver writing
# NEW content there (a genuine merge by the table, though there was nothing of the base's to merge).
#
# Exit 0: pass. Exit 1: findings. Exit 2: bad args / git failure. Exit 3: unjudgeable — no
# pre-rebase tip, or the base is not an ancestor of HEAD. Never a PASS for a question not asked.
set -Eeuo pipefail
# The header promises "Exit 2: bad args / git failure". Without this, `set -e` lets a git failure
# escape with its OWN status — 128 for a missing object — and a caller checking for 2 sees a code
# the contract never mentions. Deliberate exits (1 findings, 3 unjudgeable) do not fire ERR.
# `-E`: the trap must reach a git call inside a FUNCTION too (the tree loader), else that one
# escapes with 128.
trap 'rc=$?; echo "rebase_scope_check: a git or shell command failed (exit $rc)" >&2; exit 2' ERR

base="origin/main"; head_ref="HEAD"; orig_ref=""; do_fetch=1; quiet=0; expects=()
die() { echo "rebase_scope_check: $*" >&2; exit 2; }

while [[ $# -gt 0 ]]; do
	case "$1" in
		--base)      base="${2:-}"; [[ -n "$base" ]] || die "--base needs a ref"; shift 2 ;;
		--head)      head_ref="${2:-}"; [[ -n "$head_ref" ]] || die "--head needs a ref"; shift 2 ;;
		--orig)      orig_ref="${2:-}"; [[ -n "$orig_ref" ]] || die "--orig needs a ref"; shift 2 ;;
		--expect)    [[ -n "${2:-}" ]] || die "--expect needs a path"
		             case "$2" in *'*'*|*'?'*) die "--expect takes one literal path, not a pattern: '$2'" ;; esac
		             expects+=("$2"); shift 2 ;;
		--no-fetch)  do_fetch=0; shift ;;
		-q|--quiet)  quiet=1; shift ;;
		-h|--help)   awk 'NR >= 2 && !/^#/ { exit } NR >= 2 { print substr($0, 3) }' "$0"; exit 0 ;;
		*)           die "unknown argument '$1'" ;;
	esac
done

git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
say() { [[ "$quiet" -eq 1 ]] || echo "$@"; }

# Fetch BEFORE resolving the base: a stale remote-tracking ref answers every later question wrong,
# and answers them plausibly. Only for a remote-tracking base; a local ref has nothing to fetch.
base_before=""
if [[ "$do_fetch" -eq 1 && "$base" == */* ]]; then
	remote="${base%%/*}"
	if git remote | grep -qx -- "$remote"; then
		base_before="$(git rev-parse --verify --quiet "$base^{commit}" || true)"
		git fetch --quiet "$remote" >/dev/null 2>&1 || die "git fetch $remote failed"
	fi
fi

resolve() { git rev-parse --verify --quiet "$1^{commit}" || true; }
base_oid="$(resolve "$base")"; [[ -n "$base_oid" ]] || die "base ref '$base' does not resolve to a commit"
head_oid="$(resolve "$head_ref")"; [[ -n "$head_oid" ]] || die "head ref '$head_ref' does not resolve to a commit"

# The fetch can advance the base under the caller, so the question answered stops being the one
# that was asked. Pass an OID to --base to pin it.
if [[ -n "$base_before" && "$base_before" != "$base_oid" ]]; then
	echo "rebase_scope_check: NOTE ${base} moved during this run: ${base_before:0:8} -> ${base_oid:0:8}."
	echo "  Judging against the NEW tip. Pass --base ${base_before:0:8} to ask about the old one."
fi

if ! git merge-base --is-ancestor "$base_oid" "$head_oid"; then
	behind="$(git rev-list --count "$head_oid..$base_oid")"
	echo "rebase_scope_check: ${base} (${base_oid:0:8}) is NOT an ancestor of ${head_ref} (${head_oid:0:8})."
	echo "  ${head_ref} is missing ${behind} commit(s) of ${base}: this branch has not been rebased onto it."
	echo "  Fix: git fetch origin && git rebase ${base}   then re-run."
	exit 3
fi

# The pre-rebase tip. ORIG_HEAD is what `git rebase` leaves behind, but it is also what `git reset`
# and `git merge` leave behind, so it is a DEFAULT and never an assumption: --orig pins it.
if [[ -n "$orig_ref" ]]; then
	orig_oid="$(resolve "$orig_ref")"; [[ -n "$orig_oid" ]] || die "--orig ref '$orig_ref' does not resolve to a commit"
else
	orig_oid="$(resolve ORIG_HEAD)"
fi
if [[ -z "$orig_oid" || "$orig_oid" == "$head_oid" ]]; then
	echo "rebase_scope_check: no pre-rebase tip to compare ${head_ref} against."
	if [[ -z "$orig_oid" ]]; then
		echo "  ${orig_ref:-ORIG_HEAD} is unset, so there is no before/after."
	else
		echo "  ${orig_ref:-ORIG_HEAD} (${orig_oid:0:8}) names ${head_ref} itself, so there is no before/after."
	fi
	echo "  This is UNJUDGEABLE, not a pass: run it right after 'git rebase ${base}', or name the"
	echo "  pre-rebase tip with --orig <ref> (git reflog ${head_ref} finds it)."
	exit 3
fi

# After a rebase the pre-rebase tip is NOT an ancestor of HEAD — its commits were replayed, not
# kept. One that IS an ancestor is something else wearing ORIG_HEAD's name (a reset, a merge, an
# earlier commit of this branch), and judging a rebase that did not happen is how the predecessor
# answered questions it had not asked. Refuse instead (round 1, sol).
if git merge-base --is-ancestor "$orig_oid" "$head_oid" 2>/dev/null; then
	# A FAST-FORWARD: every commit between the old tip and the new one is already in the base, so
	# nothing of the branch was replayed and no resolution happened. Refusing this reads as a
	# fault where there is none (round 2, sol).
	if git merge-base --is-ancestor "$head_oid" "$base_oid" 2>/dev/null; then
		say "rebase_scope_check: ${head_ref} fast-forwarded onto ${base}; no commit was replayed, so no resolution could have lost anything. PASS."
		say "  A pass is bounded: this says only that nothing was rewritten."
		exit 0
	fi
	echo "rebase_scope_check: ${orig_ref:-ORIG_HEAD} (${orig_oid:0:8}) is an ANCESTOR of ${head_ref}."
	echo "  A rebase replays its commits, so its pre-rebase tip is never an ancestor of the result."
	echo "  This names something else — a reset, a merge, or an earlier commit of this branch — so"
	echo "  there is no before/after to compare. UNJUDGEABLE, not a pass."
	echo "  Fix: name the real pre-rebase tip with --orig <ref>   (git reflog ${head_ref} finds it)."
	exit 3
fi

# ...and the mirror: a pre-rebase tip that is a DESCENDANT of HEAD is `git reset` after the rebase
# wearing ORIG_HEAD's name — the commit it discarded — and judging it reads the reset as a
# resolution (oracle T15). Same answer: not a rebase, not judgeable.
if git merge-base --is-ancestor "$head_oid" "$orig_oid" 2>/dev/null; then
	echo "rebase_scope_check: ${orig_ref:-ORIG_HEAD} (${orig_oid:0:8}) is a DESCENDANT of ${head_ref} (${head_oid:0:8})."
	echo "  A rebase's pre-rebase tip is never on the far side of its result: this names a commit made"
	echo "  and discarded AFTER the rebase (a reset), so there is no before/after. UNJUDGEABLE, not a pass."
	echo "  Fix: name the real pre-rebase tip with --orig <ref>   (git reflog ${head_ref} finds it)."
	exit 3
fi

old_base="$(git merge-base "$orig_oid" "$base_oid" || true)"
[[ -n "$old_base" ]] || die "no merge base between the pre-rebase tip and ${base}"

# Commits made AFTER the rebase are inside the before/after window and read as part of it. That
# cannot be untangled from here — but it can be SAID, and a count is enough to say it.
n_before="$(git rev-list --count "$old_base..$orig_oid")"
n_after="$(git rev-list --count "$base_oid..$head_oid")"
if [[ "$n_after" -ne "$n_before" ]]; then
	echo "rebase_scope_check: NOTE ${head_ref} has ${n_after} commit(s) since ${base}; the pre-rebase tip ${orig_oid:0:8} had ${n_before}."
	echo "  A count is not a diagnosis: work committed AFTER the rebase, a commit the rebase"
	echo "  dropped as already-upstream, and an interactive split all move it."
	echo "  Anything committed after the rebase is inside this window and reads as part of it —"
	echo "  run this right after the rebase, or pass --orig <the tip that rebase left behind>."
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# The four trees, loaded WHOLE, each path a KEY and never an argument to git. Handed to git, a path
# is a PATHSPEC (`ls-tree -- P`, `rev-list -- P`) or a REVISION (`rev-parse R:P`), and each has a
# grammar: a leading `:` is pathspec magic that names nothing, so both sides read absent, compare
# equal, and a dropped file passes; a newline is C-quoted on the way out and resolves to nothing on
# the way back in. Both were defects of the per-path lookups this replaces. `-z` so the path
# arrives raw; split at the FIRST tab and only there, a path may hold tabs of its own. `ls-tree -r`
# lists blobs and gitlinks; an entry is "<mode> <oid>". Through a FILE, not a process substitution,
# so a git failure reaches the ERR trap (exit 2) instead of reading as an empty tree.
declare -A ent_orig=() ent_head=() ent_oldbase=() ent_base=()
load_tree() {
	local -n into="$1"
	local line meta
	git ls-tree -r -z --full-tree "$2" > "$tmp/tree"
	while IFS= read -r -d '' line; do
		meta="${line%%$'\t'*}"
		into["${line#*$'\t'}"]="${meta%% *} ${meta##* }"
	done < "$tmp/tree"
}
load_tree ent_orig "$orig_oid"; load_tree ent_head "$head_oid"
load_tree ent_oldbase "$old_base"; load_tree ent_base "$base_oid"

# Renames since the fork, on BOTH sides. A base-side rename src -> dst is the IDENTITY the header
# describes. The branch's own renames are read for one reason: when both sides made the SAME
# rename, the branch's side of the file is at dst already and the identity reads it from there —
# else a clean rebase reports KEPT-OURS at the new name (oracle R27). Detection pinned: `-l0`, so
# an ambient diff.renameLimit cannot make git SKIP inexact detection — it does that with a warning
# on stderr and an empty result, which turned a clean rebase across a rename into two findings
# (oracle G26) — and `diff.renames=true` so a user config cannot switch it off. `-M` only: `-C`
# would pair a copy and `-B` a rewrite, and a rebase follows neither. NUL-delimited into bash
# through a file, so a git failure reaches the ERR trap rather than reading as "no renames".
renames() {
	if ! git -c diff.renames=true diff -z -M -l0 --diff-filter=R --name-status "$1" "$2" > "$3" 2> "$tmp/renames.err"; then
		cat "$tmp/renames.err" >&2; false
	fi
	if grep -qi 'rename detection' "$tmp/renames.err"; then
		echo "rebase_scope_check: git skipped rename detection between ${1:0:8} and ${2:0:8}:"
		sed 's/^/  /' "$tmp/renames.err"
		echo "  Without it a base-side rename reads as a deletion plus an addition. UNJUDGEABLE, not a pass."
		exit 3
	fi
}
declare -A branch_moved_to=() moved_to=() moved_from=() ident_o=()
renames "$old_base" "$orig_oid" "$tmp/renames.branch"
while IFS= read -r -d '' status && IFS= read -r -d '' src && IFS= read -r -d '' dst; do
	[[ "$status" == R* ]] || continue
	branch_moved_to["$src"]="$dst"
done < "$tmp/renames.branch"
renames "$old_base" "$base_oid" "$tmp/renames.base"
while IFS= read -r -d '' status && IFS= read -r -d '' src && IFS= read -r -d '' dst; do
	[[ "$status" == R* ]] || continue
	if [[ -n "${ent_orig[$dst]:-}" ]]; then
		# The branch has its own dst. The same rename on both sides: read the branch's side from
		# there. Anything else is the branch creating dst independently — an add/add at the new
		# name, which the identity would misread as the branch's change arriving — and both names
		# stand alone, a bound the header states.
		[[ "${branch_moved_to[$src]:-}" == "$dst" ]] || continue
		ident_o["$src"]="$dst"
	else
		ident_o["$src"]="$src"
	fi
	moved_to["$src"]="$dst"; moved_from["$dst"]="$src"
done < "$tmp/renames.base"

# Was this content once a state of the base's own history for this path? Then the resolution did
# not invent it -- it restored it, which is what reverting a sibling looks like from the outside.
# Here the path IS an argument: `--literal-pathspecs`, or a name with pathspec magic in it walks
# nothing and REVERT is blind for that file. The walk does not follow renames: under an identity
# it is dst's history, which begins at the rename.
# was_in_base OID DST [SRC]   Under an identity the walk takes dst THEN src: the base's states from
# before its rename live under the old name, and a walk of dst alone read a restored one of them
# as NOVEL, with a sentence naming a cause that had not happened (round 1, sol). Under the old
# name only commits where dst does not yet exist count: a LATER, unrelated file reusing that name
# is not this file's history, and its content restored at dst is not a REVERT (round 2, sol).
was_in_base() {
	local want="$1" first="$2" second="${3:-}" path c e guard
	[[ -n "$want" ]] || return 1
	for path in "$first" "$second"; do
		[[ -n "$path" ]] || continue
		guard=""; [[ "$path" == "$first" ]] || guard="$first"
		while read -r c; do
			[[ -n "$c" ]] || continue
			if [[ -n "$guard" && -n "$(git --literal-pathspecs ls-tree --full-tree "$c" -- "$guard" 2>/dev/null || true)" ]]; then continue; fi
			e="$(git --literal-pathspecs ls-tree --full-tree "$c" -- "$path" 2>/dev/null || true)"
			e="${e%%$'\t'*}"
			if [[ -n "$e" && "${e##* }" == "$want" ]]; then printf '%s\n' "$c"; return 0; fi
		done < <(git --literal-pathspecs rev-list --max-count=60 "$base_oid" -- "$path")
	done
	return 1
}

# The table, on ONE axis. Values are opaque strings and "" is absent — absent == absent holds, which
# is what makes a base-side deletion the branch never touched a clean absorption with no clause of
# its own. Sets `kind` ("" = silent) and `at` (REVERT's commit) in the caller's scope.
# decide O OLDBASE BASE HEAD WALK HISTORY-PATH...
decide() {
	local o="$1" bo="$2" bn="$3" h="$4" walk="$5"; shift 5
	kind=""; at=""
	if [[ "$bo" == "$bn" ]]; then
		# The base did not change it (a pure rename does not), so the rebase had nothing to
		# absorb into it: the result must be the branch's own, unchanged.
		[[ "$o" == "$h" ]] || kind=DIVERGED
	elif [[ "$o" == "$bo" ]]; then
		# The branch never touched it, so the result must be the base's — what every ordinary sync
		# looks like across an edit, a deletion, or a rename.
		if [[ "$h" == "$bn" ]]; then :
		elif [[ -z "$h" ]]; then kind=DROPPED
		elif [[ "$h" == "$bo" ]]; then kind=RESTORED
		elif [[ "$walk" -eq 1 ]] && at="$(was_in_base "$h" "$@")"; then kind=REVERT
		else kind=NOVEL
		fi
	else
		# Both changed it. The same change on both sides (cherry-picked upstream, or both deleting
		# the same obsolete file): the rebase drops the redundant commit and nothing is absent.
		# The order below is load-bearing and pinned: the branch's side kept, whole, is asked
		# before "absent" (a kept deletion is KEPT-OURS), the base's side before "absent" too.
		if [[ "$h" == "$o" && "$o" == "$bn" ]]; then :
		elif [[ "$h" == "$o" ]]; then kind=KEPT-OURS
		elif [[ "$h" == "$bn" ]]; then kind=LOST-OURS
		elif [[ -z "$h" ]]; then kind=DROPPED
		elif [[ "$h" == "$bo" ]]; then kind=RESTORED
		elif [[ "$walk" -eq 1 ]] && at="$(was_in_base "$h" "$@")"; then kind=REVERT
		fi
		# Anything else is content neither side had, on a file both changed: a genuine merge.
		# Silent ON PURPOSE — every honest resolution produces that. It is the gap the PASS names.
	fi
}

# Findings in ARRAYS, by index. What the report prints (`src -> dst` for an identity) is a label,
# never a key: a file literally named `a -> b` and the identity `a -> b` are two findings, and a
# label-keyed store had kept one (round 1, sol). Every value the report needs is kept beside the
# kind, so the report never re-derives a case the table already decided.
n_f=0
declare -a f_kind=() f_disp=() f_axis=() f_o=() f_bo=() f_bn=() f_h=() f_src=() f_dst=() f_at=()

# classify LABEL ORIG OLDBASE BASE HEAD SRC DST      (DST empty: SRC stands alone)
# Entries are "<mode> <oid>". The CONTENT is judged first, then the MODE, each by the same table:
# a resolution that kept the branch's mode bit and dropped every byte of its edit is LOST-OURS on
# the bytes, not a "genuine merge" of the entry (oracle M15); a chmod carried across a base-side
# edit is silent on both axes; a chmod the resolver undid is a finding on the mode axis alone.
classify() {
	local disp="$1" o="$2" bo="$3" bn="$4" h="$5" src="$6" dst="$7" axis kind at
	decide "${o##* }" "${bo##* }" "${bn##* }" "${h##* }" 1 "$dst" "$src"; axis=content
	if [[ -z "$kind" ]]; then decide "${o%% *}" "${bo%% *}" "${bn%% *}" "${h%% *}" 0; axis=mode; fi
	[[ -n "$kind" ]] || return 0
	f_kind[n_f]="$kind"; f_disp[n_f]="$disp"; f_axis[n_f]="$axis"
	f_o[n_f]="$o"; f_bo[n_f]="$bo"; f_bn[n_f]="$bn"; f_h[n_f]="$h"
	f_src[n_f]="$src"; f_dst[n_f]="$dst"; f_at[n_f]="$at"
	n_f=$((n_f + 1))
}

declare -A seen=()
for path in "${!ent_orig[@]}" "${!ent_head[@]}" "${!ent_oldbase[@]}" "${!ent_base[@]}"; do
	[[ -z "${seen[$path]:-}" ]] || continue
	seen["$path"]=1
	if [[ -n "${moved_to[$path]:-}" ]]; then
		dst="${moved_to[$path]}"; from="${ident_o[$path]}"
		classify "$path -> $dst" "${ent_orig[$from]:-}" "${ent_oldbase[$path]:-}" \
			"${ent_base[$dst]:-}" "${ent_head[$dst]:-}" "$path" "$dst"
		# The old name still present in the result is a second question, asked of it alone.
		[[ -z "${ent_head[$path]:-}" ]] || classify "$path" "${ent_orig[$path]:-}" \
			"${ent_oldbase[$path]:-}" "${ent_base[$path]:-}" "${ent_head[$path]:-}" "$path" ""
	elif [[ -n "${moved_from[$path]:-}" ]]; then
		continue   # judged under its source, as the identity
	else
		classify "$path" "${ent_orig[$path]:-}" "${ent_oldbase[$path]:-}" \
			"${ent_base[$path]:-}" "${ent_head[$path]:-}" "$path" ""
	fi
done

# --expect is per FINDING and must still be earning its keep: a stale acknowledgement is how a
# blanket override grows one line at a time. A finding is named as printed, or by either name of
# a rename identity — and a name that matches MORE than one finding is refused, naming them: one
# flag silencing two findings, or an old `--expect src` starting to cover a later `src -> dst`, is
# exactly the growth this guards against (round 1, sol).
for e in ${expects[@]+"${expects[@]}"}; do
	hits=()
	for ((i = 0; i < n_f; i++)); do
		[[ -n "${f_kind[i]}" ]] || continue
		if [[ "${f_disp[i]}" == "$e" || "${f_src[i]}" == "$e" || "${f_dst[i]}" == "$e" ]]; then hits+=("$i"); fi
	done
	[[ "${#hits[@]}" -ne 0 ]] || die "--expect '$e' matches no finding; drop it"
	if [[ "${#hits[@]}" -gt 1 ]]; then
		msg="--expect '$e' matches ${#hits[@]} findings; acknowledge one at a time, as printed:"
		# Quoted the way bash would: a label holding a quote or a newline must still paste back.
		for i in "${hits[@]}"; do msg+=$'\n'"  --expect $(printf '%q' "${f_disp[i]}")   (${f_kind[i]})"; done
		die "$msg"
	fi
	f_kind[${hits[0]}]=""
done

# Deterministic order — by label, C collation — without a line-delimited detour: NUL in, NUL out.
# Each record is the label plus a fixed-width index, so two findings with the same label both
# survive and the index is read off the END, whatever the label holds.
findings=()
while IFS= read -r -d '' rec; do
	findings+=("${rec: -8}")
done < <(for ((i = 0; i < n_f; i++)); do [[ -n "${f_kind[i]}" ]] && printf '%s\x01%08d\0' "${f_disp[i]}" "$i"; done | LC_ALL=C sort -z)

n="${#findings[@]}"
if [[ "$n" -eq 0 ]]; then
	say "rebase_scope_check: ${orig_oid:0:8} -> ${head_oid:0:8} onto ${base} — the rebase changed the branch's net effect only where ${base} moved. PASS."
	say "  A pass is bounded: a resolution that merged most of ${base}'s change and dropped one HUNK of it is outside this check."
	exit 0
fi

# An entry for the reader, on the axis the finding is about: the short oid (the empty blob by
# name; the mode beside it when it is not a plain file), or the mode alone, or the word "absent" —
# never an empty pair of parentheses standing in for a file the base does not have.
show() {
	local axis="$1" e="$2" mode oid
	[[ -n "$e" ]] || { printf 'absent'; return; }
	mode="${e%% *}"; oid="${e##* }"
	if [[ "$axis" == mode ]]; then printf 'mode %s' "$mode"
	elif [[ "$oid" == e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 ]]; then printf '%s (empty file)' "${oid:0:8}"
	elif [[ "$mode" == 100644 ]]; then printf '%s' "${oid:0:8}"
	else printf '%s (mode %s)' "${oid:0:8}" "$mode"
	fi
}

echo "rebase_scope_check: ${orig_oid:0:8} -> ${head_oid:0:8} onto ${base} — ${n} file(s) whose net effect the rebase changed beyond absorbing ${base}."
echo "  The resolution lives inside a replayed branch commit, so nothing in the log says this happened."
echo
for i in "${findings[@]}"; do
	i=$((10#$i)); kind="${f_kind[i]}"; axis="${f_axis[i]}"; key="${f_disp[i]}"
	o="$(show "$axis" "${f_o[i]}")"; bo="$(show "$axis" "${f_bo[i]}")"
	bn="$(show "$axis" "${f_bn[i]}")"; h="$(show "$axis" "${f_h[i]}")"
	src="${f_src[i]}"; dst="${f_dst[i]}"
	# One line per finding: a name holding a control character is printed the way bash would
	# quote it ($'...'), so it cannot be mistaken for two.
	disp="$key"; [[ "$key" != *[[:cntrl:]]* ]] || disp="$(printf '%q' "$key")"
	printf '  %-9s %s\n' "$kind" "$disp"
	if [[ -n "$dst" ]]; then
		if [[ "${f_bo[i]##* }" == "${f_bn[i]##* }" ]]; then
			printf '            %s RENAMED %s to %s after this branch forked, without changing it; this\n' "$base" "$src" "$dst"
			printf '            branch'"'"'s result for the file belongs at %s.\n' "$dst"
		else
			printf '            %s RENAMED %s to %s after this branch forked and changed it there; this\n' "$base" "$src" "$dst"
			printf '            branch'"'"'s change to the file belongs at %s.\n' "$dst"
		fi
	fi
	what="its content"; [[ "$axis" == content ]] || { what="its MODE"; printf '            (the file mode; its content is as expected on both sides)\n'; }
	case "$kind" in
		DIVERGED)
			printf '            %s did not change %s, yet the branch'"'"'s result did: %s -> %s.\n' "$base" "$what" "$o" "$h"
			if [[ "${f_h[i]}" == "${f_bn[i]}" && "$axis" == content ]] || [[ "${f_h[i]%% *}" == "${f_bn[i]%% *}" && "$axis" == mode ]]; then
				printf '            The result is %s'"'"'s side whole, so this branch'"'"'s own change (%s -> %s) is absent from it.\n' "$base" "$bo" "$o"
			elif [[ -z "${f_h[i]}" ]]; then
				printf '            The result lacks it altogether.\n'
			fi ;;
		DROPPED)
			printf '            %s has it (%s); the rebased branch does not. The resolution deleted it.\n' "$base" "$bn"
			[[ "$o" == "$bo" ]] || printf '            This branch had changed it too (%s -> %s); the result keeps neither side.\n' "$bo" "$o" ;;
		RESTORED)
			printf '            %s changed it after this branch forked (%s -> %s); the result is %s again, so\n' "$base" "$bo" "$bn" "$bo"
			if [[ "$o" == "$bo" ]]; then
				printf '            %s'"'"'s change was resolved away.\n' "$base"
			else
				printf '            %s'"'"'s change was resolved away — and this branch'"'"'s own (%s -> %s) with it.\n' "$base" "$bo" "$o"
			fi ;;
		KEPT-OURS)
			printf '            both %s and this branch changed it; the result (%s) is this branch'"'"'s pre-rebase\n' "$base" "$h"
			printf '            side unchanged, so %s'"'"'s change (%s -> %s) is absent from it.\n' "$base" "$bo" "$bn" ;;
		LOST-OURS)
			printf '            both %s and this branch changed it; the result (%s) is %s'"'"'s side whole, so this\n' "$base" "$h" "$base"
			printf '            branch'"'"'s own change (%s -> %s) is absent from it.\n' "$bo" "$o" ;;
		NOVEL)
			printf '            this branch never changed it; %s did (%s -> %s), and the result (%s) is content\n' "$base" "$bo" "$bn" "$h"
			printf '            neither side had at this path — created during the rebase, or a rename below\n'
			printf '            git'"'"'s similarity threshold, which is not followed.\n' ;;
		REVERT)
			at="${f_at[i]}"
			printf '            result %s is %s at %s — %s\n' "$h" "$base" "${at:0:8}" \
				"$(git log -1 --format='%ad %s' --date=short "$at" | cut -c1-72)"
			printf '            %s now has %s; this branch does not. Undone in the rebase, or in a\n' "$base" "$bn"
			printf '            commit made after it — run this right after the rebase and it is the rebase.\n'
			[[ "$o" == "$bo" ]] || printf '            This branch'"'"'s own change (%s -> %s) is gone with it.\n' "$bo" "$o" ;;
	esac
done
echo
echo "  Restore the side that left — the finding says which:"
echo "    ${base}'s:            git checkout ${base} -- <path>"
echo "    this branch's:       git checkout ${orig_oid:0:8} -- <path>     (the pre-rebase tip)"
echo "  then commit and say so in the PR body. A merge of both sides is not a finding here."
echo "  Acknowledge a deliberate one: --expect <path>   (one flag per file; either name of a rename)"
exit 1
