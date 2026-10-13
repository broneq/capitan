# Agent prompt template

A task prompt has three parts: the common part, the part for the task type, and the ending. Fill the placeholders, drop what does not apply, and add the extras from `.claude/capitan.md` (section `Prompt`). Reference the project's own skills, rules and commands by name when they exist (for example a planning skill, an E2E test rule, a PR template). Do not invent ones that do not exist.

## Common part (always)

> You are working on the task: <issue URL, or the task text>. Read it and everything it links to. The environment is ready: a worktree on branch `<branch>` based on `<base>`<, plus what the setup prepared: env files, dependencies, port>. Follow the project's CLAUDE.md and rules. If the task has an open question: analyse the code, propose an answer and ask me with AskUserQuestion before you implement anything.

## Type `Bug`

> 1) Confirm the problem: reproduce it end to end the way a user sees it, and check git history to see whether it is a regression. If it does not reproduce, stop and report the evidence.
> 2) Decide whether the fix needs a new test. A test is needed when the bug could come back unnoticed: logic, regression, a user flow. A trivial fix (typo, cosmetic style, obvious one-liner) does not need one. Write the decision and the reason in your report and in the PR description.
> 3) If a test is needed, fix it test-first: a failing test (E2E or unit, whichever is enough), then the fix, then green. Otherwise fix it and verify manually the way a user would.

## Type `Feature`

> 1) Before you write anything, ask me with AskUserQuestion: do we design first (bigger feature, architecture or product decisions) or plan right away (small, clear change)? Include your recommendation.
> 2) Follow the chosen path. Show me the plan and wait for my approval.
> 3) Implement the plan with tests for the new behaviour.

## Type `Decision`

> 1) Analyse the problem: read the task, linked reports and related issues. Reproduce the current behaviour end to end and find the cause in the code.
> 2) Prepare a decision document: current behaviour with evidence, cause, 2-4 options with cost, risk and user impact, and your recommendation. Give me the link or path and STOP. Implement nothing before my decision.
> 3) After the decision: a fix follows the `Bug` path (from step 2), new behaviour follows the `Feature` path (plan, approval, implementation). If the decision is "no change", propose a comment for the task and stop.

## Ending (all types)

> 4) Run the quality gates: <the project's typecheck, lint and tests related to the change, as defined in CLAUDE.md, rules or `.claude/capitan.md`>.
> 5) Commit and open a PR following the project's PR template and rules. If the task is an issue, the PR description must contain `Closes #<nr>`.
> 6) Wait for CI. If something is red, fix the code (not the tests) and push.
> 7) Do not merge unless `.claude/capitan.md` defines a merge policy that allows it.
> 8) Finish with a short report: what changed, the PR link, the test decision, and anything I must do.

## Rules for Capitan

- Pass along any open questions from the task, so the agent asks them.
- Never paste secrets into a prompt.
- One prompt per task. Follow-up instructions go through `herdr agent prompt` only after you checked the agent is not `working`.
