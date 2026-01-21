#!/bin/bash
# =============================================================================
# Claude Code Provider Switching Profile for Linux/macOS
# Ported from: https://github.com/exurocommits/claude-provider-scripts
# 
# Add this to your ~/.bashrc or ~/.zshrc:
#   source ~/scripts/claude_profile.sh
# =============================================================================

# Path to scripts (adjust if you installed elsewhere)
CLAUDE_SCRIPT_PATH="${CLAUDE_SCRIPT_PATH:-$HOME/scripts}"

# Configuration paths
CLAUDE_SETTINGS_PATH="$HOME/.claude/settings.json"
CLAUDE_API_BACKUP_PATH="$HOME/.claude/api_keys_backup.json"

# Store original title when profile loads
_CLAUDE_ORIGINAL_TITLE=""

# Colors
_C_RED='\033[0;31m'
_C_GREEN='\033[0;32m'
_C_YELLOW='\033[1;33m'
_C_CYAN='\033[0;36m'
_C_GRAY='\033[0;90m'
_C_WHITE='\033[1;37m'
_C_MAGENTA='\033[0;35m'
_C_NC='\033[0m'

# =============================================================================
# Helper: Check for jq
# =============================================================================
_claude_check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${_C_RED}Error: jq is required but not installed.${_C_NC}"
        echo "Install it with:"
        echo "  Ubuntu/Debian: sudo apt install jq"
        echo "  macOS: brew install jq"
        echo "  Fedora: sudo dnf install jq"
        return 1
    fi
    return 0
}

# =============================================================================
# Function to set window title with provider indicator
# =============================================================================
Set-ClaudeWindowTitle() {
    _claude_check_jq || return 1
    
    local provider="Anthropic"
    
    if [[ -f "$CLAUDE_SETTINGS_PATH" ]]; then
        local base_url
        base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$CLAUDE_SETTINGS_PATH" 2>/dev/null)
        if [[ "$base_url" == *"z.ai"* ]]; then
            provider="GLM"
        fi
    fi
    
    # Set terminal title (works in xterm, gnome-terminal, etc.)
    echo -ne "\033]0;[$provider] ${SHELL##*/}\007"
}

# =============================================================================
# Function to toggle between providers
# =============================================================================
cswitch() {
    local provider="${1:-Toggle}"
    
    # Call the switch script
    bash "$CLAUDE_SCRIPT_PATH/switch_provider.sh" "$provider"
    
    # Update window title after switch
    Set-ClaudeWindowTitle
}

# =============================================================================
# Launch Claude with GLM provider (safe - uses environment variables)
# =============================================================================
claudeglm() {
    bash "$CLAUDE_SCRIPT_PATH/claudeglm.sh" "$@"
}

# =============================================================================
# Clear GLM environment variables to return to Anthropic
# =============================================================================
claude-reset() {
    echo -e "${_C_YELLOW}Clearing GLM environment variables...${_C_NC}"
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_DEFAULT_SONNET_MODEL
    unset ANTHROPIC_DEFAULT_OPUS_MODEL
    unset ANTHROPIC_DEFAULT_HAIKU_MODEL
    echo -e "${_C_GREEN}✅ Reset to Anthropic (default)${_C_NC}"
    echo -e "${_C_GRAY}You can now run 'claude' normally${_C_NC}"
}

# =============================================================================
# Quick info function
# =============================================================================
claude-info() {
    _claude_check_jq || return 1
    
    if [[ -f "$CLAUDE_SETTINGS_PATH" ]]; then
        local settings base_url sonnet opus haiku provider
        
        # Check if env exists and has ANTHROPIC_BASE_URL
        base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$CLAUDE_SETTINGS_PATH" 2>/dev/null)
        
        if [[ "$base_url" == *"z.ai"* ]]; then
            provider="GLM (Z.AI)"
        else
            provider="Anthropic"
        fi
        
        # Get values or defaults
        if [[ -n "$base_url" ]]; then
            sonnet=$(jq -r '.env.ANTHROPIC_DEFAULT_SONNET_MODEL // "default"' "$CLAUDE_SETTINGS_PATH" 2>/dev/null)
            opus=$(jq -r '.env.ANTHROPIC_DEFAULT_OPUS_MODEL // "default"' "$CLAUDE_SETTINGS_PATH" 2>/dev/null)
            haiku=$(jq -r '.env.ANTHROPIC_DEFAULT_HAIKU_MODEL // "default"' "$CLAUDE_SETTINGS_PATH" 2>/dev/null)
        else
            base_url="default (Anthropic)"
            sonnet="default"
            opus="default"
            haiku="default"
        fi
        
        echo ""
        echo -e "${_C_CYAN}=== Claude Code Configuration ===${_C_NC}"
        echo -e "${_C_WHITE}  Provider: $provider${_C_NC}"
        echo -e "${_C_GRAY}  Base URL: $base_url${_C_NC}"
        echo -e "${_C_GRAY}  Sonnet: $sonnet${_C_NC}"
        echo -e "${_C_GRAY}  Opus: $opus${_C_NC}"
        echo -e "${_C_GRAY}  Haiku: $haiku${_C_NC}"
        echo ""
        echo -e "${_C_YELLOW}Commands:${_C_NC}"
        echo -e "${_C_WHITE}  cswitch          - Toggle between GLM and Anthropic${_C_NC}"
        echo -e "${_C_WHITE}  cswitch GLM      - Switch to GLM provider${_C_NC}"
        echo -e "${_C_WHITE}  cswitch Anthropic - Switch to Anthropic provider${_C_NC}"
        echo -e "${_C_WHITE}  claudeglm        - Launch Claude with GLM (session only)${_C_NC}"
        echo -e "${_C_WHITE}  claude           - Launch Claude with default provider${_C_NC}"
        echo -e "${_C_WHITE}  claude-info      - Show this info${_C_NC}"
        echo ""
    else
        echo -e "${_C_RED}Settings file not found at: $CLAUDE_SETTINGS_PATH${_C_NC}"
        return 1
    fi
}

# =============================================================================
# Hint function - shows all custom shortcuts
# =============================================================================
hint() {
    echo ""
    echo -e "${_C_CYAN}=== Custom Shortcuts & Actions ===${_C_NC}"
    echo ""
    
    echo -e "${_C_YELLOW}Claude Code Provider Management:${_C_NC}"
    echo -e "${_C_WHITE}  cswitch          - Toggle between GLM and Anthropic providers${_C_NC}"
    echo -e "${_C_WHITE}  cswitch GLM      - Switch to GLM (Z.AI) provider${_C_NC}"
    echo -e "${_C_WHITE}  cswitch Anthropic - Switch to Anthropic provider${_C_NC}"
    echo -e "${_C_GREEN}  claudeglm        - Launch Claude with GLM (safe, uses env vars)${_C_NC}"
    echo -e "${_C_YELLOW}  claude-reset     - Clear GLM env vars to return to Anthropic${_C_NC}"
    echo -e "${_C_WHITE}  claude-info      - Show current Claude provider configuration${_C_NC}"
    echo ""
    
    echo -e "${_C_YELLOW}Visual Indicators:${_C_NC}"
    echo -e "${_C_WHITE}  Window title shows [GLM] or [Anthropic] prefix${_C_NC}"
    echo -e "${_C_WHITE}  Title updates automatically when switching providers${_C_NC}"
    echo ""
    
    echo -e "${_C_YELLOW}Help & Info:${_C_NC}"
    echo -e "${_C_WHITE}  hint / hh        - Show this custom shortcuts legend${_C_NC}"
    echo -e "${_C_WHITE}  claude-info      - Show Claude provider configuration details${_C_NC}"
    echo ""
    
    echo -e "${_C_MAGENTA}Tips:${_C_NC}"
    echo -e "${_C_GRAY}  - Use 'claudeglm' for one-off GLM sessions (safe with concurrent Claude)${_C_NC}"
    echo -e "${_C_GRAY}  - Use 'cswitch' to permanently change your default provider${_C_NC}"
    echo -e "${_C_GRAY}  - Check window title to see current provider at a glance${_C_NC}"
    echo ""
}

# Short alias for hint (hh to avoid conflicts)
hh() { hint; }

# =============================================================================
# Set initial title on profile load
# =============================================================================
Set-ClaudeWindowTitle 2>/dev/null

# Functions are available when this script is sourced
