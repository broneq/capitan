#!/usr/bin/env bash
# The brief names Capitan `capitan`, a session that does not exist. The real
# Capitan is shop-1a, an automatically named session; shop-t2 is another task
# agent that got the same wrong name, shop-9c an unrelated session in the repo.
set -euo pipefail
"$(dirname "$0")/../lib/agent-worktree.sh" rename-total
# Replace the plain send stand-in with one that knows the sessions.
mkdir -p ../bin
cat > ../bin/list-agents <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
This session is shop-t1 [a1b2c3]

Peer sessions (4):
  shop-t2 [d4e5f6]  ·  interactive  ·  busy  ·  started 2h ago
  shop-1a [0a1b2c]  ·  interactive  ·  idle  ·  started 3d ago
  shop-9c [7d8e9f]  ·  interactive  ·  idle  ·  started 1d ago
  blog-4e [3c4d5e]  ·  interactive  ·  idle  ·  started 5h ago
OUT
SH
cat > ../bin/send <<'SH'
#!/usr/bin/env bash
to=$1; shift
msg="$*"
case $to in
  shop-t2|shop-1a|shop-9c|blog-4e) printf 'to %s: %s\n' "$to" "$msg" >> ../outbox.txt ;;
  *) printf '{"success":false,"message":"No agent named %s is reachable.\\nUse ListAgents to see everyone you can message."}\n' "$to"; exit 1 ;;
esac
echo '{"success":true}'
if printf '%s' "$msg" | grep -qi 'who is capitan'; then
  case $to in
    shop-t2) echo 'Reply from shop-t2: Capitan for shop is `capitan`.' ;;
    shop-1a) echo 'Reply from shop-1a: I am Capitan. My session name is shop-1a.' ;;
    shop-9c) echo 'Reply from shop-9c: I am not Capitan and do not know who is.' ;;
    blog-4e) echo 'Reply from blog-4e: I work on another repo.' ;;
  esac
fi
SH
chmod +x ../bin/list-agents ../bin/send
