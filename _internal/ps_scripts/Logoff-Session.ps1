param(
    [Parameter(Mandatory=$true)]
    [string]$Server,

    [Parameter(Mandatory=$true)]
    [int]$SessionID
)

try {
    logoff $SessionID /server:$Server
    Write-Host "Session $SessionID on $Server logged off." -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}