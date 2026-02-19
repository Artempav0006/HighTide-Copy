#!/usr/bin/env bash
set -euo pipefail

title="CI: Submodule update report"
body_file="reports/submodule_report.md"

# Find existing issue by exact title (if any)
issue_number="$(gh issue list --limit 50 --search "$title in:title" --json number,title \
  --jq ".[] | select(.title==\"$title\") | .number" | head -n 1 || true)"

if [ -z "${issue_number:-}" ]; then
  gh issue create --title "$title" --body-file "$body_file" >/dev/null
  echo "Created issue: $title"
else
  # Update by commenting (keeps history per push)
  gh issue comment "$issue_number" --body-file "$body_file" >/dev/null
  echo "Commented on issue #$issue_number"
fi
