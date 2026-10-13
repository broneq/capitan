#!/usr/bin/env bash
# Checks that the current project can be orchestrated by Capitan.
# Prints one line per check and exits non-zero when a required check fails.
set -uo pipefail

failed=0
ok()   { printf 'ok    %s\n' "$1"; }
info() { printf 'info  %s\n' "$1"; }
warn() { printf 'warn  %s\n      fix: %s\n' "$1" "$2"; }
bad()  { printf 'FAIL  %s\n      fix: %s\n' "$1" "$2"; failed=1; }

if [ "${HERDR_ENV:-}" = 1 ]; then
  ok "running inside Herdr"
else
  bad "not running inside Herdr (HERDR_ENV is not 1)" \
    "start herdr, open the project's main checkout in a pane, start claude there and run Capitan again"
fi

if command -v herdr >/dev/null 2>&1; then
  ok "$(herdr --version 2>/dev/null)"
else
  bad "herdr is not on PATH" "install Herdr: https://herdr.dev"
fi

if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
  bad "not inside a git repository" "start Capitan from the project's main checkout"
  exit 1
fi

git_dir=$(git rev-parse --path-format=absolute --git-dir)
common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
if [ "$git_dir" = "$common_dir" ]; then
  ok "main checkout: $root"
else
  bad "this is a linked worktree, not the main checkout" \
    "start Capitan from the main checkout: $(dirname "$common_dir")"
fi

if [ -f "$root/.worktreeinclude" ]; then
  ok ".worktreeinclude found"
  if ! git -C "$root" ls-files --error-unmatch .worktreeinclude >/dev/null 2>&1; then
    warn ".worktreeinclude is not committed" "commit it so every worktree and teammate shares it"
  fi
else
  bad ".worktreeinclude is missing in $root" \
    "create it: list the gitignored files a fresh worktree needs (for example .env.local), one gitignore-style pattern per line. An empty file is valid when nothing must be copied."
fi

if [ -f "$root/.claude/capitan.md" ]; then
  ok "project config: .claude/capitan.md"
else
  info "no .claude/capitan.md, using Capitan defaults"
fi

if base=$(git -C "$root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null); then
  ok "default base: $base"
else
  warn "origin/HEAD is not set, the default base branch is unknown" \
    "git remote set-head origin --auto (or set the base in .claude/capitan.md)"
fi

if [ "$failed" -ne 0 ]; then
  printf '\nCapitan cannot run in this project. Fix the FAIL lines and start Capitan again.\n'
  exit 1
fi
printf '\nready\n'
