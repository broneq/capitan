# Capitan config

<!--
Example of .claude/capitan.md. Copy it to your project and keep only the sections you need.
Every section overrides the matching Capitan default. Missing sections use the defaults.
Plain instructions are enough: Capitan reads this file as rules, not as a strict schema.
-->

## Report

At the end the agent drafts a Slack message (English, no em dash) and Capitan passes it to me verbatim. Never send it.

```
:hourglass: <short description of the change>
PR: <PR URL>

:merged: will be merged automatically when pr-checks pass
```

## Tracker

Tasks are GitHub issues. Take only issues that are ready and not blocked (check `blockedBy`). At task start assign me (`gh issue edit <n> --add-assignee @me`). At close-out: if the issue is still open, close it with a comment naming the PR (`gh issue close <n> --comment "Done in <PR URL>"`), and tick the task in the epic's checklist. Agents never touch issues.
