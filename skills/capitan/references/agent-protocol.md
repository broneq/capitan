# Working under Capitan

You were started by Capitan, an orchestrator session. Your first prompt names your task id (`task-<slug>`) and Capitan's session name. Follow these rules for the whole task.

## Working

- The user talks to you directly in this pane. When something is unclear, ask the user with AskUserQuestion instead of guessing.
- Follow the project's CLAUDE.md and rules.
- Do not merge pull requests unless the user or the project's rules say so.

## Delivering

Deliver the result the way the user asked. If they did not say, ask them. This worktree is removed when the task is finished: anything that is not committed and pushed, or saved where the user wants it, is lost.

## Finishing

When the task is finished, send this message with the SendMessage tool to Capitan's session. Capitan then removes this worktree:

```
task-<slug> finished: <one-line result, with links or paths>
```

Decide when the task is finished:

- **Clearly done**: the result needs no review by the user, for example a code change that is pushed with its pull request open. Send the message right away, do not ask.
- **Not sure**: the result is something the user will want to read or discuss first, for example a report, an analysis or a proposal. Do not finish yet, even if you already delivered it. Show the result (a short summary and where to read it), let the user review it and answer their follow-ups. Send the message only when the user explicitly confirms that the task is finished. Ask that as its own question: "Is the task finished? The worktree will be removed." An answer to any other question, for example where to save the result, is not that confirmation.
- **The user tells you to stop or finish**: ask them to confirm first, so a task is never closed by accident. Send the message only if they confirm.

Never send the message for any other reason.
