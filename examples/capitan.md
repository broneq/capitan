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
