# Capitan plugin

Claude Code plugin with one skill, `capitan`: it turns a session into an orchestrator that delegates every task to an agent in its own git worktree and Herdr workspace.

## Layout

- `.claude-plugin/plugin.json` - plugin manifest. Never edit `version` by hand: release-please owns it.
- The plugin is listed in the `bdk` marketplace (`broneq/bdk`, `.claude-plugin/marketplace.json` on `main` and `staging/v3`), not here.
- `skills/capitan/SKILL.md` - the orchestrator instructions. Keep it short; details go to `references/`.
- `skills/capitan/references/` - agent prompt template, operations (monitoring, cleanup, recovery).
- `skills/capitan/scripts/preflight.sh` - project readiness check. Worktrees are created by `wt` and `herdr worktree open` commands written in `SKILL.md`, not by scripts.
- `examples/` - sample `.claude/capitan.md`, `.worktreeinclude` and `.config/wt.toml` for user projects.
- `.github/workflows/` - `pr.yml` (shellcheck, skill-check, strict plugin validation, commitlint) and `release.yml` (release-please, then fast-forward of the `release` branch to the release tag).

## Rules

- The skill must stay project-agnostic. Anything specific to one project (tracker IDs, ports, setup scripts, gates, merge policy, chat messages) belongs in that project's `.claude/capitan.md`, never in the skill. If you add a new override point, document it in `examples/capitan.md` and the README.
- The workflow must not assume a task source or a deliverable: a task can be anything (code, a report, an analysis). GitHub issues, pull requests, task types and status columns belong to the project's `.claude/capitan.md`.
- Agents start with exactly the settings of the Capitan session (`CLAUDE_CONFIG_DIR`, launch flags, model, effort): without the same config and permission mode, `SendMessage` from an agent does not reach Capitan.
- Skill text is written in plain, imperative English. No em dash, use `-`.
- Scripts: bash, `set -euo pipefail`, compatible with macOS bash 3.2 (no `mapfile`, no associative arrays), must pass `shellcheck`.
- Worktree creation, file copying and per-worktree setup belong to [Worktrunk](https://worktrunk.dev) and the project's `.config/wt.toml` hooks; never add copy, port or setup logic here. The copy must run in a `pre-start` hook (blocking), because Capitan starts the agent as soon as `wt switch` returns. Never pass `--yes` to `wt`: approving project hooks is the user's decision.
- Do not add wrapper scripts around commands the agent can run directly; scripts are only for checks that need many commands (the preflight). Commands the skill runs without a prompt go to `allowed-tools`.
- Do not depend on interactive tools (for example the herdr-worktrunk plugin, an fzf picker): Capitan must drive everything from the CLI.
- Do not depend on other skills (for example `herdr` or `worktrunk`): the skill names every command it needs itself, with the flags it relies on, and falls back to `<tool> <command> --help`.
- The preflight and Capitan only report what is missing and how to fix it; they never install, configure or approve anything themselves.
- Every `wt` command and flag in the docs must exist in the current Worktrunk CLI (`wt <cmd> --help`).
- Every Herdr command in the docs must exist in the current Herdr CLI (`herdr <cmd> --help`). Never document `herdr workspace close --group`, except as the forbidden trap.

## Commits and releases

- Every commit follows Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` ...). release-please derives the version and `CHANGELOG.md` from them; never edit `CHANGELOG.md`, `.release-please-manifest.json` or the manifest `version` by hand.
- Changes reach `main` only through a pull request with green checks. The only merge method is rebase: a merge commit would repeat the PR title and release-please would list the change twice, and a squash would replace the linted commits with an unlinted PR title.
- A release is the merge of the release PR that release-please opens. The `release` branch then points at the release tag; the `bdk` marketplace installs from it.

## Checks before commit

```bash
shellcheck skills/capitan/scripts/*.sh
node <bdk-skill-kit>/dist/skill-check.mjs --strict   # or /bdk-skill-kit:skill-check
npx claude plugin validate . --strict
```

Manual test: inside Herdr, in a scratch git repo with a `.worktreeinclude` and `.config/wt.toml`, run `claude --plugin-dir <this repo>` and invoke the skill. Give it a task, confirm the end in the agent's pane and check that the agent's `finished` message reaches Capitan and the cleanup runs. Check the preflight failure path too (no `.worktreeinclude`, no pre-start copy hook, unapproved hooks, `wt` missing, Herdr integration for claude missing, outside Herdr, from a linked worktree).
