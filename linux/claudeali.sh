#!/bin/bash
# =============================================================================
# claudeali.sh
# Launch Claude Code with Alibaba Cloud Model Studio (Qwen) provider
# Uses Coding Plan exclusive endpoint
# =============================================================================

BACKUP_PATH="$HOME/.claude/api_keys_backup.json"

_C_RED='\033[0;31m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[1;33m'
_C_CYAN='\033[0;36m'
_C_GRAY='\033[0;90m'
_C_WHITE='\033[1;37m'
_C_NC='\033[0m'

API_KEY=""

if [[ -f "$BACKUP_PATH" ]] && command -v jq &> /dev/null; then
    API_KEY=$(jq -r '.ALIBABA // empty' "$BACKUP_PATH" 2>/dev/null)
    if [[ -n "$API_KEY" ]]; then
        echo -e "${_C_GRAY}Using Alibaba API key from backup${_C_NC}"
    fi
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${_C_YELLOW}Alibaba Cloud API key not found in backup.${_C_NC}"
    echo -e "${_C_YELLOW}Get your API key from: https://modelstudio.console.alibabacloud.com/${_C_NC}"
    echo "(Make sure to create the key in Singapore region)"
    echo -n "Enter your Alibaba Cloud API key: "
    read -rs API_KEY
    echo

    if [[ -z "$API_KEY" ]]; then
        echo -e "${_C_RED}API key required for Alibaba provider${_C_NC}"
        exit 1
    fi

    mkdir -p "$(dirname "$BACKUP_PATH")"
    if [[ -f "$BACKUP_PATH" ]]; then
        jq -s '.[0] * {"ALIBABA": "'"$API_KEY"'"}' "$BACKUP_PATH" > "${BACKUP_PATH}.tmp" && mv "${BACKUP_PATH}.tmp" "$BACKUP_PATH"
    else
        echo "{\"ALIBABA\": \"$API_KEY\"}" > "$BACKUP_PATH"
    fi
    chmod 600 "$BACKUP_PATH"
fi

echo ""
echo -e "${_C_CYAN}=== Launching Claude Code with Alibaba Cloud Provider ===${_C_NC}"
echo -e "${_C_GREEN}✅ Using ENVIRONMENT VARIABLES (safe for concurrent sessions)${_C_NC}"
echo -e "${_C_GREEN}✅ Does NOT modify settings.json${_C_NC}"
echo ""

export ANTHROPIC_AUTH_TOKEN="$API_KEY"
export ANTHROPIC_BASE_URL="https://coding-intl.dashscope.aliyuncs.com/apps/anthropic"
export ANTHROPIC_DEFAULT_SONNET_MODEL="qwen3-plus"
export ANTHROPIC_DEFAULT_OPUS_MODEL="qwen3-plus"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="qwen3-plus"

echo -e "${_C_WHITE}Provider: Alibaba Cloud Model Studio (Coding Plan)${_C_NC}"
echo -e "${_C_GRAY}Base URL: coding-intl.dashscope.aliyuncs.com/apps/anthropic${_C_NC}"
echo -e "${_C_GRAY}Model: qwen3-plus (all tiers)${_C_NC}"
echo ""
echo -e "${_C_GREEN}Launching Claude Code...${_C_NC}"
echo ""

# --- Session tagging: snapshot before launch ---
SESSIONS_INDEX="$HOME/.claude/sessions-index.json"
SESSION_PROVIDERS="$HOME/.claude/session_providers.json"
_SESSIONS_BEFORE=""
if [[ -f "$SESSIONS_INDEX" ]] && command -v jq &> /dev/null; then
    _SESSIONS_BEFORE=$(jq -r 'keys[]' "$SESSIONS_INDEX" 2>/dev/null | sort)
fi

claude "$@"
_CLAUDE_EXIT=$?

# --- Session tagging: diff and tag new sessions ---
if [[ -f "$SESSIONS_INDEX" ]] && command -v jq &> /dev/null; then
    _SESSIONS_AFTER=$(jq -r 'keys[]' "$SESSIONS_INDEX" 2>/dev/null | sort)
    _NEW_SESSIONS=$(comm -13 <(echo "$_SESSIONS_BEFORE") <(echo "$_SESSIONS_AFTER"))
    if [[ -n "$_NEW_SESSIONS" ]]; then
        mkdir -p "$(dirname "$SESSION_PROVIDERS")"
        [[ -f "$SESSION_PROVIDERS" ]] || echo '{}' > "$SESSION_PROVIDERS"
        _TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        while IFS= read -r _SESSION_UUID; do
            [[ -z "$_SESSION_UUID" ]] && continue
            _TAG_JSON="{\"provider\": \"alibaba\", \"model\": \"qwen3-plus\", \"tagged\": \"$_TIMESTAMP\"}"
            jq --arg uuid "$_SESSION_UUID" --argjson tag "$_TAG_JSON" \
                '.[$uuid] = $tag' "$SESSION_PROVIDERS" > "${SESSION_PROVIDERS}.tmp" \
                && mv "${SESSION_PROVIDERS}.tmp" "$SESSION_PROVIDERS"
        done <<< "$_NEW_SESSIONS"
        _NEW_COUNT=$(echo "$_NEW_SESSIONS" | grep -c .)
        echo -e "${_C_GRAY}Tagged $_NEW_COUNT new session(s) as Alibaba${_C_NC}"
    fi
fi
exit $_CLAUDE_EXIT
