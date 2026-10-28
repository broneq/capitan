# Operations

## Monitoring

- All agents: `herdr agent list`. One agent: `herdr agent get <name>`.
- Recent output: `herdr agent read <name> --source recent-unwrapped --lines 120`. When the agent is `working`, this returns `agent_not_idle`; use `--source visible` instead.
- Wait for an agent to settle: `herdr agent wait <name> --timeout <ms>`.
- Statuses:
  - `working` - leave it alone.
  - `blocked` - the agent waits for the user (question or permission). Tell the user which agent asks what. Do not answer for them.
  - `idle` / `done` - the agent finished a turn. Read the result and summarise it briefly.

## Status check

When the user asks for status, collect for every task:

```bash
herdr agent list
wt -C <main checkout> list
```

Report a table: task, workspace, branch, agent status, worktree state (uncommitted changes, commits ahead of the base, already merged), next step. Add what `.claude/capitan.md` asks for (for example the pull request, the issue or a port).

## Closing out a finished task

Run this when the agent reported `task-<slug> finished` and you verified the task is done (SKILL.md, Messages from agents), or when the user asks you to. Bookkeeping comes first, then cleanup. Skip steps that do not apply (a task without a tracker item, a report without a pull request). Use the tracker tools named in `.claude/capitan.md`.

1. Set the tracker item's final status (for example Done) and close it if it is still open (for example a pull request without `Closes` leaves the issue open). Add a comment naming the pull request or the deliverable.
2. Tick the task in its parent checklist (for example an epic) if the project has one.
3. Run any extra bookkeeping from `.claude/capitan.md`.
4. Close the task's workspace alone: `herdr workspace close <workspace_id>`. Never `--group`. After the first close in a session, check `herdr workspace list` that the other workspaces survived.
5. Remove the worktree with Worktrunk, which also runs the project's `pre-remove` and `post-remove` hooks (for example stopping its containers): `git -C <main checkout> fetch origin`, then `wt -C <main checkout> remove --foreground <branch>`. Never `--force` or `-D`.
6. Report what Worktrunk did. It refuses to remove a worktree with uncommitted changes, and it keeps a branch whose content is not in the base branch yet. In both cases tell the user and leave it; do not fix it yourself.
7. Offer the next ready and unblocked tasks.

## Tidy up

When the user asks to tidy Herdr or the sidebar is cluttered, list what exists and compare:

```bash
herdr worktree list --cwd <main checkout>
wt -C <main checkout> list
herdr agent list
```

- A workspace without a live task (its agent is gone, its branch is merged or its worktree is removed) is a leftover. Show the user the list and close only the ones they approve, one by one, with `herdr workspace close <workspace_id>` (never `--group`), then remove its worktree as in cleanup above.
- A workspace listed under `<main checkout>/.` or any other path than the main checkout was opened with a relative path. Close it and restore it as below with the absolute path.

## Recovery after an accidental close

- The files in the worktree stay on disk: `git -C <path> status`.
- `herdr worktree open --cwd <main checkout> --path <worktree path> --label "<label>" --no-focus` restores the grouped workspace. Herdr usually resumes the previous agent session in it.
- If it does not: Claude sessions live in `<CLAUDE_CONFIG_DIR, default ~/.claude>/projects/<worktree path with / replaced by ->/<session-id>.jsonl`. The newest by modification time is the one. Start the agent as in step 4 of the skill, with `--resume <session-id>` added, then tell the agent where to continue.
- If the worktree is gone but the branch exists (locally or on `origin`), recreate it: `wt -C <main checkout> switch <branch> --no-cd --format=json`, open it with `herdr worktree open` as in step 2 of the skill, then start the agent as above. The old session is found by the worktree path as above; without it, start fresh and point the agent at the branch and its pull request.
