# Capitan plugin

Claude Code plugin with one skill, `capitan`: it turns a session into an orchestrator that delegates every task to an agent in its own git worktree and Herdr workspace.

## Layout

- `.claude-plugin/plugin.json` - plugin manifest. Bump `version` on every user-visible change.
- The plugin is listed in the `bdk` marketplace (`broneq/bdk`, `.claude-plugin/marketplace.json` on `main` and `staging/v3`), not here.
- `skills/capitan/SKILL.md` - the orchestrator instructions. Keep it short; details go to `references/`.
- `skills/capitan/references/` - agent prompt template, operations (monitoring, cleanup, recovery).
- `skills/capitan/scripts/` - `preflight.sh` (project readiness) and `copy-worktreeinclude.sh`.
- `examples/` - sample `.claude/capitan.md` and `.worktreeinclude` for user projects.

## Rules

- The skill must stay project-agnostic. Anything specific to one project (tracker IDs, ports, setup scripts, gates, merge policy, chat messages) belongs in that project's `.claude/capitan.md`, never in the skill. If you add a new override point, document it in `examples/capitan.md` and the README.
- Skill text is written in plain, imperative English. No em dash, use `-`.
- Scripts: bash, `set -euo pipefail`, compatible with macOS bash 3.2 (no `mapfile`, no associative arrays), must pass `shellcheck`.
- `copy-worktreeinclude.sh` must keep Claude Code semantics: copy only files that match `.worktreeinclude` AND are gitignored, never overwrite.
- Every Herdr command in the docs must exist in the current Herdr CLI (`herdr <cmd> --help`). Never document `herdr workspace close --group`, except as the forbidden trap.

## Checks before commit

```bash
shellcheck skills/capitan/scripts/*.sh
claude plugin validate .
```

Manual test: inside Herdr, in a scratch git repo with a `.worktreeinclude`, run `claude --plugin-dir <this repo>` and invoke the skill. Check the preflight failure path too (no `.worktreeinclude`, outside Herdr, from a linked worktree).
