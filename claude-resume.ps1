# claude-resume.ps1
# Auto-repair and resume a Claude Code session.
# Usage: .\claude-resume.ps1 <session-uuid>

param(
    [Parameter(Mandatory=$false)]
    [string]$SessionId,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guardScript = Join-Path $scriptDir "lib\session-guard.mjs"

if (-not (Test-Path $guardScript)) {
    Write-Error "session-guard.mjs not found at: $guardScript"
    exit 1
}

# Repair foreign sessions first
if ($SessionId -and $SessionId -match '^[0-9a-f]{8}-[0-9a-f]{4}-') {
    node $guardScript $SessionId
} else {
    node $guardScript --all
}

# Launch claude — pass through all original args exactly as given
& claude @PSBoundParameters.Values @ExtraArgs
exit $LASTEXITCODE
