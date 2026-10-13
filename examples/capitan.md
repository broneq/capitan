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
- path: `~/projects/shop-<nr>`
- base: `origin/main`
- setup, run in the worktree after copying `.worktreeinclude`:
  ```bash
  ./scripts/setup-worktree.sh   # picks a free E2E_INSTANCE and runs npm ci
  ```
  Report the `E2E_INSTANCE` and its port (`3001 + n`) in every status table.

## Agent

- kind: `claude`, args: `--model opus`

## Prompt

- Common part: mention `E2E_INSTANCE=<n>` and the dev server port `<3001+n>`.
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

- Nothing extra: the instance is freed when the worktree is removed.
