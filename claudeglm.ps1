# claudeglm.ps1
# Launch Claude Code with GLM (Z.AI) provider using ENVIRONMENT VARIABLES
# This does NOT modify settings.json - completely safe for concurrent sessions!

$backupPath = "$env:USERPROFILE\.claude\api_keys_backup.json"

# Load API keys backup to get GLM key
$apiBackup = @{}
if (Test-Path $backupPath) {
    $backupContent = Get-Content $backupPath -Raw | ConvertFrom-Json
    foreach ($prop in $backupContent.PSObject.Properties) {
        $apiBackup[$prop.Name] = $prop.Value
    }
}

# Get GLM API key
$apiKey = $null
if ($apiBackup['GLM']) {
    $apiKey = $apiBackup['GLM']
    Write-Host "Using GLM API key from backup" -ForegroundColor Gray
} else {
    Write-Host "GLM API key not found in backup." -ForegroundColor Yellow
    Write-Host "Get your API key from: https://z.ai/manage-apikey/apikey-list" -ForegroundColor Yellow
    $apiKey = Read-Host "Enter your Z.AI API key"
    if (-not $apiKey) {
        Write-Error "API key required for GLM provider"
        exit 1
    }
    # Save to backup for future use
    $apiBackup['GLM'] = $apiKey
    $apiBackup | ConvertTo-Json | Set-Content $backupPath
}

Write-Host ""
Write-Host "=== Launching Claude Code with GLM Provider ===" -ForegroundColor Cyan
Write-Host "✅ Using ENVIRONMENT VARIABLES (safe for concurrent sessions)" -ForegroundColor Green
Write-Host "✅ Does NOT modify settings.json" -ForegroundColor Green
Write-Host ""

# Set environment variables for THIS PROCESS ONLY
$env:ANTHROPIC_AUTH_TOKEN = $apiKey
$env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-4.7"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-4.7"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air"

Write-Host "Provider: GLM (Z.AI)" -ForegroundColor White
Write-Host "Models: Sonnet/Opus → glm-4.7, Haiku → glm-4.5-air" -ForegroundColor Gray
Write-Host ""
Write-Host "Launching Claude Code..." -ForegroundColor Green
Write-Host ""

# Launch Claude Code - it will inherit the environment variables
& claude @args
exit $LASTEXITCODE
