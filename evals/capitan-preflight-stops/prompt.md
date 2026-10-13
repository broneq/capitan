---
name: capitan-preflight-stops
tags: [capitan]
runs: 3
max_turns: 10
timeout_seconds: 300
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

/capitan:capitan Add a file NOTES.md with three short facts about git.
