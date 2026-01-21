# Claude Code Provider Switching Scripts (Linux/macOS)

Bash scripts for seamlessly switching between Anthropic Claude and ZAI/GLM model providers in Claude Code CLI.

> **Ported from:** [exurocommits/claude-provider-scripts](https://github.com/exurocommits/claude-provider-scripts) (PowerShell version)

## Why This Exists

These scripts solve the problem of switching between different LLM providers while using Claude Code:

- **Anthropic Claude** - Your subscription-based models (Sonnet, Opus, Haiku)
- **ZAI/GLM Models** - Alternative providers (glm-4.7, glm-4.5-air) via Z.AI

Instead of manually editing configuration files, these scripts provide instant provider switching with simple commands.

## Features

- 🔄 **One-command switching** between providers
- 🚀 **Session-specific launches** - Use GLM for single sessions without changing defaults
- 🔐 **Secure API key storage** - Keys stored in `~/.claude/api_keys_backup.json`
- 🎨 **Visual indicators** - Terminal title shows `[GLM]` or `[Anthropic]` prefix
- 📋 **Built-in help** - Type `hint` to see all available commands

### Key Feature: Two Switching Modes

| Command | Scope | Modifies Config | Use Case |
|---------|-------|-----------------|----------|
| `cswitch GLM` | **Permanent** | ✅ Yes (`settings.json`) | Change your default provider |
| `claudeglm` | **Session only** | ❌ No (env vars only) | One-off GLM session, safe for concurrent use |

## Prerequisites

- Linux or macOS
- Bash or Zsh shell
- **jq** (JSON processor) - required
- Claude Code CLI installed
- Z.AI API key (for GLM) - Get yours at: https://z.ai/manage-apikey/apikey-list

## Installation

### Step 1: Install jq

```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# Fedora
sudo dnf install jq

# Arch
sudo pacman -S jq
```

### Step 2: Download the scripts

```bash
# Create scripts directory
mkdir -p ~/scripts
cd ~/scripts

# Download files (or clone repo)
# Place claude_profile.sh, switch_provider.sh, claudeglm.sh here
```

### Step 3: Make scripts executable

```bash
chmod +x ~/scripts/switch_provider.sh
chmod +x ~/scripts/claudeglm.sh
```

### Step 4: Add to your shell profile

```bash
# For Bash
echo 'source ~/scripts/claude_profile.sh' >> ~/.bashrc

# For Zsh
echo 'source ~/scripts/claude_profile.sh' >> ~/.zshrc
```

### Step 5: Reload your shell

```bash
source ~/.bashrc   # or source ~/.zshrc
```

## Usage

### Quick Commands

| Command | Description |
|---------|-------------|
| `cswitch` | Toggle between GLM and Anthropic |
| `cswitch GLM` | Switch to GLM provider (permanent) |
| `cswitch Anthropic` | Switch to Anthropic provider (permanent) |
| `claudeglm` | Launch Claude with GLM (session only) |
| `claude-info` | Show current provider configuration |
| `claude-reset` | Clear GLM env vars to return to Anthropic |
| `hint` or `hh` | Show all available commands |

### Examples

**Toggle between providers:**
```bash
cswitch
# Output: Switching to GLM (Z.AI) provider...
# Or: Switching to Anthropic provider (uses your login subscription)...
```

**Switch to GLM (permanent):**
```bash
cswitch GLM
```
- First time: prompts for Z.AI API key
- Saves key to `~/.claude/api_keys_backup.json`
- Updates `~/.claude/settings.json`
- All future `claude` commands use GLM

**Switch to Anthropic (permanent):**
```bash
cswitch Anthropic
```
- Removes GLM configuration from settings
- Reverts to your Claude subscription models

**Launch single GLM session (safe for concurrent use):**
```bash
claudeglm
```
Output:
```
=== Launching Claude Code with GLM Provider ===
✅ Using ENVIRONMENT VARIABLES (safe for concurrent sessions)
✅ Does NOT modify settings.json

Provider: GLM (Z.AI)
Models: Sonnet/Opus → glm-4.7, Haiku → glm-4.5-air

Launching Claude Code...
```

**Pass arguments to claudeglm:**
```bash
claudeglm --resume              # Resume session with GLM
claudeglm -p "explain this"     # Single prompt with GLM
```

**Check current configuration:**
```bash
claude-info
```
Output:
```
=== Claude Code Configuration ===
  Provider: GLM (Z.AI)
  Base URL: https://api.z.ai/api/anthropic
  Sonnet: glm-4.7
  Opus: glm-4.7
  Haiku: glm-4.5-air

Commands:
  cswitch          - Toggle between GLM and Anthropic
  ...
```

## How It Works

### Permanent Switching (`cswitch`)

Modifies `~/.claude/settings.json` to set/remove the `env` block:

**GLM Configuration:**
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "your-api-key",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
  }
}
```

**Anthropic Configuration:**
Removes the `env` block entirely, reverting to defaults.

### Session-Only Switching (`claudeglm`)

Sets environment variables **only for that process**:
- Does NOT touch `settings.json`
- Other terminals remain unaffected
- Perfect for one-off GLM sessions

### API Key Storage

Keys stored in `~/.claude/api_keys_backup.json`:
```json
{"GLM": "your-api-key"}
```
File permissions set to `600` (owner read/write only).

## File Structure

```
~/.claude/
├── settings.json           # Claude Code settings (managed by cswitch)
└── api_keys_backup.json    # Your GLM API key (secure storage)

~/scripts/
├── claude_profile.sh       # Main profile (source this in .bashrc/.zshrc)
├── switch_provider.sh      # Standalone switching script
└── claudeglm.sh            # Session-only GLM launcher
```

## Visual Indicators

Terminal title automatically updates:
- `[GLM] bash` - Using GLM provider
- `[Anthropic] bash` - Using Anthropic provider

## Troubleshooting

### "jq: command not found"
Install jq - see Prerequisites section.

### "Settings file not found"
Claude Code creates `~/.claude/settings.json` on first run. Run `claude` once first.

### API key not being saved
Check file permissions:
```bash
ls -la ~/.claude/
```

### Title not updating
Some terminals don't support title changes. Functionality still works.

## Uninstalling

```bash
# Remove scripts
rm ~/scripts/claude_profile.sh
rm ~/scripts/switch_provider.sh
rm ~/scripts/claudeglm.sh

# Remove source line from shell profile
# Edit ~/.bashrc or ~/.zshrc and remove the line:
#   source ~/scripts/claude_profile.sh
```

Your API keys (`~/.claude/api_keys_backup.json`) are NOT removed automatically.

## License

MIT License - Feel free to modify and distribute.

## Credits

- Original PowerShell version: [exurocommits/claude-provider-scripts](https://github.com/exurocommits/claude-provider-scripts)
