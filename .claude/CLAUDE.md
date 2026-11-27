# Capitan plugin

Claude Code plugin with two skills: `capitan` turns a session into a coordinator that opens every task in its own git worktree, Herdr workspace and agent, keeps track of all tasks and closes them out; `delegate` (`/capitan:delegate`) opens tasks in a running Capitan session, with an optional per-task mode.

## Layout

- `.claude-plugin/plugin.json` - plugin manifest. Never edit `version` by hand: release-please owns it.
- The plugin is listed in the `bdk` marketplace (`broneq/bdk`, `.claude-plugin/marketplace.json` on `main` and `staging/v3`), not here.
- `skills/capitan/SKILL.md` - the coordinator: principles and the process (start, open, run, close). Keep it short and about the process; models handle the details.
- `skills/delegate/SKILL.md` - thin entry point that runs Capitan's Open a task. Its `allowed-tools` must cover every command of Open a task: keep them in sync.
- `skills/capitan/references/` - `agent-rules.md` (the agents' standing rules, loaded with `--append-system-prompt-file`: modes, questions, merging, watching, finishing) and `agent-brief.md` (the first prompt).
- `skills/capitan/scripts/preflight.sh` - project readiness check. Worktrees are created by `wt` and `herdr worktree open` commands written in `SKILL.md`, not by scripts.
- `evals/` - `claude plugin eval` suite (see Evals below).
- `examples/` - sample `.claude/capitan.md`, `.worktreeinclude` and `.config/wt.toml` for user projects.
- `.github/workflows/` - `pr.yml` (shellcheck, skill-check, strict plugin validation, commitlint) and `release.yml` (release-please, then fast-forward of the `release` branch to the release tag).

## Rules

- The skill must stay project-agnostic. Anything specific to one project (tracker IDs, ports, setup scripts, gates, merge policy, chat messages) belongs in that project's `.claude/capitan.md`, never in the skill. If you add a new override point, document it in `examples/capitan.md` and the README.
- The workflow must not assume a task source or a deliverable: a task can be anything (code, a report, an analysis). GitHub issues, pull requests, task types and status columns belong to the project's `.claude/capitan.md`.
- Agents start with the settings of the Capitan session (`CLAUDE_CONFIG_DIR`, permission mode, the known launch flags the preflight carries over, model, effort): with another config or permission mode, `SendMessage` between them is held for approval.
- Under auto mode the classifier blocks `SendMessage` the user did not sanction. The brief (a user turn for the agent) therefore says which sessions the agent may message; keep that line when you change the brief.
- Herdr agent names allow only `a-z`, `0-9`, `-`, `_` (up to 32 characters), so agent names are lowercase (`shop-t1`); labels keep the id as is (`T1 ...`).
- Questions never go through Capitan: agents ask the user in their own pane. Do not force a question form; the user's and the project's instructions decide it.
- Skill text is written in plain, imperative English. No em dash, use `-`.
- Scripts: bash, `set -euo pipefail`, compatible with macOS bash 3.2 (no `mapfile`, no associative arrays), must pass `shellcheck`.
- Worktree creation, file copying and per-worktree setup belong to [Worktrunk](https://worktrunk.dev) and the project's `.config/wt.toml` hooks; never add copy, port or setup logic here. The copy must run in a `pre-start` hook (blocking), because Capitan starts the agent as soon as `wt switch` returns. Never pass `--yes` to `wt`: approving project hooks is the user's decision.
- Do not add wrapper scripts around commands the agent can run directly; scripts are only for checks that need many commands (the preflight). Commands the skill runs without a prompt go to `allowed-tools`.
- Do not depend on interactive tools (for example the herdr-worktrunk plugin, an fzf picker): Capitan must drive everything from the CLI.
- Do not depend on other skills (for example `herdr` or `worktrunk`): the skill names every command it needs itself, with the flags it relies on, and falls back to `wt <command> --help` and `herdr <group>`.
- The preflight and Capitan only report what is missing and how to fix it; they never install, configure or approve anything themselves.
- Every `wt` command and flag in the docs must exist in the current Worktrunk CLI (`wt <cmd> --help`).
- Every Herdr command in the docs must exist in the current Herdr CLI (`herdr <group>` without arguments prints the usage; `herdr <group> <cmd> --help` prints only the global help). Never document `herdr workspace close --group`, except as the forbidden trap.

## Commits and releases

- Every commit follows Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` ...). release-please derives the version and `CHANGELOG.md` from them; never edit `CHANGELOG.md`, `.release-please-manifest.json` or the manifest `version` by hand.
- Changes reach `main` only through a pull request with green checks. The only merge method is rebase: a merge commit would repeat the PR title and release-please would list the change twice, and a squash would replace the linted commits with an unlinted PR title.
- A release is the merge of the release PR that release-please opens. The `release` branch then points at the release tag; the `bdk` marketplace installs from it.

## Checks before commit

```bash
shellcheck skills/capitan/scripts/*.sh evals/lib/*.sh evals/*/setup.sh
node <bdk-skill-kit>/dist/skill-check.mjs --strict   # or /bdk-skill-kit:skill-check
npx claude plugin validate . --strict
```

Manual test: inside Herdr, in a scratch git repo with a `.worktreeinclude` and `.config/wt.toml`, run `claude --plugin-dir <this repo>` and invoke the skill. Give it a clear task and an open one (a report), and check that the agent's `finished` message reaches Capitan and the cleanup runs. Also check: a pull request task where the agent watches until merge (the background watch survives `/compact` and a long wait), the agent rules still apply after `/compact`, `-n <name>` is the name `ListAgents` shows, a resumed or compacted Capitan tells the running agents its `ListAgents` name and never `capitan`, and an agent that cannot reach Capitan asks the repo's sessions. Check the modes and delegation: `/capitan` asks for the mode only without a flag or `Mode`, `/capitan:delegate` with two links opens two tasks one after another and its mode flag reaches the brief, `/capitan:delegate` outside a Capitan session stops, and a new worktree starts from `origin/<base>` even when the local base branch is behind. Check the preflight failure path too (no `.worktreeinclude`, no pre-start copy hook, unapproved hooks, `wt` missing, Herdr integration for claude missing, outside Herdr, from a linked worktree).

## Evals

`npm run eval` runs `evals/` with `claude plugin eval`: 8 cases x 3 runs, about 2.50 USD, a few minutes. It is not in CI (cost); run it after changing `SKILL.md` or `references/agent-rules.md`, and before a release. Results go to `evals/results/` (gitignored).

- `capitan-preflight-stops` - outside Herdr the preflight fails, and Capitan stops without doing the task or fixing anything.
- `agent-clear-task-finishes`, `agent-report-asks-first`, `agent-finish-request-confirms`, `agent-open-pr-watches` - the agent rules: when an agent reports its task finished, when it asks first, and that it watches an open pull request instead of finishing.
- `agent-hands-off-finishes-report`, `agent-hands-off-asks-critical` - `hands-off` mode: a delivered report is reported without the finish question, and an undeliverable one still makes the agent ask.
- `agent-finds-capitan` - the brief names a Capitan that does not exist: the agent asks the repo's sessions, ignores a wrong answer and reports to the real Capitan.

The eval sandbox has no `SendMessage` or `AskUserQuestion`, no Herdr, and `git` fails there on macOS. The agent cases therefore replace them with stand-ins (`append_system_prompt`: `../bin/send`, which appends a line to `../outbox.txt`, a final question, the agent rules read from `../capitan/agent-rules.md`) and deliver into `../shared/`. Integration (Herdr, Worktrunk, real `SendMessage`, cleanup) stays in the manual test above. When you change a grader, check that it still fails on a broken protocol, for example with the finish question removed from `agent-rules.md`.
