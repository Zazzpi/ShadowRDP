param(
    [Parameter(Mandatory=$true)]
    [string]$Server,

    [Parameter(Mandatory=$true)]
    [int]$SessionID
)

try {
    rwinsta $SessionID /server:$Server
    Write-Host "Session $SessionID on $Server reset." -ForegroundColor Yellow
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}