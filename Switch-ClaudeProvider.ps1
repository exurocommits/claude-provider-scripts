# Switch-ClaudeProvider.ps1
# Toggles Claude Code between GLM (Z.AI) and Anthropic providers

param(
    [Parameter()]
    [ValidateSet('GLM', 'Anthropic', 'Toggle')]
    [string]$Provider = 'Toggle'
)

$settingsPath = "$env:USERPROFILE\.claude\settings.json"

if (-not (Test-Path $settingsPath)) {
    Write-Error "Settings file not found at: $settingsPath"
    exit 1
}

$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# Ensure env property exists
if (-not $settings.PSObject.Properties['env']) {
    $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{})
}

# Store current provider for toggle logic
$currentBaseUrl = if ($settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) { $settings.env.ANTHROPIC_BASE_URL } else { $null }
$isCurrentGlm = $currentBaseUrl -match 'z\.ai'

# Determine target provider
if ($Provider -eq 'Toggle') {
    $targetProvider = if ($isCurrentGlm) { 'Anthropic' } else { 'GLM' }
} else {
    $targetProvider = $Provider
}

# Define provider configurations
$glmConfig = @{
    ANTHROPIC_BASE_URL = 'https://api.z.ai/api/anthropic'
}

# Apply configuration
if ($targetProvider -eq 'GLM') {
    Write-Host "Switching to GLM (Z.AI) provider..." -ForegroundColor Cyan

    # Check if we have a GLM API key stored
    $backupPath = "$env:USERPROFILE\.claude\api_keys_backup.json"
    $glmApiKey = $null
    if (Test-Path $backupPath) {
        $backupContent = Get-Content $backupPath -Raw | ConvertFrom-Json
        foreach ($prop in $backupContent.PSObject.Properties) {
            if ($prop.Name -eq 'GLM') {
                $glmApiKey = $prop.Value
                break
            }
        }
    }

    if (-not $glmApiKey) {
        Write-Host "GLM API key not found in backup." -ForegroundColor Yellow
        Write-Host "Get your API key from: https://z.ai/manage-apikey/apikey-list" -ForegroundColor Yellow
        $glmApiKey = Read-Host "Enter your Z.AI API key"
        if ($glmApiKey) {
            # Save to backup
            $backup = @{'GLM' = $glmApiKey}
            $backup | ConvertTo-Json | Set-Content $backupPath
        } else {
            Write-Error "API key required for GLM provider"
            exit 1
        }
    }

    # Add or update properties
    if ($settings.env.PSObject.Properties['ANTHROPIC_AUTH_TOKEN']) {
        $settings.env.ANTHROPIC_AUTH_TOKEN = $glmApiKey
    } else {
        $settings.env | Add-Member -NotePropertyName 'ANTHROPIC_AUTH_TOKEN' -NotePropertyValue $glmApiKey
    }

    if ($settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) {
        $settings.env.ANTHROPIC_BASE_URL = $glmConfig.ANTHROPIC_BASE_URL
    } else {
        $settings.env | Add-Member -NotePropertyName 'ANTHROPIC_BASE_URL' -NotePropertyValue $glmConfig.ANTHROPIC_BASE_URL
    }

    if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_SONNET_MODEL']) {
        $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL = 'glm-4.7'
    } else {
        $settings.env | Add-Member -NotePropertyName 'ANTHROPIC_DEFAULT_SONNET_MODEL' -NotePropertyValue 'glm-4.7'
    }

    if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_OPUS_MODEL']) {
        $settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL = 'glm-4.7'
    } else {
        $settings.env | Add-Member -NotePropertyName 'ANTHROPIC_DEFAULT_OPUS_MODEL' -NotePropertyValue 'glm-4.7'
    }

    if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_HAIKU_MODEL']) {
        $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL = 'glm-4.5-air'
    } else {
        $settings.env | Add-Member -NotePropertyName 'ANTHROPIC_DEFAULT_HAIKU_MODEL' -NotePropertyValue 'glm-4.5-air'
    }

} else {
    Write-Host "Switching to Anthropic provider (uses your login subscription)..." -ForegroundColor Cyan

    # Only remove properties if env exists
    if ($settings.PSObject.Properties['env']) {
        # Remove ALL GLM-specific settings to revert to Anthropic defaults
        if ($settings.env.PSObject.Properties['ANTHROPIC_AUTH_TOKEN']) {
            $settings.env.PSObject.Properties.Remove('ANTHROPIC_AUTH_TOKEN')
        }
        if ($settings.env.PSObject.Properties['ANTHROPIC_BASE_URL']) {
            $settings.env.PSObject.Properties.Remove('ANTHROPIC_BASE_URL')
        }
        if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_SONNET_MODEL']) {
            $settings.env.PSObject.Properties.Remove('ANTHROPIC_DEFAULT_SONNET_MODEL')
        }
        if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_OPUS_MODEL']) {
            $settings.env.PSObject.Properties.Remove('ANTHROPIC_DEFAULT_OPUS_MODEL')
        }
        if ($settings.env.PSObject.Properties['ANTHROPIC_DEFAULT_HAIKU_MODEL']) {
            $settings.env.PSObject.Properties.Remove('ANTHROPIC_DEFAULT_HAIKU_MODEL')
        }

        # Remove env section entirely if empty (PowerShell quirk workaround)
        $envCount = 0
        foreach ($prop in $settings.env.PSObject.Properties) {
            $envCount++
        }
        if ($envCount -eq 0) {
            # Create new settings without env
            $newSettings = @{}
            foreach ($prop in $settings.PSObject.Properties) {
                if ($prop.Name -ne 'env') {
                    $newSettings[$prop.Name] = $prop.Value
                }
            }
            # Convert to PSObject
            $settings = [PSCustomObject]$newSettings
        }
    }
}

# Save settings
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

$hasEnv = $settings.PSObject.Properties['env'] -and $settings.env.PSObject.Properties.Count -gt 0
$displayBaseUrl = if ($hasEnv -and $settings.env.ANTHROPIC_BASE_URL) { $settings.env.ANTHROPIC_BASE_URL } else { 'default (Anthropic)' }
$displaySonnet = if ($hasEnv -and $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL) { $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL } else { 'default' }
$displayOpus = if ($hasEnv -and $settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL) { $settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL } else { 'default' }
$displayHaiku = if ($hasEnv -and $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL) { $settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL } else { 'default' }

Write-Host "Switched to $targetProvider provider!" -ForegroundColor Green
Write-Host "Current configuration:" -ForegroundColor Gray
Write-Host "  Base URL: $displayBaseUrl" -ForegroundColor Gray
Write-Host "  Sonnet: $displaySonnet" -ForegroundColor Gray
Write-Host "  Opus: $displayOpus" -ForegroundColor Gray
Write-Host "  Haiku: $displayHaiku" -ForegroundColor Gray
