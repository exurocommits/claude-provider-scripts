# Claude Code Provider Switching Scripts

Cross-platform scripts for seamlessly switching between Anthropic, ZAI/GLM, and Alibaba Cloud model providers in Claude Code CLI, with automatic session integrity repair for foreign-provider sessions.

**Platform Support:**
- **Windows** - PowerShell scripts (this directory)
- **Linux/macOS** - Bash scripts ([`linux/` folder](./linux/README.md))

## Why This Exists

These scripts solve two problems when using Claude Code with alternative LLM providers:

1. **Provider switching** - Instantly switch between Anthropic, GLM (Z.AI), and Alibaba Cloud (Qwen) without manually editing config files.
2. **Session integrity** - Sessions created under a foreign provider (GLM, Alibaba) contain non-Anthropic message formats (model IDs, tool call IDs, usage fields). Resuming these sessions on Anthropic causes errors. The session repair system automatically normalizes foreign messages before resume.

## Features

- **One-command switching** between providers (`cswitch`)
- **Session-only launchers** - `claudeglm` / `claudeali` use env vars, never touch `settings.json`
- **Automatic session tagging** - Launchers record which provider created each session
- **Session repair on resume** - `claude-resume` auto-detects and repairs foreign sessions before resuming
- **Manual repair tools** - `claude-repair` and `claude-check` for targeted diagnostics
- **Visual indicators** - Window title shows current provider ([GLM], [Alibaba], or [Anthropic])
- **Flag passthrough** - All commands pass extra flags directly to `claude` CLI
- **Built-in help** - Type `hint` to see all available commands

## Prerequisites

### Windows
- Windows 11 with PowerShell 7+
- Claude Code CLI installed
- Z.AI API key (if using GLM models): https://z.ai/manage-apikey/apikey-list

### Linux/macOS
- Bash 4+ or Zsh
- `jq` (JSON processor)
- `node` (for session repair)
- See [`linux/README.md`](./linux/README.md) for full installation instructions

## Installation

### Linux/macOS

1. Clone this repo or copy the files to `~/scripts/`:
   ```bash
   git clone https://github.com/exurocommits/claude-provider-scripts.git ~/scripts
   ```

2. Source the profile in your shell config (`~/.bashrc` or `~/.zshrc`):
   ```bash
   source ~/scripts/linux/claude_profile.sh
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc   # or source ~/.zshrc
   ```

### Windows (PowerShell)

1. Place scripts in `C:\Users\<YourUsername>\.claude\scripts\`
2. Add to your PowerShell profile (`$PROFILE`):
   ```powershell
   $claudeProfilePath = "$env:USERPROFILE\scripts\ClaudeProfile.ps1"
   if (Test-Path $claudeProfilePath) { . $claudeProfilePath }
   ```
3. Restart PowerShell or run `. $PROFILE`

## Commands Reference

### Provider Switching

| Command | Description |
|---------|-------------|
| `cswitch` | Toggle between GLM and Anthropic |
| `cswitch GLM` | Switch to GLM provider |
| `cswitch Anthropic` | Switch to Anthropic provider |
| `claudeglm [flags]` | Launch single session with GLM (env vars only) |
| `claudeali [flags]` | Launch single session with Alibaba/Qwen (env vars only) |
| `claude-reset` | Clear custom env vars, return to Anthropic |
| `claude-info` | Show current provider configuration |
| `hint` / `hh` | Show all custom shortcuts |

### Session Repair

| Command | Description |
|---------|-------------|
| `claude-resume` | Repair all foreign sessions, then `claude -r` |
| `claude-resume <uuid>` | Repair specific session, then `claude --resume <uuid>` |
| `claude-repair <uuid>` | Repair a specific session file |
| `claude-repair --all` | Repair all tagged foreign sessions |
| `claude-check <uuid>` | Dry-run check a session for issues (no changes) |

### Flag Passthrough Examples

All commands pass extra arguments through to the `claude` CLI:

```bash
# Resume last session with auto-repair, skip permission prompts
claude-resume --dangerously-skip-permissions

# Resume specific session with skip permissions
claude-resume abc12345-1234-5678-9abc-def012345678 --dangerously-skip-permissions

# Launch GLM session and resume last conversation
claudeglm -r

# Launch Alibaba session with custom flags
claudeali --dangerously-skip-permissions
```

## Session Repair System

### The Problem

When you use a foreign provider (GLM, Alibaba) to run a Claude Code session, the session JSONL file contains provider-specific formats:
- Non-`claude-*` model IDs (e.g., `glm-4.7`)
- Non-`msg_` message IDs
- Non-`toolu_` tool use IDs
- OpenAI-style usage fields (`prompt_tokens` instead of `input_tokens`)
- Non-standard `stop_reason` values (`stop` instead of `end_turn`)

Resuming such a session on Anthropic fails because the API rejects these formats.

### The Solution

The repair system (`lib/session-repair.mjs`) normalizes foreign messages:
- Model IDs remapped to `claude-sonnet-4-5-20250514`
- Message IDs regenerated with `msg_` prefix
- Tool use IDs sanitized to `toolu_` prefix
- Corresponding `tool_result.tool_use_id` references updated to match
- Usage fields converted from OpenAI to Anthropic format
- Stop reasons mapped (`stop` -> `end_turn`, `tool_calls` -> `tool_use`)
- Content blocks sorted: thinking -> text -> tool_use
- Original session backed up to `~/.claude/session_backups/`

### How Tagging Works

When you launch via `claudeglm` or `claudeali`, the launcher:
1. Snapshots the session index before launch
2. Runs `claude` with the provider env vars
3. Diffs the session index after exit
4. Tags new sessions in `~/.claude/session_providers.json` with provider and timestamp

The guard (`lib/session-guard.mjs`) uses these tags to detect foreign sessions. It also falls back to scanning the JSONL for non-`claude-*` model IDs if no tag is found.

## How It Works

### Configuration Files

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Provider config (modified by `cswitch`) |
| `~/.claude/api_keys_backup.json` | Stored API keys for quick switching |
| `~/.claude/session_providers.json` | Session-to-provider tag map (auto-generated) |
| `~/.claude/session_backups/` | Pre-repair backups of session JSONL files |

### GLM Configuration

When switching to GLM, the scripts set these environment variables (or `settings.json` fields):
```json
{
  "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
  "ANTHROPIC_AUTH_TOKEN": "<your-zai-api-key>",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.7",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
}
```

## Troubleshooting

### "API key required" error
Run `cswitch GLM` and enter your Z.AI API key when prompted.

### Session resume fails after provider switch
Run `claude-repair <session-uuid>` or `claude-resume` (which auto-repairs).

### Settings not updating
- Ensure `~/.claude/settings.json` exists
- Check file permissions
- Try reloading your shell profile

### Provider not switching
- Close all Claude Code instances
- Run `cswitch` again
- Open new terminal and verify with `claude-info`

## Script Architecture

```
claude-provider-scripts/
  ClaudeProfile.ps1          # Windows: profile with all shell functions
  Switch-ClaudeProvider.ps1  # Windows: core switching logic
  claudeglm.ps1             # Windows: GLM session launcher
  lib/
    session-repair.mjs       # Core repair engine (normalize foreign JSONL)
    session-guard.mjs        # Pre-resume guard (detect + trigger repair)
  linux/
    claude_profile.sh        # Linux/macOS: profile with all shell functions
    claudeglm.sh             # Linux/macOS: GLM session launcher + tagger
    claudeali.sh             # Linux/macOS: Alibaba session launcher + tagger
    claude-resume.sh         # Linux/macOS: auto-repair + resume wrapper
    install.sh               # Linux/macOS: installer script
  glm-implementation-skill/  # Skill definition for GLM implementation
```

## Security Notes

- API keys are stored locally in `~/.claude/api_keys_backup.json` (chmod 600)
- Never commit API keys to version control
- The `.gitignore` excludes sensitive files and backups

## License

MIT License - Feel free to modify and distribute.

## Contributing

Issues and pull requests welcome at: https://github.com/exurocommits/claude-provider-scripts
