# Capitan

A Claude Code plugin that turns your session into a coordinator: it does not do the work, it delegates. Every task (a code change, a report, an analysis, anything) gets an id, its own git worktree, its own [Herdr](https://herdr.dev) workspace and its own Claude Code agent, started with the settings of your session. Capitan opens tasks, knows what runs where, warns about overlapping tasks, passes information between them, and closes them out when they are done. Agents work autonomously: they ask you directly in their Herdr pane, watch their pull request until it is merged, and then report to Capitan.

```
you ── Capitan (main checkout)
         ├── shop-123   ../shop.fix/123-login-timeout   Herdr workspace "123 Fix login timeout"
         ├── shop-124   ../shop.feat/124-csv-export     Herdr workspace "124 Export CSV"
         └── shop-t1    ../shop.q3-report               Herdr workspace "T1 Q3 usage report"
```

## Requirements

Capitan has no worktree logic of its own. It builds on [Worktrunk](https://worktrunk.dev), which creates the worktrees and runs your project's hooks, and on Herdr, which hosts the agents.

| Tool | Why | Install |
| --- | --- | --- |
| Claude Code with messaging between sessions (`ListAgents`, `SendMessage`) | agents report a finished task to Capitan; agents run in the same permission mode as Capitan, otherwise these messages wait for approval | - |
| [Herdr](https://herdr.dev) | workspaces and agent sessions; start Claude Code inside a Herdr pane (`HERDR_ENV=1`) | see herdr.dev |
| [Worktrunk](https://worktrunk.dev) 0.60+ | creates worktrees, runs the project's `.config/wt.toml` hooks | `brew install worktrunk` or `cargo install worktrunk` |
| Herdr integration for Claude Code | reports each agent's state (working, blocked, idle) to Herdr; Capitan monitors with it | `herdr integration install claude` |

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

## Where worktrees live

Worktrunk decides, Capitan uses the path it returns. By default a worktree is a sibling of the main checkout (`../shop.login-timeout`). Change it in your Worktrunk user config, `~/.config/worktrunk/config.toml`, for all repositories or per repository (`wt config show` prints the repository's identifier). It is a personal setting, so Worktrunk ignores it in the project's `.config/wt.toml`.

```toml
# all repositories: ~/worktrees/shop/login-timeout
worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"

# one repository: inside it, at .worktrees/login-timeout (add .worktrees/ to .gitignore)
[projects."github.com/acme/shop"]
worktree-path = ".worktrees/{{ branch | sanitize }}"
```

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

First Capitan runs a preflight. If the project is not ready (not in Herdr, Worktrunk or the Herdr integration missing, no `.worktreeinclude`, no copy hook, hooks not approved, started from a worktree) it lists what to fix and stops. It never fixes anything itself. Otherwise it waits for tasks. For each task:

1. Capitan gives it an id (the tracker number, or `T1`, `T2`...), warns when it overlaps a running task, and claims the tracker item (assigns you, sets it in progress) as `.claude/capitan.md` says.
2. It creates the worktree with `wt switch --create`, which runs your `pre-start` hooks (copy, ports, installs), and opens it in Herdr under the main checkout, labelled `<id> <short title>`, one setup at a time.
3. It starts `claude` there with your session's settings (`CLAUDE_CONFIG_DIR`, permission mode, plugin dirs, model, effort) plus the agent rules in the system prompt, and sends the task.
4. The agent works on its own. It asks you in its pane (Herdr shows which agent needs you), never Capitan. While it waits on checks, review or merge, it runs a background watch and reacts to every change. With no merge policy it merges once all checks are green and no review requests changes.
5. When the task is done (delivered, merged if there is a pull request, nothing open) the agent sends Capitan `finished`. For a report or analysis it first asks you "Is the task finished? The worktree will be removed." Capitan verifies, closes the tracker item, closes the workspace, runs `wt remove` with your `pre-remove`/`post-remove` hooks, and offers the next tasks. Worktrunk refuses to remove uncommitted work and keeps unmerged branches.

If Capitan's session is resumed under a new name, it tells every running agent; an agent that cannot reach Capitan asks the other agents of the repo who Capitan is.

Capitan never answers agents' questions for you, never approves Worktrunk hooks for you (no `--yes`), never closes workspaces it did not create and never runs `herdr workspace close --group`.

## Per-project config

Capitan works with defaults. To give it extra instructions for a project, add `.claude/capitan.md`, in plain words. For example:

| Section | Example | Default |
| --- | --- | --- |
| Tracker | GitHub issues, Jira, anything: which items are ready, how to claim (assign, in progress) and close them | tracker items are not updated |
| Branches | `<type>/<issue>-<slug>`, base `origin/develop` | the project's convention, else a slug from `origin/HEAD` |
| Merge | merge method, required reviews, when agents merge | merge when all checks are green and no review requests changes; never auto-merge; no merge without checks |
| Watch | the command agents poll while they wait (for example `gh pr view`) | the agent writes one |
| Agents | notes for every agent (how to present questions and results, a Slack draft), model or extra flags | your session's settings |

Commit the file: agents read it in their own worktrees.

Worktree setup and teardown do not belong here: they are Worktrunk hooks in `.config/wt.toml`. Quality gates come from the project's `CLAUDE.md` and rules.

See [examples/capitan.md](examples/capitan.md), [examples/.worktreeinclude](examples/.worktreeinclude) and [examples/wt.toml](examples/wt.toml).

## How it is built

- [skills/capitan/SKILL.md](skills/capitan/SKILL.md) - the coordinator: principles, start, open, run, close.
- [skills/capitan/references/agent-rules.md](skills/capitan/references/agent-rules.md) - the agents' standing rules, loaded into their system prompt: questions, merging, watching, finishing.
- [skills/capitan/references/agent-brief.md](skills/capitan/references/agent-brief.md) - the first prompt sent to each agent.
- [skills/capitan/scripts/preflight.sh](skills/capitan/scripts/preflight.sh) - project readiness check; prints the flags agents start with.

## Development

```bash
npm ci
shellcheck skills/capitan/scripts/*.sh evals/lib/*.sh evals/*/setup.sh
npx claude plugin validate . --strict
npm run eval                 # behaviour evals in evals/, about 1.30 USD per run
claude --plugin-dir .        # inside a Herdr pane, in a test repo
```

The skill is also checked by `skill-check` from [bdk-skill-kit](https://github.com/broneq/bdk) (`/bdk-skill-kit:skill-check`). Commits follow Conventional Commits; releases are cut by release-please, and the marketplace installs the `release` branch.
