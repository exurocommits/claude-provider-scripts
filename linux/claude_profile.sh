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
        elif [[ "$base_url" == *"dashscope"* ]]; then
            provider="Alibaba"
        fi
    fi
    
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
# Launch Claude with Alibaba Cloud provider (safe - uses environment variables)
# =============================================================================
claudeali() {
    bash "$CLAUDE_SCRIPT_PATH/claudeali.sh" "$@"
}

# =============================================================================
# Clear GLM/Alibaba environment variables to return to Anthropic
# =============================================================================
claude-reset() {
    echo -e "${_C_YELLOW}Clearing custom provider environment variables...${_C_NC}"
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
        elif [[ "$base_url" == *"dashscope"* ]]; then
            provider="Alibaba Cloud (Qwen)"
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
        echo -e "${_C_WHITE}  cswitch           - Toggle between GLM and Anthropic${_C_NC}"
        echo -e "${_C_WHITE}  cswitch GLM       - Switch to GLM provider${_C_NC}"
        echo -e "${_C_WHITE}  cswitch Anthropic - Switch to Anthropic provider${_C_NC}"
        echo -e "${_C_GREEN}  claudeglm        - Launch Claude with GLM (session only)${_C_NC}"
        echo -e "${_C_GREEN}  claudeali        - Launch Claude with Alibaba (session only)${_C_NC}"
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
    echo -e "${_C_GREEN}  claudeali        - Launch Claude with Alibaba (Qwen, safe)${_C_NC}"
    echo -e "${_C_GREEN}  claude-resume    - Resume session with auto-repair + flag passthrough${_C_NC}"
    echo -e "${_C_GREEN}  claude-repair    - Repair a session: claude-repair <uuid> | --all${_C_NC}"
    echo -e "${_C_GREEN}  claude-check     - Dry-run check a session for issues${_C_NC}"
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
    echo -e "${_C_GRAY}  - Use 'claudeali' for one-off Alibaba sessions (safe with concurrent Claude)${_C_NC}"
    echo -e "${_C_GRAY}  - Use 'cswitch' to permanently change your default provider${_C_NC}"
    echo -e "${_C_GRAY}  - Check window title to see current provider at a glance${_C_NC}"
    echo ""
}

# =============================================================================
# Resume a session with automatic provider-aware repair
# Usage: claude-resume <uuid> [--dangerously-skip-permissions] [other flags]
# =============================================================================
claude-resume() {
    local script_dir
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$CLAUDE_SCRIPT_PATH"
    fi
    bash "$script_dir/claude-resume.sh" "$@"
}

# =============================================================================
# Session repair shortcuts (friendly names for node commands)
# =============================================================================
claude-repair() {
    # Repair a specific session or all foreign sessions
    # Usage: claude-repair <uuid>   OR   claude-repair --all
    local script_dir
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$CLAUDE_SCRIPT_PATH"
    fi
    node "$script_dir/../lib/session-repair.mjs" "$@"
}

claude-check() {
    # Dry-run check a session for foreign provider issues
    # Usage: claude-check <uuid>
    local script_dir
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        script_dir="$CLAUDE_SCRIPT_PATH"
    fi
    node "$script_dir/../lib/session-repair.mjs" --check "$@"
}

# =============================================================================
# Set initial title on profile load
# =============================================================================
Set-ClaudeWindowTitle 2>/dev/null

# Functions are available when this script is sourced
