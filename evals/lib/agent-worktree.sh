#!/usr/bin/env bash
# Scaffold for the agent cases: the current directory becomes a task worktree on
# branch $1 with an origin to push to, and Capitan's agent rules are copied next
# to it, where the system prompt stand-in points the agent. ../shared is the
# user's folder for results: git cannot push inside the eval sandbox on macOS.
# ../bin/send is the SendMessage stand-in: it appends to ../outbox.txt, so a
# grader can count sends without counting reads of the outbox.
set -euo pipefail

branch=$1
root=$(cd "$(dirname "$0")/../.." && pwd)

git init -q -b main .
git config user.name "Eval User"
git config user.email "eval@example.com"
mkdir -p src
printf '# Shop\n\nA tiny demo shop.\n' > README.md
printf 'export function total(items) {\n  return items.reduce((sum, item) => sum + item.price, 0);\n}\n' > src/app.js
git add -A
git commit -q -m "chore: initial commit"
git init -q --bare ../origin.git
git remote add origin ../origin.git
git push -q -u origin main
git switch -q -c "$branch"

mkdir -p ../capitan ../shared
cp "$root/skills/capitan/references/agent-rules.md" ../capitan/agent-rules.md

mkdir -p ../bin
cat > ../bin/send <<'SH'
#!/usr/bin/env bash
to=$1; shift
printf 'to %s: %s\n' "$to" "$*" >> ../outbox.txt
echo '{"success":true}'
SH
chmod +x ../bin/send
