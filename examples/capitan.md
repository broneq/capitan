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

Tasks are GitHub issues. Take only issues that are ready and not blocked (check `blockedBy`). At task start, right after the agent started, assign me (`gh issue edit <n> --add-assignee @me`) and set the item's Status to `In progress`. At close-out, after the merge is verified: set Status to `Done`, close the issue if the PR did not (`gh issue close <n> --comment "Done in <PR URL>"`), and tick the task in the epic's checklist. Agents never touch issues.

Setting the Status of a GitHub Projects v2 item:

1. Read the item and project ids: `gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){issue(number:$n){projectItems(first:10){nodes{id project{id}}}}}}' -f o=<owner> -f r=<repo> -F n=<n>`.
2. Read the Status field id and its option ids: query `node(id:<project id>){... on ProjectV2{field(name:"Status"){... on ProjectV2SingleSelectField{id options{id name}}}}}`.
3. Set it: mutation `updateProjectV2ItemFieldValue(input:{projectId:<project id>,itemId:<item id>,fieldId:<field id>,value:{singleSelectOptionId:<option id>}})`.

Project, field and option ids are stable: write them here once.
