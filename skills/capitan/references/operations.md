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

When the user asks for status, check for every task the task state, the PR and the local worktree:

```bash
gh issue view <nr> --json state,stateReason,closedByPullRequestsReferences   # if the task is an issue
gh pr list --head <branch> --state all --json number,state,url,labels,autoMergeRequest
git -C <worktree> status --porcelain
```

Report a table: task, workspace, branch, agent status, task state, PR (state, labels, auto-merge), next step. Add the columns that `.claude/capitan.md` asks for (for example port or instance).

## Cleanup after merge

A task is done when its PR is `MERGED` and its issue is `CLOSED` (for a free-text task: the PR is `MERGED`). Clean up a done task right away when a status check finds it:

1. Verify the worktree has no local changes (`git -C <worktree> status --porcelain` is empty) and no unpushed commits (`git -C <worktree> log @{u}..HEAD` is empty). If anything is there, do not clean up; ask the user.
2. Close its workspace alone: `herdr workspace close <workspace_id>`. Never `--group`. After the first close in a session, check `herdr workspace list` that the other workspaces survived.
3. Remove the worktree and its branch with Worktrunk, which also runs the project's `pre-remove` and `post-remove` hooks (for example stopping its containers): `git -C <main checkout> fetch origin`, then `wt -C <main checkout> remove --foreground <branch>`. Never `--force` or `-D`. Worktrunk deletes the branch only when its content is already in the base branch; if it keeps the branch, tell the user and leave it.
4. Run any extra cleanup from `.claude/capitan.md` (for example freeing a port or instance).
5. If the PR is merged but the issue is still open, do not close it. Tell the user.

## Recovery after an accidental close

- The code in the worktree stays on disk: `git -C <path> status`.
- `herdr worktree open --cwd <main checkout> --path <worktree path> --label "<label>" --no-focus` restores the grouped workspace. Herdr usually resumes the previous agent session in it.
- If it does not: Claude sessions live in `~/.claude/projects/<worktree path with / replaced by ->/<session-id>.jsonl`. The newest by modification time is the one. Resume it with `herdr agent start <name> --kind claude --pane <pane> -- --model <model> --resume <session-id>`, then tell the agent which step to continue from.
