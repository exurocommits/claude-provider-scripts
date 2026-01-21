#!/bin/bash
# =============================================================================
# Claude Provider Scripts - Linux Installer
# =============================================================================
#
# This script installs the Claude provider switching scripts.
#
# Usage:
#   ./install.sh              # Install to ~/scripts/
#   ./install.sh /custom/path # Install to custom directory
#   ./install.sh --uninstall  # Remove installation
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default install directory
INSTALL_DIR="${1:-$HOME/scripts}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Functions
# =============================================================================

check_dependencies() {
    echo -e "${CYAN}Checking dependencies...${NC}"
    
    local missing=()
    
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if ! command -v claude &> /dev/null; then
        echo -e "${YELLOW}Warning: 'claude' command not found.${NC}"
        echo "Make sure Claude Code CLI is installed before using these scripts."
        echo "Install: npm install -g @anthropic-ai/claude-code"
        echo
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing required dependencies: ${missing[*]}${NC}"
        echo
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "  macOS:         brew install ${missing[*]}"
        echo "  Fedora:        sudo dnf install ${missing[*]}"
        echo
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies satisfied${NC}"
}

install_scripts() {
    echo -e "${CYAN}Installing to: $INSTALL_DIR${NC}"
    
    # Create directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy scripts
    cp "$SCRIPT_DIR/claude_profile.sh" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/switch_provider.sh" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/claudeglm.sh" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/claude_provider_config.sh" "$INSTALL_DIR/"
    
    # Make executable
    chmod +x "$INSTALL_DIR/switch_provider.sh"
    chmod +x "$INSTALL_DIR/claudeglm.sh"
    
    echo -e "${GREEN}✓ Scripts installed${NC}"
    
    # Detect shell
    local shell_rc=""
    local shell_name=""
    
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
        shell_name="zsh"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
        shell_name="bash"
    fi
    
    # Check if already installed
    local source_line="source \"$INSTALL_DIR/claude_profile.sh\""
    
    if [[ -n "$shell_rc" ]]; then
        if grep -qF "claude_profile.sh" "$shell_rc" 2>/dev/null; then
            echo -e "${YELLOW}Note: claude_profile.sh already sourced in $shell_rc${NC}"
        else
            echo
            echo -e "${CYAN}Add to your $shell_rc:${NC}"
            echo
            echo -e "  ${GREEN}$source_line${NC}"
            echo
            echo -n "Add automatically? [y/N]: "
            read -r add_auto
            
            if [[ "$add_auto" =~ ^[Yy]$ ]]; then
                echo "" >> "$shell_rc"
                echo "# Claude Provider Switching Scripts" >> "$shell_rc"
                echo "$source_line" >> "$shell_rc"
                echo -e "${GREEN}✓ Added to $shell_rc${NC}"
            fi
        fi
    else
        echo
        echo -e "${YELLOW}Could not detect shell. Add this to your shell profile:${NC}"
        echo -e "  ${GREEN}$source_line${NC}"
    fi
    
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo
    echo "To activate now (without restarting terminal):"
    echo -e "  ${BLUE}source $INSTALL_DIR/claude_profile.sh${NC}"
    echo
    echo "Available commands after activation:"
    echo -e "  ${GREEN}cswitch${NC}           - Toggle between providers"
    echo -e "  ${GREEN}cswitch GLM${NC}       - Switch to GLM (permanent)"
    echo -e "  ${GREEN}cswitch Anthropic${NC} - Switch to Anthropic (permanent)"
    echo -e "  ${GREEN}claudeglm${NC}         - Launch with GLM (session only)"
    echo -e "  ${GREEN}claude-info${NC}       - Show current configuration"
    echo -e "  ${GREEN}hint${NC}              - Show all commands"
    echo
}

uninstall_scripts() {
    echo -e "${CYAN}Uninstalling...${NC}"
    
    # Remove scripts
    rm -f "$INSTALL_DIR/claude_profile.sh"
    rm -f "$INSTALL_DIR/switch_provider.sh"
    rm -f "$INSTALL_DIR/claudeglm.sh"
    rm -f "$INSTALL_DIR/claude_provider_config.sh"
    
    echo -e "${GREEN}✓ Scripts removed${NC}"
    echo
    echo -e "${YELLOW}Note: You may want to remove the source line from your shell profile.${NC}"
    echo "Check ~/.bashrc or ~/.zshrc and remove the line containing 'claude_profile.sh'"
    echo
    echo -e "${YELLOW}API keys and settings are NOT removed:${NC}"
    echo "  ~/.claude/settings.json"
    echo "  ~/.claude/api_keys_backup.json"
}

show_help() {
    cat << 'EOF'
Claude Provider Scripts - Linux Installer

USAGE:
    ./install.sh              Install to ~/scripts/
    ./install.sh /custom/path Install to custom directory
    ./install.sh --uninstall  Remove installation
    ./install.sh --help       Show this help

REQUIREMENTS:
    - jq (JSON processor)
    - Claude Code CLI (optional, for functionality)

WHAT GETS INSTALLED:
    - claude_profile.sh       Main profile script (source this)
    - switch_provider.sh      Standalone switching script
    - claudeglm.sh            Session-only GLM launcher
    - claude_provider_config.sh  Configuration template

After installation, add to your ~/.bashrc or ~/.zshrc:
    source ~/scripts/claude_profile.sh

Then use:
    cswitch           Toggle providers
    claudeglm         Session-only GLM
    claude-info       Show configuration
    hint              Show all commands
EOF
}

# =============================================================================
# Main
# =============================================================================

case "${1:-}" in
    --uninstall|-u)
        uninstall_scripts
        ;;
    --help|-h)
        show_help
        ;;
    *)
        check_dependencies
        install_scripts
        ;;
esac
