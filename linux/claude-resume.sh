#!/usr/bin/env bash
# claude-resume.sh
# Auto-repair and resume a Claude Code session.
# Usage: claude-resume [session-uuid] [claude flags...]
#   claude-resume                                    → repair all foreign, then claude -r
#   claude-resume --dangerously-skip-permissions     → repair all foreign, then claude -r --dangerously-skip-permissions
#   claude-resume abc-123                            → repair abc-123, then claude --resume abc-123
#   claude-resume abc-123 --dangerously-skip-permissions → repair abc-123, then claude --resume abc-123 --dangerously-skip-permissions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detect if first arg is a UUID (contains hyphens, no dashes prefix) or a flag
SESSION_ID=""
CLAUDE_ARGS=()

for arg in "$@"; do
    if [[ -z "$SESSION_ID" && "$arg" =~ ^[0-9a-f]{8}-[0-9a-f]{4}- ]]; then
        SESSION_ID="$arg"
    else
        CLAUDE_ARGS+=("$arg")
    fi
done

# Repair foreign sessions first
if [[ -n "$SESSION_ID" ]]; then
    node "$SCRIPT_DIR/lib/session-guard.mjs" "$SESSION_ID"
else
    node "$SCRIPT_DIR/lib/session-guard.mjs" --all
fi

# Launch claude — pass through all original args exactly as given
claude "$@"
