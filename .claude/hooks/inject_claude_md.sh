#!/usr/bin/env bash
set -euo pipefail
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
file="$proj/CLAUDE.md"
[ -f "$file" ] || exit 0
printf "\n### INSTRUCTIONS (from %s)\n\n" "$file"
cat "$file"
printf "\n"
if grep -q '{{' "$file" 2>/dev/null; then
  printf "\nNOTICE: This project has not been initialized ({{PLACEHOLDER}} values remain in CLAUDE.md).\n"
  printf "Run /init [describe what you want to build] to complete setup, or see SETUP.md.\n\n"
fi
