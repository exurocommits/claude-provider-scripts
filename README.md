# Claude Code Provider Switching Scripts

Cross-platform scripts for seamlessly switching between Anthropic Claude and ZAI/GLM model providers in Claude Code CLI.

**📂 Platform Support:**
- **Windows** - PowerShell scripts (this directory)
- **Linux/macOS** - Bash scripts ([`linux/` folder](./linux/README.md))

## Why This Exists

These scripts solve the problem of switching between different LLM providers while using Claude Code:
- **Anthropic Claude** - Your subscription-based models (Sonnet, Opus, Haiku)
- **ZAI/GLM Models** - Alternative providers (glm-4.7, glm-4.5-air) via Z.AI

Instead of manually editing configuration files, these scripts provide instant provider switching with simple commands.

## Features

- 🔄 **One-command switching** between providers
- 🎨 **Visual indicators** - Window title shows current provider ([GLM] or [Anthropic])
- 🔐 **Secure API key storage** - Keys stored separately and loaded automatically
- 🚀 **Session-specific launches** - Use GLM for single sessions without changing defaults
- 📋 **Built-in help** - Type `hint` to see all available commands

## Prerequisites

### Windows (This Guide)
- Windows 11 with PowerShell 7+
- Claude Code CLI installed
- Git Bash or similar (for running the scripts)
- Z.AI API key (if using GLM models) - Get yours at: https://z.ai/manage-apikey/apikey-list

### Linux/macOS
**→ See [`linux/README.md`](./linux/README.md) for Linux/macOS installation**

## Installation

### 1. Clone or Copy Scripts

Place these files in `C:\Users\<YourUsername>\scripts\`:
- `ClaudeProfile.ps1`
- `Switch-ClaudeProvider.ps1`
- `claudeglm.ps1`

### 2. Update PowerShell Profile

Add this to your PowerShell profile (`$PROFILE` or `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`):

```powershell
# Claude Code Provider Switching
$claudeProfilePath = "$env:USERPROFILE\scripts\ClaudeProfile.ps1"
if (Test-Path $claudeProfilePath) {
    . $claudeProfilePath
}
```

### 3. Reload Profile

Restart PowerShell or run:
```powershell
. $PROFILE
```

## Usage

### Quick Commands

| Command | Description |
|---------|-------------|
| `cswitch` | Toggle between GLM and Anthropic |
| `cswitch GLM` | Switch to GLM provider |
| `cswitch Anthropic` | Switch to Anthropic provider |
| `claudeglm` | Launch Claude with GLM (session only) |
| `claude-info` | Show current provider configuration |
| `claude-reset` | Clear GLM env vars, return to Anthropic |
| `hint` or `hh` | Show all custom shortcuts |

### Examples

**Switch to GLM models:**
```powershell
cswitch GLM
```
- Prompts for Z.AI API key (first time only)
- Updates `~\.claude\settings.json`
- Sets window title to `[GLM]`

**Switch back to Anthropic:**
```powershell
cswitch Anthropic
```
- Removes GLM configuration
- Reverts to Claude subscription models
- Sets window title to `[Anthropic]`

**Launch single GLM session (safe for concurrent use):**
```powershell
claudeglm
```
- Uses environment variables only
- Doesn't modify settings.json
- Run Claude normally in other terminals

**Check current configuration:**
```powershell
claude-info
```
Shows:
- Active provider
- Base URL
- Model mappings (Sonnet/Opus/Haiku)

### Visual Indicators

Your terminal window title automatically updates:
- `[GLM] PowerShell` - Using GLM models
- `[Anthropic] PowerShell` - Using Claude subscription

## How It Works

### Configuration Files

**Settings File:** `~\.claude\settings.json`
- Modified by `cswitch` command
- Contains provider configuration in `env` section

**API Key Backup:** `~\.claude\api_keys_backup.json`
- Stores GLM API key securely
- Loaded automatically on switch

### GLM Configuration

When switching to GLM, the scripts set:
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "your-zai-api-key",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
  }
}
```

### Anthropic Configuration

When switching to Anthropic, the scripts:
1. Remove all GLM-specific environment variables
2. Remove the entire `env` section if empty
3. Claude Code defaults to subscription models

## Troubleshooting

### "API key required" error
Run `cswitch GLM` and enter your Z.AI API key when prompted.

### Settings not updating
- Ensure `~\.claude\settings.json` exists
- Check file permissions
- Try running PowerShell as administrator

### Provider not switching
- Close all Claude Code instances
- Run `cswitch` again
- Open new terminal to verify with `claude-info`

### Window title not updating
Reload profile: `. $PROFILE`

### Authentication errors with Anthropic
- Run `claude` CLI to re-authenticate
- Ensure you're logged in: Check for OAuth token at `~\.claude\oauth_token.json`

## Script Details

### ClaudeProfile.ps1
Main profile script containing:
- `cswitch` - Provider switching function
- `claudeglm` - GLM launcher
- `claude-reset` - Environment cleaner
- `claude-info` - Configuration viewer
- `hint` - Help command
- Window title management

### Switch-ClaudeProvider.ps1
Core switching logic:
- Reads/writes settings.json
- Manages API key storage
- Toggles provider configuration
- Validates settings

### claudeglm.ps1
Session-specific GLM launcher:
- Sets environment variables
- Launches Claude Code
- Doesn't modify global settings

## Tips

- Use `claudeglm` for one-off GLM sessions while keeping Anthropic as default
- Use `cswitch` to permanently change your default provider
- Check window title at a glance to see current provider
- Run `hint` if you forget the commands

## Security Notes

- API keys are stored locally in `~\.claude\api_keys_backup.json`
- Never commit API keys to version control
- The `.gitignore` excludes sensitive files

## License

MIT License - Feel free to modify and distribute

## Contributing

Issues and pull requests welcome at: https://github.com/exurocommits/claude-provider-scripts
