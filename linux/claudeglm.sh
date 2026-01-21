#!/bin/bash
# =============================================================================
# claudeglm.sh
# Launch Claude Code with GLM (Z.AI) provider using ENVIRONMENT VARIABLES
# This does NOT modify settings.json - completely safe for concurrent sessions!
# Ported from: https://github.com/exurocommits/claude-provider-scripts
# =============================================================================

BACKUP_PATH="$HOME/.claude/api_keys_backup.json"

# Colors
_C_RED='\033[0;31m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[1;33m'
_C_CYAN='\033[0;36m'
_C_GRAY='\033[0;90m'
_C_WHITE='\033[1;37m'
_C_NC='\033[0m'

# =============================================================================
# Load API keys backup to get GLM key
# =============================================================================
API_KEY=""

if [[ -f "$BACKUP_PATH" ]] && command -v jq &> /dev/null; then
    API_KEY=$(jq -r '.GLM // empty' "$BACKUP_PATH" 2>/dev/null)
    if [[ -n "$API_KEY" ]]; then
        echo -e "${_C_GRAY}Using GLM API key from backup${_C_NC}"
    fi
fi

if [[ -z "$API_KEY" ]]; then
    echo -e "${_C_YELLOW}GLM API key not found in backup.${_C_NC}"
    echo -e "${_C_YELLOW}Get your API key from: https://z.ai/manage-apikey/apikey-list${_C_NC}"
    echo -n "Enter your Z.AI API key: "
    read -rs API_KEY
    echo
    
    if [[ -z "$API_KEY" ]]; then
        echo -e "${_C_RED}API key required for GLM provider${_C_NC}"
        exit 1
    fi
    
    # Save to backup for future use
    mkdir -p "$(dirname "$BACKUP_PATH")"
    echo "{\"GLM\": \"$API_KEY\"}" > "$BACKUP_PATH"
    chmod 600 "$BACKUP_PATH"
fi

echo ""
echo -e "${_C_CYAN}=== Launching Claude Code with GLM Provider ===${_C_NC}"
echo -e "${_C_GREEN}✅ Using ENVIRONMENT VARIABLES (safe for concurrent sessions)${_C_NC}"
echo -e "${_C_GREEN}✅ Does NOT modify settings.json${_C_NC}"
echo ""

# Set environment variables for THIS PROCESS ONLY
export ANTHROPIC_AUTH_TOKEN="$API_KEY"
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.7"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.7"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"

echo -e "${_C_WHITE}Provider: GLM (Z.AI)${_C_NC}"
echo -e "${_C_GRAY}Models: Sonnet/Opus → glm-4.7, Haiku → glm-4.5-air${_C_NC}"
echo ""
echo -e "${_C_GREEN}Launching Claude Code...${_C_NC}"
echo ""

# Launch Claude Code - it will inherit the environment variables
claude "$@"
exit $?
