#!/usr/bin/env bash
# Reconcile GitHub issues that track failing Renovate PRs (#43).
#   - Opens a `renovate-failure`-labeled issue for any open `renovate/**` PR
#     whose CI has a failing check. Idempotent: one issue per PR, keyed on a
#     `<!-- renovate-pr-<N> -->` marker in the body.
#   - Closes a tracking issue once its PR is passing / merged / closed.
#
# Self-healing scheduled reconcile — no event plumbing. See
# .github/workflows/renovate-failure-issue.yml.
#
# Usage: renovate-failure-issues.sh <owner/repo>
set -euo pipefail
REPO="${1:?owner/repo}"
LABEL="renovate-failure"

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

# Open renovate/** PRs with their check rollup.
gh pr list -R "$REPO" --state open --limit 200 \
  --json number,title,url,headRefName,statusCheckRollup \
  | jq -c '[.[] | select(.headRefName | startswith("renovate/"))]' > "$work/prs.json"

# A PR is "failing" if any rollup entry concluded badly (pending != failing).
jq -r '
  def bad: ascii_upcase | IN("FAILURE","TIMED_OUT","STARTUP_FAILURE","CANCELLED","ERROR");
  .[] | select([.statusCheckRollup[]? | ((.conclusion // "") | bad) or ((.state // "") | bad)] | any)
      | .number
' "$work/prs.json" | sort -u > "$work/failing.txt"

echo "failing renovate PRs: $(tr '\n' ' ' < "$work/failing.txt")"

# --- 1. Open an issue for each failing PR that isn't already tracked. ---
gh issue list -R "$REPO" --state open --label "$LABEL" --limit 200 --json number,body \
  > "$work/issues.json"

issue_for_pr() {  # $1 = PR number -> tracking issue number, or empty
  jq -r --arg m "<!-- renovate-pr-$1 -->" \
    '[.[] | select((.body // "") | contains($m))][0].number // empty' "$work/issues.json"
}

while read -r pr; do
  [ -n "$pr" ] || continue
  if [ -n "$(issue_for_pr "$pr")" ]; then echo "PR #$pr already tracked"; continue; fi
  prj="$(jq -c --argjson n "$pr" '.[] | select(.number==$n)' "$work/prs.json")"
  title="$(jq -r '.title' <<<"$prj")"
  url="$(jq -r '.url' <<<"$prj")"
  branch="$(jq -r '.headRefName' <<<"$prj")"
  failed="$(jq -r '
    def bad: ascii_upcase | IN("FAILURE","TIMED_OUT","STARTUP_FAILURE","CANCELLED","ERROR");
    [.statusCheckRollup[]? | select(((.conclusion // "") | bad) or ((.state // "") | bad)) | (.name // .context)]
    | unique | join(", ")' <<<"$prj")"
  body="$(printf '<!-- renovate-pr-%s -->\nRenovate PR **#%s** is failing CI.\n\n- PR: %s\n- Branch: `%s`\n- Failing checks: %s\n\n_Auto-opened by `renovate-failure-issue.yml`; closes automatically when the PR passes, merges, or closes._\n' \
    "$pr" "$pr" "$url" "$branch" "${failed:-unknown}")"
  gh issue create -R "$REPO" --label "$LABEL" \
    --title "Renovate CI failing: ${title} (PR #${pr})" --body "$body"
  echo "opened tracking issue for PR #$pr"
done < "$work/failing.txt"

# --- 2. Close tracking issues whose PR is no longer failing. ---
# `jq -c '.[]'` emits one compact line per issue (escaped body), so the marker
# is greppable without multi-line breakage.
jq -c '.[]' "$work/issues.json" | while read -r row; do
  inum="$(jq -r '.number' <<<"$row")"
  pr="$(jq -r '.body // ""' <<<"$row" | grep -oE 'renovate-pr-[0-9]+' | head -1 | grep -oE '[0-9]+' || true)"
  [ -n "$pr" ] || continue
  if grep -qx "$pr" "$work/failing.txt"; then continue; fi   # still failing — keep open
  gh issue close "$inum" -R "$REPO" \
    --comment "Renovate PR #${pr} is no longer failing (passing, merged, or closed) — auto-closing."
  echo "closed issue #$inum (PR #$pr resolved)"
done
