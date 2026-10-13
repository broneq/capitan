#!/usr/bin/env bash
# Copies the files listed in .worktreeinclude from the main checkout into a worktree.
# Same rule as Claude Code: a file is copied only when it matches a .worktreeinclude
# pattern AND is gitignored. Existing files in the worktree are never overwritten.
#
# usage: copy-worktreeinclude.sh <main checkout> <worktree path>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <main checkout> <worktree path>" >&2
  exit 2
fi

main=$(git -C "$1" rev-parse --show-toplevel)
worktree=$2
include="$main/.worktreeinclude"

[ -f "$include" ] || { echo "error: $include does not exist" >&2; exit 1; }
[ -d "$worktree" ] || { echo "error: worktree $worktree does not exist" >&2; exit 1; }

copied=0
skipped=0
while IFS= read -r -d '' path; do
  if [ -e "$worktree/$path" ] || [ -L "$worktree/$path" ]; then
    skipped=$((skipped + 1))
    continue
  fi
  mkdir -p "$worktree/$(dirname "$path")"
  cp -Pp "$main/$path" "$worktree/$path"
  copied=$((copied + 1))
done < <(
  git -C "$main" ls-files -z --others --ignored --exclude-from="$include" \
    | git -C "$main" check-ignore -z --stdin || true
)

echo "copied $copied, kept $skipped existing: $worktree"
