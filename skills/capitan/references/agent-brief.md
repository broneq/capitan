# Agent brief

Send this as the agent's first prompt with the placeholders filled. Pass the user's request verbatim, with any links or files they gave; do not add a method of your own (planning steps, test strategy). Never paste secrets. The standing rules are in agent-rules.md, already in the agent's system prompt.

---

You are `<name>`, task `<id>`. Capitan's session name is `<your session name>`.

Task: <the user's request, verbatim>.

You work in `<path>` on branch `<branch>` (from `<base>`); the setup hooks already ran. Overlapping tasks: <names and labels, or none>.

You may message Capitan and the other agents of this repo (names starting with `<repo>-`) with SendMessage, as your standing rules describe.
