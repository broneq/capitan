#!/usr/bin/env bash
# Checks that the current project can be orchestrated by Capitan.
# Prints one line per check and exits non-zero when a required check fails.
set -uo pipefail

failed=0
ok()   { printf 'ok    %s\n' "$1"; }
warn() { printf 'warn  %s\n      fix: %s\n' "$1" "$2"; }
bad()  { printf 'FAIL  %s\n      fix: %s\n' "$1" "$2"; failed=1; }

# version_at_least <actual> <minimum>, both dotted numbers
version_at_least() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)" = "$2" ]
}

if [ "${HERDR_ENV:-}" = 1 ]; then
  ok "running inside Herdr"
else
  bad "not running inside Herdr (HERDR_ENV is not 1)" \
    "start herdr, open the project's main checkout in a pane, start claude there and run Capitan again"
fi

have_herdr=0
if command -v herdr >/dev/null 2>&1; then
  have_herdr=1
  ok "$(herdr --version 2>/dev/null)"
else
  bad "herdr is not on PATH" "install Herdr: https://herdr.dev"
fi

# Worktrunk creates every worktree and runs the project's hooks in it.
have_wt=0
if command -v wt >/dev/null 2>&1 && wt_version=$(wt --version 2>/dev/null | sed -n 's/^wt v\{0,1\}\([0-9][0-9.]*\).*/\1/p') && [ -n "$wt_version" ]; then
  if version_at_least "$wt_version" 0.60.0; then
    have_wt=1
    ok "worktrunk $wt_version"
  else
    bad "worktrunk $wt_version is too old (0.60.0 or later needed)" "brew upgrade worktrunk"
  fi
else
  bad "worktrunk (wt) is not on PATH" \
    "brew install worktrunk (or cargo install worktrunk); see https://worktrunk.dev"
fi

# The integration reports the agents' state (working, blocked, idle) to Herdr;
# Capitan's monitoring depends on it.
if [ "$have_herdr" = 1 ]; then
  claude_state=$(herdr integration status 2>/dev/null | sed -n 's/^claude: \([a-z][a-z ]*\).*/\1/p' | sed 's/ *$//')
  if [ "$claude_state" = current ]; then
    ok "Herdr integration for claude"
  else
    bad "Herdr integration for claude is ${claude_state:-missing}, so Herdr cannot report the agents' state" \
      "herdr integration install claude"
  fi
fi

if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
  bad "not inside a git repository" "start Capitan from the project's main checkout"
  printf '\nCapitan cannot run in this project. Fix the FAIL lines and start Capitan again.\n'
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
    "create it: list the gitignored files a fresh worktree needs (for example .env.local), one gitignore-style pattern per line"
fi

if [ "$have_wt" = 1 ]; then
  # The copy must run in a blocking pre-start hook: Capitan starts the agent as
  # soon as `wt switch` returns, so a post-start copy would race it.
  if wt -C "$root" hook show pre-start 2>/dev/null | grep -q 'copy-ignored'; then
    ok "worktrunk pre-start hook copies .worktreeinclude files"
  elif wt -C "$root" hook show 2>/dev/null | grep -q 'copy-ignored'; then
    bad "wt step copy-ignored runs in a background hook, so the agent could start before the files are copied" \
      "move it to a pre-start hook in .config/wt.toml"
  else
    bad "no worktrunk hook copies the .worktreeinclude files into new worktrees" \
      "add this to .config/wt.toml and commit it:
        [[pre-start]]
        copy = \"wt step copy-ignored --require-include\""
  fi

  # Project hooks run only after the user approved them; Capitan never passes --yes.
  if wt -C "$root" config approvals list --format=json 2>/dev/null | grep -Eq '"state": *"(approved|no_commands)"'; then
    ok "worktrunk project hooks approved"
  else
    bad "worktrunk project hooks of this repository are not approved yet" \
      "review and approve them: wt -C $root config approvals add"
  fi
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
