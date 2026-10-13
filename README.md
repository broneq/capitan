# Capitan

A Claude Code plugin that turns your session into a captain: it does not write code, it delegates. Every task (issue, bug, feature, chore) gets its own git worktree, its own [Herdr](https://herdr.dev) workspace and its own agent session. Capitan creates them, sends the task, watches progress, relays the agents' questions to you, reports results and cleans up after merge.

```
you ── Capitan (main checkout)
         ├── task-123  worktree ../repo-123   Herdr workspace "123 Fix login"
         ├── task-130  worktree ../repo-130   Herdr workspace "130 Export CSV"
         └── task-cache worktree ../repo-cache Herdr workspace "cache Decide caching"
```

## Requirements

- [Herdr](https://herdr.dev), with Claude Code started inside a Herdr pane (`HERDR_ENV=1`).
- A git repository, Capitan started from its main checkout (not from a linked worktree).
- A `.worktreeinclude` file in the repository root. This is the opt-in: it lists the gitignored files a new worktree needs (`.env.local` and similar), in gitignore syntax. It is the same file Claude Code uses for its own worktrees. An empty file is valid.
- `gh` if your tasks are GitHub issues.

## Install

```
/plugin marketplace add broneq/bdk
/plugin install capitan@bdk
```

## Usage

```
/capitan                     # enter orchestration mode
/capitan 123                 # enter and start issue #123 right away
/capitan fix the flaky login test
```

(`/capitan:capitan` works too.)

First Capitan runs a preflight. If the project is not ready (not in Herdr, no `.worktreeinclude`, started from a worktree) it lists what to fix and stops. Otherwise it waits for tasks. For each task it:

1. reads it and classifies it as `Bug`, `Feature` or `Decision`,
2. creates a worktree with `herdr worktree create` (grouped under the main checkout in Herdr),
3. copies the `.worktreeinclude` files and runs your project setup, one setup at a time,
4. starts an agent (`claude` on the most capable model by default) in the new workspace and sends it a task prompt,
5. monitors it, relays questions, and on request reports a status table of all tasks,
6. after the PR is merged, closes the workspace and removes the worktree and branch, but only when nothing is left unpushed.

Capitan never answers agents' questions for you, never closes workspaces it did not create and never runs `herdr workspace close --group`.

## Per-project config

Capitan works with defaults. To fit a project, add `.claude/capitan.md`. Each section overrides a default:

| Section | What it controls | Default |
| --- | --- | --- |
| Tasks | where tasks come from, how to claim them (assignee, board status), type mapping | GitHub issue or free text, no claiming |
| Worktree | branch and path naming, base, setup command | `<type>/<id>-<slug>`, `../<repo>-<id>`, `origin/HEAD`, no setup |
| Agent | agent kind and arguments | `claude` on the most capable model |
| Prompt | extras for the agent prompt per task type | generic Bug / Feature / Decision flow |
| Gates | typecheck, lint, tests | taken from the project's CLAUDE.md and rules |
| Delivery | PR rules, labels, merge policy | open a PR, never merge |
| Report | final report format (for example a Slack draft) | short summary with PR link |
| Cleanup | extra cleanup steps | none |

See [examples/capitan.md](examples/capitan.md) and [examples/.worktreeinclude](examples/.worktreeinclude).

## How it is built

- [skills/capitan/SKILL.md](skills/capitan/SKILL.md) - the orchestrator role and the new-task procedure.
- [skills/capitan/references/agent-prompt.md](skills/capitan/references/agent-prompt.md) - the prompt template sent to each agent.
- [skills/capitan/references/operations.md](skills/capitan/references/operations.md) - monitoring, status, cleanup, recovery.
- [skills/capitan/scripts/preflight.sh](skills/capitan/scripts/preflight.sh) - project readiness check.
- [skills/capitan/scripts/copy-worktreeinclude.sh](skills/capitan/scripts/copy-worktreeinclude.sh) - copies files that match `.worktreeinclude` and are gitignored, same rule as Claude Code. Needed because `herdr worktree create` does not read `.worktreeinclude`.

## Development

```bash
npm ci
shellcheck skills/capitan/scripts/*.sh
npx claude plugin validate . --strict
claude --plugin-dir .        # inside a Herdr pane, in a test repo
```

The skill is also checked by `skill-check` from [bdk-skill-kit](https://github.com/broneq/bdk) (`/bdk-skill-kit:skill-check`). Commits follow Conventional Commits; releases are cut by release-please, and the marketplace installs the `release` branch.
