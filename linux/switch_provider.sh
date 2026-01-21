#!/bin/bash
# =============================================================================
# Switch-ClaudeProvider.sh
# Toggles Claude Code between GLM (Z.AI) and Anthropic providers
# Ported from: https://github.com/exurocommits/claude-provider-scripts
# =============================================================================

set -e

# Configuration
SETTINGS_PATH="$HOME/.claude/settings.json"
BACKUP_PATH="$HOME/.claude/api_keys_backup.json"

# Colors
_C_RED='\033[0;31m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[1;33m'
_C_CYAN='\033[0;36m'
_C_GRAY='\033[0;90m'
_C_NC='\033[0m'

# =============================================================================
# Check dependencies
# =============================================================================
if ! command -v jq &> /dev/null; then
    echo -e "${_C_RED}Error: jq is required but not installed.${_C_NC}"
    echo "Install with: sudo apt install jq (Ubuntu/Debian)"
    echo "              brew install jq (macOS)"
    exit 1
fi

# =============================================================================
# Parse arguments
# =============================================================================
PROVIDER="${1:-Toggle}"

# Normalize provider name (case-insensitive)
PROVIDER=$(echo "$PROVIDER" | tr '[:lower:]' '[:upper:]')
case "$PROVIDER" in
    GLM|ZAI) PROVIDER="GLM" ;;
    ANTHROPIC|CLAUDE) PROVIDER="Anthropic" ;;
    TOGGLE|"") PROVIDER="Toggle" ;;
    *)
        echo -e "${_C_RED}Invalid provider: $1${_C_NC}"
        echo "Valid options: GLM, Anthropic, Toggle"
        exit 1
        ;;
esac

# =============================================================================
# Check settings file exists
# =============================================================================
if [[ ! -f "$SETTINGS_PATH" ]]; then
    echo -e "${_C_RED}Settings file not found at: $SETTINGS_PATH${_C_NC}"
    exit 1
fi

# =============================================================================
# Read current settings
# =============================================================================
SETTINGS=$(cat "$SETTINGS_PATH")

# Ensure env property exists
if ! echo "$SETTINGS" | jq -e '.env' > /dev/null 2>&1; then
    SETTINGS=$(echo "$SETTINGS" | jq '. + {env: {}}')
fi

# Store current provider for toggle logic
CURRENT_BASE_URL=$(echo "$SETTINGS" | jq -r '.env.ANTHROPIC_BASE_URL // empty')
IS_CURRENT_GLM=false
if [[ "$CURRENT_BASE_URL" == *"z.ai"* ]]; then
    IS_CURRENT_GLM=true
fi

# =============================================================================
# Determine target provider
# =============================================================================
if [[ "$PROVIDER" == "Toggle" ]]; then
    if [[ "$IS_CURRENT_GLM" == "true" ]]; then
        TARGET_PROVIDER="Anthropic"
    else
        TARGET_PROVIDER="GLM"
    fi
else
    TARGET_PROVIDER="$PROVIDER"
fi

# =============================================================================
# Apply configuration
# =============================================================================
if [[ "$TARGET_PROVIDER" == "GLM" ]]; then
    echo -e "${_C_CYAN}Switching to GLM (Z.AI) provider...${_C_NC}"
    
    # Check if we have a GLM API key stored
    GLM_API_KEY=""
    if [[ -f "$BACKUP_PATH" ]]; then
        GLM_API_KEY=$(jq -r '.GLM // empty' "$BACKUP_PATH" 2>/dev/null)
    fi
    
    if [[ -z "$GLM_API_KEY" ]]; then
        echo -e "${_C_YELLOW}GLM API key not found in backup.${_C_NC}"
        echo -e "${_C_YELLOW}Get your API key from: https://z.ai/manage-apikey/apikey-list${_C_NC}"
        echo -n "Enter your Z.AI API key: "
        read -rs GLM_API_KEY
        echo
        
        if [[ -z "$GLM_API_KEY" ]]; then
            echo -e "${_C_RED}API key required for GLM provider${_C_NC}"
            exit 1
        fi
        
        # Save to backup
        mkdir -p "$(dirname "$BACKUP_PATH")"
        echo "{\"GLM\": \"$GLM_API_KEY\"}" > "$BACKUP_PATH"
        chmod 600 "$BACKUP_PATH"
    fi
    
    # Update settings with GLM configuration
    SETTINGS=$(echo "$SETTINGS" | jq \
        --arg auth_token "$GLM_API_KEY" \
        --arg base_url "https://api.z.ai/api/anthropic" \
        --arg sonnet "glm-4.7" \
        --arg opus "glm-4.7" \
        --arg haiku "glm-4.5-air" \
        '.env.ANTHROPIC_AUTH_TOKEN = $auth_token |
         .env.ANTHROPIC_BASE_URL = $base_url |
         .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $sonnet |
         .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $opus |
         .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $haiku')

else
    echo -e "${_C_CYAN}Switching to Anthropic provider (uses your login subscription)...${_C_NC}"
    
    # Remove ALL GLM-specific settings to revert to Anthropic defaults
    SETTINGS=$(echo "$SETTINGS" | jq '
        del(.env.ANTHROPIC_AUTH_TOKEN) |
        del(.env.ANTHROPIC_BASE_URL) |
        del(.env.ANTHROPIC_DEFAULT_SONNET_MODEL) |
        del(.env.ANTHROPIC_DEFAULT_OPUS_MODEL) |
        del(.env.ANTHROPIC_DEFAULT_HAIKU_MODEL)')
    
    # Remove env section entirely if empty
    ENV_COUNT=$(echo "$SETTINGS" | jq '.env | length')
    if [[ "$ENV_COUNT" == "0" ]]; then
        SETTINGS=$(echo "$SETTINGS" | jq 'del(.env)')
    fi
fi

# =============================================================================
# Save settings
# =============================================================================
echo "$SETTINGS" | jq '.' > "$SETTINGS_PATH"

# =============================================================================
# Display result
# =============================================================================
# Check what we have now
HAS_ENV=$(echo "$SETTINGS" | jq -e '.env' > /dev/null 2>&1 && echo "true" || echo "false")

if [[ "$HAS_ENV" == "true" ]]; then
    DISPLAY_BASE_URL=$(echo "$SETTINGS" | jq -r '.env.ANTHROPIC_BASE_URL // "default (Anthropic)"')
    DISPLAY_SONNET=$(echo "$SETTINGS" | jq -r '.env.ANTHROPIC_DEFAULT_SONNET_MODEL // "default"')
    DISPLAY_OPUS=$(echo "$SETTINGS" | jq -r '.env.ANTHROPIC_DEFAULT_OPUS_MODEL // "default"')
    DISPLAY_HAIKU=$(echo "$SETTINGS" | jq -r '.env.ANTHROPIC_DEFAULT_HAIKU_MODEL // "default"')
else
    DISPLAY_BASE_URL="default (Anthropic)"
    DISPLAY_SONNET="default"
    DISPLAY_OPUS="default"
    DISPLAY_HAIKU="default"
fi

echo -e "${_C_GREEN}Switched to $TARGET_PROVIDER provider!${_C_NC}"
echo -e "${_C_GRAY}Current configuration:${_C_NC}"
echo -e "${_C_GRAY}  Base URL: $DISPLAY_BASE_URL${_C_NC}"
echo -e "${_C_GRAY}  Sonnet: $DISPLAY_SONNET${_C_NC}"
echo -e "${_C_GRAY}  Opus: $DISPLAY_OPUS${_C_NC}"
echo -e "${_C_GRAY}  Haiku: $DISPLAY_HAIKU${_C_NC}"
