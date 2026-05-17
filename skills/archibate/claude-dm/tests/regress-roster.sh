#!/usr/bin/env bash
# Roster-resolution regression test. No real claude session required: spawns
# fake long-lived processes that mimic the three ways an interactive claude
# can land on a tmux pane, with a stub ~/.claude/sessions/<pid>.json so the
# sessions-file fallback can fire. Verifies that `list`, `status`, and `peek`
# all see every pane regardless of whether comm == "claude".
#
# Cases exercised:
#   A: shell-resolved `claude` — comm = "claude", no sessions file needed
#   B: `exec claude`            — same comm, shell replaced
#   C: `exec /…/versions/X.Y.Z` — comm = version basename; without the
#                                 sessions-file fallback the pane silently
#                                 disappears from `list` (the original bug)
#
# Plus one non-claude pane to confirm exclusion still works.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DM="$HERE/bin/claude-dm"

SOCK=$(mktemp -u /tmp/claude-dm-regress.XXXXXX.sock)
WORK=$(mktemp -d /tmp/claude-dm-regress-fake.XXXXXX)
SESSIONS=$(mktemp -d /tmp/claude-dm-regress-sessions.XXXXXX)
PROJECTS=$(mktemp -d /tmp/claude-dm-regress-projects.XXXXXX)

cleanup() {
  tmux -S "$SOCK" kill-server 2>&1 | head -1 || true
  rm -rf "$WORK" "$SESSIONS" "$PROJECTS"
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'OK:   %s\n' "$*"; }

# Build the fake claude install layout: a versioned sleep binary + a "claude"
# symlink pointing to it. The kernel sets task->comm to the basename of the
# path passed to execve, so invoking via the symlink yields comm="claude" and
# invoking via the resolved path yields comm="X.Y.Z".
mkdir -p "$WORK/versions"
cp /bin/sleep "$WORK/versions/9.9.9"
ln -s "$WORK/versions/9.9.9" "$WORK/claude"

# Spawn three claude-shaped panes plus one plain-shell pane.
tmux -S "$SOCK" -f /dev/null new-session -d -s a     -n A "$WORK/claude 60"
tmux -S "$SOCK" -f /dev/null new-session -d -s b     -n B "exec $WORK/claude 60"
tmux -S "$SOCK" -f /dev/null new-session -d -s c     -n C "exec $WORK/versions/9.9.9 60"
tmux -S "$SOCK" -f /dev/null new-session -d -s plain -n P 'sleep 60'
sleep 1

# Stub a sessions/<pid>.json + transcript only for case C — this is the path
# where the comm fast-path fails and the fallback must take over.
PID_C=$(tmux -S "$SOCK" display-message -p -t c '#{pane_pid}')
SID_C="aaaaaaaa-bbbb-cccc-dddd-pid${PID_C}"
mkdir -p "$PROJECTS/proj"
printf '{"pid":%s,"sessionId":"%s","cwd":"/tmp"}\n' "$PID_C" "$SID_C" > "$SESSIONS/$PID_C.json"
printf '{"type":"assistant","message":{"content":[{"type":"text","text":"hello from c"}]}}\n' > "$PROJECTS/proj/$SID_C.jsonl"

export CLAUDE_DM_SOCKET="$SOCK"
export CLAUDE_SESSIONS_DIR="$SESSIONS"
export CLAUDE_PROJECTS_DIR="$PROJECTS"

list_out=$("$CLAUDE_DM" list 2>&1)

grep -qE '^a:0\.0[[:space:]]'     <<<"$list_out" || fail "list missing a:0.0 (comm-fast-path case)"
pass "list contains a:0.0"

grep -qE '^b:0\.0[[:space:]]'     <<<"$list_out" || fail "list missing b:0.0 (exec-shell case)"
pass "list contains b:0.0"

grep -qE '^c:0\.0[[:space:]]'     <<<"$list_out" || fail "list missing c:0.0 — sessions-file fallback regressed"
pass "list contains c:0.0 (versioned-comm fallback)"

grep -qE '^plain:0\.0[[:space:]]' <<<"$list_out" && fail "list should exclude non-claude pane"
pass "list excludes plain:0.0"

status_out=$("$CLAUDE_DM" status c:0.0 2>&1)
grep -qE "^pid[[:space:]]+$PID_C$" <<<"$status_out" \
  || fail "status c:0.0 did not resolve pid via fallback (PID_C=$PID_C); raw: $status_out"
pass "status c:0.0"

"$CLAUDE_DM" peek c:0.0 5 | grep -qF 'hello from c' || fail "peek c:0.0 did not return transcript text"
pass "peek c:0.0"

# Negative: status on the non-claude pane must error out.
if "$CLAUDE_DM" status plain:0.0 >/dev/null 2>&1; then
  fail "status plain:0.0 should fail but succeeded"
fi
pass "status plain:0.0 correctly fails"

echo
echo "regress-roster OK"
