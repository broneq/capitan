# Capitan config

<!--
Example of .claude/capitan.md. Copy it to your project, commit it (agents read it in their worktrees) and keep only the sections you need.
Every section overrides the matching Capitan default. Missing sections use the defaults.
Plain instructions are enough: Capitan and its agents read this file as rules, not as a strict schema.
-->

## Tracker

The tracker, its commands and status names. Capitan claims a task at start (assigns you, sets it in progress) and closes it at the end; agents never touch it. Without this section tracker items are not updated.

GitHub issues with a Projects board. The task id is the issue number. Take only issues that are ready and not blocked (check `blockedBy`).

- To create an item (when the request asks for one): `gh issue create`, then add it as a sub-issue of its epic. Bugs go under the BUGS epic (#42).
- At start: `gh issue edit <n> --add-assignee @me`, set the Projects Status to `In progress`.
- At the end: set Status to `Done`, close the issue if the pull request did not (`gh issue close <n> --comment "Done in <PR URL>"`), tick the task in the epic's checklist.

Setting the Status of a GitHub Projects v2 item (project, field and option ids are stable: write them here once):

1. Item and project ids: `gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){issue(number:$n){projectItems(first:10){nodes{id project{id}}}}}}' -f o=<owner> -f r=<repo> -F n=<n>`.
2. Status field and option ids: query `node(id:<project id>){... on ProjectV2{field(name:"Status"){... on ProjectV2SingleSelectField{id options{id name}}}}}`.
3. Set it: mutation `updateProjectV2ItemFieldValue(input:{projectId:<project id>,itemId:<item id>,fieldId:<field id>,value:{singleSelectOptionId:<option id>}})`.

## Mode

The session's default mode, so Capitan does not ask at start: `hands-off` (agents decide themselves and ask only when they would lose work or take an irreversible step) or `hands-on` (agents ask when a wrong guess would cost real work, and confirm before closing a report). `/capitan --hands-on` or `/capitan:delegate --hands-on` still override it.

hands-off

## Branches

`<type>/<issue>-<slug>`, base `origin/main`.

## Merge

Default without this section: agents merge when all checks are green, no review requests changes and nothing is open; not at all when the repository runs no checks.

Agents merge with `gh pr merge <n> --rebase --delete-branch` (this repository allows only rebase). A review from a code owner is required. Push review fixes in one push per round.

## Watch

The command agents poll while they wait, printing the state as one line:

`gh pr view <branch> --json state,isDraft,mergeStateStatus,reviewDecision,comments,reviews,statusCheckRollup --jq '[.state, .isDraft, .mergeStateStatus, .reviewDecision, (.comments|length), (.reviews|length), ([.statusCheckRollup[]|select(.conclusion=="FAILURE")]|length), ([.statusCheckRollup[]|select(.status!=null and .status!="COMPLETED")]|length>0)]|join(" ")' | grep -v UNKNOWN`

## Agents

Notes every agent follows, and how Capitan starts them.

- Complex questions and results: present them with Lavish. Simple choices: AskUserQuestion.
- At the end the agent drafts a Slack message (English, no em dash) and shows it to me. Never send it.
- Start agents with Capitan's model and no extra flags.
