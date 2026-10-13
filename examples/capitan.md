# Capitan config

<!--
Example of .claude/capitan.md. Copy it to your project and keep only the sections you need.
Every section overrides the matching Capitan default. Missing sections use the defaults.
Plain instructions are enough: Capitan reads this file as rules, not as a strict schema.
-->

## Tasks

- Tasks are GitHub issues in `acme/shop`.
- Claim a task: `gh issue edit <nr> --repo acme/shop --add-assignee @me`, then move it to "In progress" on project board 7 (`gh project item-edit ...`). Verify with `gh issue view <nr> --json assignees,projectItems`. If the issue is not on the board, tell me.
- Issue type comes from the `type` field (`Bug`, `Feature`, `Task`). Treat `Task` as `Bug` when it describes wrong behaviour, otherwise as `Feature`.

## Worktree

- branch: `<bugfix|feature|chore>/<nr>-<slug>`
- base: `origin/main`
- setup lives in `.config/wt.toml` (Worktrunk hooks: copy, `npm ci`, a port from `{{ branch | hash_port }}`). Extra step after it, if any:
  ```bash
  ./scripts/seed-dev-db.sh
  ```
- Report the dev server port (`grep ^PORT= .env.local | tail -1` in the worktree) in every status table.

## Agent

- kind: `claude`, args: `--model opus`

## Prompt

- Common part: mention the dev server port from the worktree's `.env.local`.
- Bug: E2E tests follow `.claude/rules/e2e-testing.md` and run with `scripts/run-e2e.sh`.
- Feature: design with `/design`, plan with `/create-plan`, implement with `/execute-plan`.

## Gates

```bash
npx tsc --noEmit --skipLibCheck
npm run lint
```

Plus tests related to the change.

## Delivery

- PR follows `.github/pull_request_template.md` and `.claude/rules/pr.md`.
- If the diff touches schema/data, auth or untested config: add label `need-qa` and list manual checks in the QA section. When in doubt, treat it as critical.
- Merge: without `need-qa` enable auto-merge (`gh pr merge <nr> --auto --merge`). With `need-qa` do not merge.

## Report

At the end the agent drafts a Slack message (English, no em dash) and Capitan passes it to me verbatim. Never send it.

```
:hourglass: <short description of the change>
PR: <PR URL>

:merged: will be merged automatically when pr-checks pass
```

## Cleanup

- Nothing extra: the `pre-remove` hook in `.config/wt.toml` stops the worktree's containers.
