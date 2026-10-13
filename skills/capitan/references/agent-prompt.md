# Agent prompt template

Send the task in the user's own words, then the context and the protocol below. Fill the placeholders and add the extras from `.claude/capitan.md` (section `Prompt`). Do not add a method of your own (planning steps, test strategy): the agent follows the project's CLAUDE.md, rules and skills, and asks the user when unsure.

## Prompt

> Your task: <the user's request, verbatim, plus any links or files they gave>.
>
> You work in the worktree `<path>` on branch `<branch>` (based on `<base>`). The project's setup hooks have already run in it. Follow the project's CLAUDE.md and rules.
>
> The user talks to you directly in this pane. When something is unclear, ask the user with AskUserQuestion instead of guessing.
>
> When the work is done, deliver it the way the user asked. If they did not say, ask them. This worktree is removed when the task is finished: anything that is not committed and pushed, or saved where the user wants it, is lost.
>
> Then tell the user what you did and ask with AskUserQuestion whether the task is finished and its worktree can be removed. Also when the user says to stop or finish this task, first ask them to confirm. Only after they confirm, send this message with the SendMessage tool to the session `<Capitan's session name>`:
>
> `task-<slug> finished: <one-line result, with links or paths>`
>
> Never send it without the user's confirmation. Do not merge pull requests unless the user or the project's rules say so.

## Rules for Capitan

- Pass along any open questions from the request, so the agent asks them.
- Never paste secrets into a prompt.
- One prompt per task. Follow-up instructions go through `herdr agent prompt` only after you checked the agent is not `working`.
