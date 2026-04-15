param(
    [Parameter(Mandatory=$true)]
    [string]$Server,

    [Parameter(Mandatory=$true)]
    [int]$SessionID
)

try {
    Write-Host "Connecting to session $SessionID on $Server..." -ForegroundColor Cyan

    Start-Process "mstsc.exe" -ArgumentList "/shadow:$SessionID /v:$Server /control /noConsentPrompt"
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}