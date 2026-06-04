#!/usr/bin/env bash
# Append a changelog entry for each published-image Dockerfile a Renovate PR
# changed, so the required `Require changelog entry for image changes` gate
# passes and the curated changelogs/<image>.md stays current. Option A of #43.
#
# Idempotent: each entry carries a `<!-- renovate-pr-<N> -->` marker, so a
# re-run on the same PR (synchronize) does not duplicate it.
#
# Usage: renovate-changelog.sh <base_ref> <pr_number> <repo> <date>
#   base_ref  : ref to diff against and read prior versions from (e.g. origin/main)
#   pr_number : PR number (idempotency marker + link)
#   repo      : owner/repo, for links
#   date      : YYYY-MM-DD (passed in for determinism/testability)
# Emits `changed=1` (to GITHUB_OUTPUT if set, else stdout) when it modified a file.
set -euo pipefail

BASE_REF="${1:?base_ref}"; PR="${2:?pr_number}"; REPO="${3:?repo}"; DATE="${4:?date}"

declare -A MAP=(
  [tools/lean4-base.Dockerfile]=changelogs/gide-lean4-base.md
  [tools/isabelle-base.Dockerfile]=changelogs/gide-isabelle-base.md
  [tools/z3.Dockerfile]=changelogs/gide-z3.md
  [tools/cvc5.Dockerfile]=changelogs/gide-cvc5.md
  [tools/yices2.Dockerfile]=changelogs/gide-yices2.md
  [tools/dreal.Dockerfile]=changelogs/gide-dreal.md
  [tools/apalache.Dockerfile]=changelogs/gide-apalache.md
)

# Resolve the headline upstream version from a Dockerfile passed on stdin.
# Mirrors how the build workflows derive each image's version tag.
resolve_version() {  # $1 = dockerfile path (selects the rule)
  local df="$1" content; content="$(cat)"
  case "$df" in
    tools/lean4-base.Dockerfile)
      printf '%s\n' "$content" | grep -m1 '^ARG MATHLIB_REV=' | sed 's/^ARG MATHLIB_REV=//' ;;
    tools/isabelle-base.Dockerfile)
      local iv at
      iv="$(printf '%s\n' "$content" | grep -m1 '^ARG ISABELLE_VERSION=' | sed 's/^ARG ISABELLE_VERSION=//')"
      at="$(printf '%s\n' "$content" | grep -m1 '^ARG AFP_DATED_TAG=' | sed 's/^ARG AFP_DATED_TAG=//')"
      [ -n "$iv$at" ] && printf '%s-%s' "$iv" "$at" ;;
    *)
      printf '%s\n' "$content" | grep -m1 -oE '^ARG [A-Z0-9_]+_VERSION=[^ ]+' | sed 's/.*=//' ;;
  esac
}

# Prepend $2 (an entry file) above the first "## [" entry of changelog $1,
# or append if the changelog has no entries yet.
prepend_entry() {  # $1 = changelog file, $2 = entry file
  local cl="$1" ef="$2"
  if grep -qm1 '^## \[' "$cl"; then
    awk 'NR==FNR{e=e $0 ORS; next} !done && /^## \[/{printf "%s\n", e; done=1} {print}' \
      "$ef" "$cl" > "${cl}.tmp" && mv "${cl}.tmp" "$cl"
  else
    { printf '\n'; cat "$ef"; } >> "$cl"
  fi
}

mapfile -t files < <(git diff --name-only "${BASE_REF}...HEAD")
changed=0

for df in "${!MAP[@]}"; do
  printf '%s\n' "${files[@]}" | grep -qxF -- "$df" || continue
  cl="${MAP[$df]}"
  marker="<!-- renovate-pr-${PR} -->"
  if grep -qF -- "$marker" "$cl" 2>/dev/null; then
    echo "  ${cl}: already has marker for #${PR}; skipping"
    continue
  fi

  new_ver="$(resolve_version "$df" < "$df" || true)"
  old_ver="$(git show "${BASE_REF}:${df}" 2>/dev/null | resolve_version "$df" 2>/dev/null || true)"

  if [ -n "$new_ver" ] && [ "$new_ver" != "$old_ver" ]; then
    ver="$new_ver"
    body="Bumped to \`${new_ver}\`${old_ver:+ (from \`${old_ver}\`)} via Renovate (#${PR})."
  else
    ver="${new_ver:-${old_ver:-unreleased}}"
    body="Base image / digest refresh via Renovate (#${PR}) — no upstream version change."
  fi

  ef="$(mktemp)"
  rel_tag="$(basename "$cl" .md)-${ver}"
  {
    echo "${marker}"
    echo "## [${ver}] — ${DATE}"
    echo "**Digest:** _published on merge — see GitHub Release \`${rel_tag}\`._"
    echo ""
    echo "### Composition (this repo)"
    echo "- ${body} Upstream release notes are in PR #${PR}; the published digest + provenance land in the GitHub Release on merge."
    echo ""
  } > "$ef"

  prepend_entry "$cl" "$ef"
  echo "  ${cl}: appended entry for ${ver}"
  changed=1
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "changed=${changed}" >> "$GITHUB_OUTPUT"; fi
echo "changed=${changed}"
