---
name: delegate
description: Opens one or more tasks (a description, a tracker link, several of them) in a running Capitan session, each in its own worktree, Herdr workspace and agent, optionally in a mode other than the session's. Can create the tracker item first when asked. Use when the user wants to hand tasks off to agents in a Capitan session.
disable-model-invocation: true
argument-hint: "[--hands-on|--hands-off] <task, link or links>"
allowed-tools: Bash(git -C * fetch *), Bash(git -C * symbolic-ref *), Bash(git -C * diff --name-only *), Bash(wt -C * switch --create *), Bash(wt -C * list *), Bash(herdr worktree open *), Bash(herdr pane run *), Bash(herdr agent *), Bash(herdr workspace list *)
---

# Delegate

Hand the tasks in `$ARGUMENTS` to agents.

1. This session must be Capitan: Capitan's instructions are in your context and its Start has run. If not, tell the user to start with `/capitan`, which takes the same arguments, and STOP.
2. Mode: `--hands-on` or `--hands-off` in `$ARGUMENTS` applies to these tasks only. Without it, use the session mode.
3. If `$ARGUMENTS` holds no task, ask the user for it.
4. Open the tasks as Capitan's Open a task says, with that mode in each brief.
