# Capitan

A Claude Code plugin that turns your session into a captain: it does not write code, it delegates. Every task (issue, bug, feature, chore) gets its own git worktree, its own [Herdr](https://herdr.dev) workspace and its own agent session. Capitan creates them, sends the task, watches progress, relays the agents' questions to you, reports results and cleans up after merge.

```
you ── Capitan (main checkout)
         ├── task-123   ../shop.bugfix-123-login     Herdr workspace "123 Fix login"
         ├── task-130   ../shop.feature-130-csv      Herdr workspace "130 Export CSV"
         └── task-cache ../shop.chore-cache-decision Herdr workspace "cache Decide caching"
```

## Requirements

Capitan has no worktree logic of its own. It builds on [Worktrunk](https://worktrunk.dev), which creates the worktrees and runs your project's hooks, and on Herdr, which hosts the agents.

| Tool | Why | Install |
| --- | --- | --- |
| [Herdr](https://herdr.dev) | workspaces and agent sessions; start Claude Code inside a Herdr pane (`HERDR_ENV=1`) | see herdr.dev |
| [Worktrunk](https://worktrunk.dev) 0.60+ | creates worktrees, runs the project's `.config/wt.toml` hooks | `brew install worktrunk` or `cargo install worktrunk` |
| Herdr integration for Claude Code | reports each agent's state (working, blocked, idle) to Herdr; Capitan monitors with it | `herdr integration install claude` |
| `gh` | only if your tasks are GitHub issues | `brew install gh` |

In the project:

- A git repository, with Capitan started from its main checkout (not from a linked worktree).
- A `.worktreeinclude` file in the repository root: the gitignored files a new worktree needs (`.env.local` and similar), in gitignore syntax. It is the same file Claude Code uses for its own worktrees. An empty file is valid.
- A `.config/wt.toml` with a `pre-start` hook that copies those files. `pre-start` blocks, so the agent never starts before the files are there:
  ```toml
  [[pre-start]]
  copy = "wt step copy-ignored --require-include"
  ```
- The project hooks approved once by you: `wt config approvals add`. Capitan never approves them for you.

Remove task worktrees through Capitan or `wt remove`, not with Herdr's own worktree remove: Herdr does not know Worktrunk, so it leaves the branch and skips your `pre-remove` and `post-remove` hooks. Closing a workspace is safe, it deletes nothing.

The preflight checks all of this and prints the exact fix for anything missing. It never fixes anything itself.

For your own manual work on the same worktrees inside Herdr, the [herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk) plugin gives you a Worktrunk picker. Capitan does not need it.

## Per-worktree environment

Ports, databases, containers and dependency installs go into `.config/wt.toml` too, so every worktree, whether Capitan or you created it, gets the same setup. For example a unique port per branch (`{{ branch | hash_port }}` is stable and in 10000-19999), a separate docker compose project, and teardown when the worktree is removed:

```toml
[[pre-start]]
port = "echo PORT={{ branch | hash_port }} >> .env.local"

[[pre-start]]
deps = "npm ci"

[[pre-remove]]
compose = "docker compose -p {{ repo }}-{{ branch | sanitize }} down -v"
```

See [examples/wt.toml](examples/wt.toml) and the [Worktrunk hook docs](https://worktrunk.dev).

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

First Capitan runs a preflight. If the project is not ready (not in Herdr, Worktrunk or the Herdr integration missing, no `.worktreeinclude`, no copy hook, hooks not approved, started from a worktree) it lists what to fix and stops. Otherwise it waits for tasks. For each task it:

1. reads it and classifies it as `Bug`, `Feature` or `Decision`,
2. creates a worktree with `wt switch --create`, which runs your `pre-start` hooks (copy, ports, installs), and opens it in Herdr grouped under the main checkout, one worktree at a time,
3. starts an agent (`claude` on the most capable model by default) in the new workspace and sends it a task prompt,
4. monitors it, relays questions, and on request reports a status table of all tasks,
5. after the PR is merged, closes the workspace and runs `wt remove` (with your `pre-remove`/`post-remove` hooks), but only when nothing is left unpushed.

Capitan never answers agents' questions for you, never approves Worktrunk hooks for you (no `--yes`), never closes workspaces it did not create and never runs `herdr workspace close --group`.

## Per-project config

Capitan works with defaults. To fit a project, add `.claude/capitan.md`. Each section overrides a default:

| Section | What it controls | Default |
| --- | --- | --- |
| Tasks | where tasks come from, how to claim them (assignee, board status), type mapping | GitHub issue or free text, no claiming |
| Worktree | branch naming, base, extra setup after the Worktrunk hooks | `<type>/<id>-<slug>`, `origin/HEAD`, none |
| Agent | agent kind and arguments | `claude` on the most capable model |
| Prompt | extras for the agent prompt per task type | generic Bug / Feature / Decision flow |
| Gates | typecheck, lint, tests | taken from the project's CLAUDE.md and rules |
| Delivery | PR rules, labels, merge policy | open a PR, never merge |
| Report | final report format (for example a Slack draft) | short summary with PR link |
| Cleanup | extra cleanup steps | none |

See [examples/capitan.md](examples/capitan.md), [examples/.worktreeinclude](examples/.worktreeinclude) and [examples/wt.toml](examples/wt.toml).

## How it is built

- [skills/capitan/SKILL.md](skills/capitan/SKILL.md) - the orchestrator role and the new-task procedure.
- [skills/capitan/references/agent-prompt.md](skills/capitan/references/agent-prompt.md) - the prompt template sent to each agent.
- [skills/capitan/references/operations.md](skills/capitan/references/operations.md) - monitoring, status, cleanup, recovery.
- [skills/capitan/scripts/preflight.sh](skills/capitan/scripts/preflight.sh) - project readiness check.

## Development

```bash
npm ci
shellcheck skills/capitan/scripts/*.sh
npx claude plugin validate . --strict
claude --plugin-dir .        # inside a Herdr pane, in a test repo
```

The skill is also checked by `skill-check` from [bdk-skill-kit](https://github.com/broneq/bdk) (`/bdk-skill-kit:skill-check`). Commits follow Conventional Commits; releases are cut by release-please, and the marketplace installs the `release` branch.
