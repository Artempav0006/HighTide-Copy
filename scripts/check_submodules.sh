#!/usr/bin/env bash
set -euo pipefail

mkdir -p reports

report="reports/submodule_report.md"
echo "# Submodule update report" > "$report"
echo "" >> "$report"
echo "Commit: \`$GITHUB_SHA\`" >> "$report"
echo "Repo: \`$GITHUB_REPOSITORY\`" >> "$report"
echo "Run: \`$GITHUB_RUN_ID\`" >> "$report"
echo "" >> "$report"

echo "## Submodules" >> "$report"
echo "" >> "$report"
echo "| Submodule | Pinned | Pinned date (UTC) | Upstream | Upstream date (UTC) | Status |" >> "$report"
echo "|---|---:|---:|---:|---:|---|" >> "$report"

# List submodules from git
git submodule status --recursive | while read -r line; do
  # line format:  <sha> <path> (optional stuff)
  sha="$(echo "$line" | awk '{print $1}' | sed 's/^-//')"
  path="$(echo "$line" | awk '{print $2}')"

  # If submodule folder isn't present, skip
  if [ ! -d "$path/.git" ] && [ ! -f "$path/.git" ]; then
    echo "| $path | $sha | ? | missing checkout |" >> "$report"
    continue
  fi

  # Fetch upstream
  git -C "$path" fetch --all --tags --prune >/dev/null 2>&1 || true

  # Determine upstream default branch HEAD (best effort)
  upstream_ref=""
  if git -C "$path" show-ref --verify --quiet refs/remotes/origin/HEAD; then
    upstream_ref="$(git -C "$path" symbolic-ref refs/remotes/origin/HEAD)"
    upstream_ref="${upstream_ref#refs/remotes/}"
  elif git -C "$path" show-ref --verify --quiet refs/remotes/origin/master; then
    upstream_ref="origin/master"
  elif git -C "$path" show-ref --verify --quiet refs/remotes/origin/main; then
    upstream_ref="origin/main"
  fi

  if [ -z "$upstream_ref" ]; then
    echo "| $path | $sha | ? | cannot detect upstream |" >> "$report"
    continue
  fi

  upstream_sha="$(git -C "$path" rev-parse "$upstream_ref")"
  pinned_date="$(git -C "$path" show -s --date=format:'%Y-%m-%d %H:%M:%S' --format='%cd' "$sha" 2>/dev/null || echo "?")"
  upstream_date="$(git -C "$path" show -s --date=format:'%Y-%m-%d %H:%M:%S' --format='%cd' "$upstream_sha" 2>/dev/null || echo "?")"

  status="up-to-date"
  if [ "$sha" != "$upstream_sha" ]; then
    # check if pinned is behind upstream
    if git -C "$path" merge-base --is-ancestor "$sha" "$upstream_sha"; then
      status="BEHIND (update available)"
    else
      status="DIVERGED (manual check)"
    fi
  fi

  echo "| $path | \`$sha\` | $pinned_date | \`$upstream_sha\` | $upstream_date | $status |" >> "$report"
done

echo "" >> "$report"
