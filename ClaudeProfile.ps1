# Claude Code Provider Switching Profile
# Add this to your PowerShell profile or run it to enable the shortcuts

# Path to scripts
$scriptPath = "$env:USERPROFILE\scripts"

# Store original title when profile loads
$script:originalTitle = $Host.UI.RawUI.WindowTitle

# Function to set window title with provider indicator
function Set-ClaudeWindowTitle {
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    $provider = "Anthropic"

    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        $hasEnv = $settings.PSObject.Properties['env']
        $baseUrl = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) { $settings.env.ANTHROPIC_BASE_URL } else { $null }
        if ($baseUrl -match 'z\.ai') {
            $provider = "GLM"
        }
    }

    $cleanTitle = $Host.UI.RawUI.WindowTitle -replace '\[GLM\] ', '' -replace '\[Anthropic\] ', ''
    $Host.UI.RawUI.WindowTitle = "[$provider] $cleanTitle"
}

# Function to restore original title
function Restore-ClaudeWindowTitle {
    $Host.UI.RawUI.WindowTitle = $script:originalTitle
}

# Set initial title
Set-ClaudeWindowTitle

# Function to toggle between providers
function cswitch {
    param(
        [Parameter(Position = 0)]
        [ValidateSet('GLM', 'Anthropic', 'Toggle')]
        [string]$Provider = 'Toggle'
    )

    & "$scriptPath\Switch-ClaudeProvider.ps1" -Provider $Provider
    Set-ClaudeWindowTitle
}

# Launch Claude with GLM provider (safe - uses environment variables)
function claudeglm {
    & "$scriptPath\claudeglm.ps1" @Args
}

# Clear GLM environment variables to return to Anthropic
function claude-reset {
    Write-Host "Clearing GLM environment variables..." -ForegroundColor Yellow
    Remove-Item Env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_SONNET_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_OPUS_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:ANTHROPIC_DEFAULT_HAIKU_MODEL -ErrorAction SilentlyContinue
    Write-Host "✅ Reset to Anthropic (default)" -ForegroundColor Green
    Write-Host "You can now run 'claude' normally" -ForegroundColor Gray
}

# Quick info function
function claude-info {
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

        $hasEnv = $settings.PSObject.Properties['env']
        $envBaseUrl = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) { $settings.env.ANTHROPIC_BASE_URL } else { $null }

        $provider = if ($envBaseUrl -match 'z\.ai') {
            'GLM (Z.AI)'
        } else {
            'Anthropic'
        }

        $baseUrl = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) { $settings.env.ANTHROPIC_BASE_URL } else { 'default (Anthropic)' }
        $sonnet = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_SONNET_MODEL']) { $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL } else { 'default' }
        $opus = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_OPUS_MODEL']) { $settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL } else { 'default' }
        $haiku = if ($hasEnv -and $settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_HAIKU_MODEL']) { $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL } else { 'default' }

        Write-Host ""
        Write-Host "=== Claude Code Configuration ===" -ForegroundColor Cyan
        Write-Host "  Provider: $provider" -ForegroundColor White
        Write-Host "  Base URL: $baseUrl" -ForegroundColor Gray
        Write-Host "  Sonnet: $sonnet" -ForegroundColor Gray
        Write-Host "  Opus: $opus" -ForegroundColor Gray
        Write-Host "  Haiku: $haiku" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  cswitch          - Toggle between GLM and Anthropic" -ForegroundColor White
        Write-Host "  cswitch GLM      - Switch to GLM provider" -ForegroundColor White
        Write-Host "  cswitch Anthropic - Switch to Anthropic provider" -ForegroundColor White
        Write-Host "  claudeglm        - Launch Claude with GLM (session only)" -ForegroundColor White
        Write-Host "  claude           - Launch Claude with default provider" -ForegroundColor White
        Write-Host "  claude-info      - Show this info" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Error "Settings file not found at: $settingsPath"
    }
}

# Hint function - shows all custom shortcuts
function hint {
    Write-Host ""
    Write-Host "=== Custom Shortcuts & Actions ===" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Claude Code Provider Management:" -ForegroundColor Yellow
    Write-Host "  cswitch          - Toggle between GLM and Anthropic providers" -ForegroundColor White
    Write-Host "  cswitch GLM      - Switch to GLM (Z.AI) provider" -ForegroundColor White
    Write-Host "  cswitch Anthropic - Switch to Anthropic provider" -ForegroundColor White
    Write-Host "  claudeglm        - Launch Claude with GLM (safe, uses env vars)" -ForegroundColor Green
    Write-Host "  claude-reset     - Clear GLM env vars to return to Anthropic" -ForegroundColor Yellow
    Write-Host "  claude-info      - Show current Claude provider configuration" -ForegroundColor White
    Write-Host ""

    Write-Host "Visual Indicators:" -ForegroundColor Yellow
    Write-Host "  Window title shows [GLM] or [Anthropic] prefix" -ForegroundColor White
    Write-Host "  Title updates automatically when switching providers" -ForegroundColor White
    Write-Host ""

    Write-Host "Navigation and Utilities:" -ForegroundColor Yellow
    Write-Host "  dev              - Quick cd to C:\dev" -ForegroundColor White
    Write-Host "  cursor           - Launch Cursor editor" -ForegroundColor White
    Write-Host ""

    Write-Host "Help & Info:" -ForegroundColor Yellow
    Write-Host "  hint / hh       - Show this custom shortcuts legend" -ForegroundColor White
    Write-Host "  claude-info      - Show Claude provider configuration details" -ForegroundColor White
    Write-Host ""

    Write-Host "Tips:" -ForegroundColor Magenta
    Write-Host "  - Use 'claudeglm' for one-off GLM sessions (safe with concurrent Claude)" -ForegroundColor Gray
    Write-Host "  - Use 'cswitch' to permanently change your default provider" -ForegroundColor Gray
    Write-Host "  - Check window title to see current provider at a glance" -ForegroundColor Gray
    Write-Host ""
}

# Short alias for hint (hh to avoid conflict with built-in 'h' history alias)
function hh { hint }

# Functions are available when this script is dot-sourced
