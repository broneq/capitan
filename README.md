# Capitan

A Claude Code plugin that turns your session into a captain: it does not do the work, it delegates. Every task (a code change, a report, an analysis, anything) gets its own git worktree, its own [Herdr](https://herdr.dev) workspace and its own Claude Code agent, started with exactly the settings of your session. Capitan creates them, sends the task, watches progress, and cleans up when an agent reports its task finished.

```
you ── Capitan (main checkout)
         ├── task-login-timeout  ../shop.login-timeout   Herdr workspace "Fix login timeout"
         ├── task-csv-export     ../shop.csv-export      Herdr workspace "Export CSV"
         └── task-q3-report      ../shop.q3-report       Herdr workspace "Q3 usage report"
```

## Requirements

Capitan has no worktree logic of its own. It builds on [Worktrunk](https://worktrunk.dev), which creates the worktrees and runs your project's hooks, and on Herdr, which hosts the agents.

| Tool | Why | Install |
| --- | --- | --- |
| Claude Code with messaging between sessions (`ListAgents`, `SendMessage`) | agents report a finished task to Capitan | - |
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
/capitan fix the flaky login test   # enter and start a task right away
/capitan prepare a report of last month's errors
```

(`/capitan:capitan` works too.)

First Capitan runs a preflight. If the project is not ready (not in Herdr, Worktrunk or the Herdr integration missing, no `.worktreeinclude`, no copy hook, hooks not approved, started from a worktree) it lists what to fix and stops. It never fixes anything itself. Otherwise it waits for tasks. For each task it:

1. creates a worktree with `wt switch --create`, which runs your `pre-start` hooks (copy, ports, installs), and opens it in Herdr grouped under the main checkout, one worktree at a time,
2. starts `claude` there with your session's exact settings (same `CLAUDE_CONFIG_DIR`, launch flags, permission mode, model and effort) and sends it the task,
3. monitors it and relays questions; you talk to the agent directly in its pane,
4. when the task is finished, the agent messages Capitan, which closes the workspace and runs `wt remove` with your `pre-remove`/`post-remove` hooks. The agent sends that message on its own when the task is clearly done; it asks you first when it is unsure (for example a report you will want to read) and when you tell it to finish, so nothing closes by accident. Worktrunk refuses to remove uncommitted work and keeps unmerged branches.

Capitan never answers agents' questions for you, never approves Worktrunk hooks for you (no `--yes`), never closes workspaces it did not create and never runs `herdr workspace close --group`.

## Per-project config

Capitan works with defaults. To give it extra instructions for a project, add `.claude/capitan.md`, in plain words. For example:

| Topic | Example | Default |
| --- | --- | --- |
| Tasks | tasks are GitHub issues; assign them and move them on the board when started | the request as you give it |
| Branches | `<type>/<issue>-<slug>`, base `origin/develop` | the project's convention, else `<slug>` from `origin/HEAD` |
| Agent | a different model or extra flags | your session's settings |
| Prompt | extras for every agent prompt | the request, the worktree context and the reporting protocol |
| Delivery | PR rules, labels, merge policy | as the project's rules say, never merge |
| Report | the format of the result (for example a Slack draft) | a short summary with links |
| Status | extra columns (PR, issue, port) | agent and worktree state |

Worktree setup and teardown do not belong here: they are Worktrunk hooks in `.config/wt.toml`. Quality gates come from the project's `CLAUDE.md` and rules.

See [examples/capitan.md](examples/capitan.md), [examples/.worktreeinclude](examples/.worktreeinclude) and [examples/wt.toml](examples/wt.toml).

## How it is built

- [skills/capitan/SKILL.md](skills/capitan/SKILL.md) - the orchestrator role and the new-task procedure.
- [skills/capitan/references/agent-prompt.md](skills/capitan/references/agent-prompt.md) - the prompt template sent to each agent.
- [skills/capitan/references/agent-protocol.md](skills/capitan/references/agent-protocol.md) - the rules every agent reads: questions, delivery, and when to report its task finished.
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
