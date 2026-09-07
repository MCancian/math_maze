#!/usr/bin/env bash
# Protect `main` on MCancian/math_maze: PR required, no force-push, no deletion. Idempotent PUT.
#
# Usage: tools/protect_main.sh [--yes]
#   without --yes: print the payload and the command, do nothing.
#   with --yes:    run the one `gh api -X PUT` call.
#
# `required_approving_review_count: 0` on purpose — reviewers are CLIs, not GitHub accounts; the
# merge gate is `revue clearance --check` (stage-1 coverage, plus a stage-2 MERGE on
# `risk-bearing`), not GitHub. enforce_admins false so the solo maintainer can fix a broken main.
# No status checks: the gate runs locally.
set -euo pipefail

REPO="MCancian/math_maze"
BRANCH="main"
ENDPOINT="repos/$REPO/branches/$BRANCH/protection"
PAYLOAD='{
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "enforce_admins": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_status_checks": null,
  "restrictions": null
}'

yes=0
case "${1:-}" in
	"")        ;;
	--yes)     yes=1 ;;
	-h|--help) sed -n "2,$(($(grep -n '^set -euo pipefail' "$0" | head -1 | cut -d: -f1) - 1))p" "$0" | cut -c3-; exit 0 ;;
	*)         echo "protect_main: unknown argument '$1'" >&2; exit 2 ;;
esac

echo "Will PUT $ENDPOINT with:"
echo "$PAYLOAD"
echo "Command: gh api -X PUT $ENDPOINT --input -"
if [[ "$yes" -eq 0 ]]; then
	echo
	echo "DRY RUN — nothing sent. Re-run with --yes to apply."
	exit 0
fi
command -v gh >/dev/null 2>&1 || { echo "protect_main: gh CLI not on PATH" >&2; exit 2; }
printf '%s' "$PAYLOAD" | gh api -X PUT "$ENDPOINT" --input - >/dev/null
echo "Applied. Verify: gh api $ENDPOINT"
