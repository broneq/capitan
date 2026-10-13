# Agent prompt template

Send this prompt with the placeholders filled. `<skill dir>` is the absolute path of this skill's directory (the directory that holds `scripts/preflight.sh`). Keep the protocol line exactly as it is: the protocol file holds the rules for questions, delivery and finishing, so do not restate or shorten them in the prompt. Add the extras from `.claude/capitan.md` (section `Prompt`). Do not add a method of your own (planning steps, test strategy): the agent follows the project's CLAUDE.md, rules and skills, and asks the user when unsure.

## Prompt

> Your task: <the user's request, verbatim, plus any links or files they gave>.
>
> You work in the worktree `<path>` on branch `<branch>` (based on `<base>`). The project's setup hooks have already run in it.
>
> Your task id is `task-<slug>`. Capitan's session name is `<Capitan's session name>`. Before you start, read `<skill dir>/references/agent-protocol.md` and follow it for the whole task.

## Rules for Capitan

- Pass along any open questions from the request, so the agent asks them.
- Never paste secrets into a prompt.
- One prompt per task. Follow-up instructions go through `herdr agent prompt` only after you checked the agent is not `working`.
