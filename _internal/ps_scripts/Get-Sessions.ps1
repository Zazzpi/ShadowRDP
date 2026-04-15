param(
    [switch]$AsJson
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$serversFile = Join-Path $PSScriptRoot 'servers.txt'

if (-not (Test-Path $serversFile)) {
    if ($AsJson) {
        @() | ConvertTo-Json
    }
    else {
        Write-Host "servers.txt not found: $serversFile" -ForegroundColor Red
    }
    exit 1
}

$servers = Get-Content $serversFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' }

if ($servers.Count -eq 0) {
    if ($AsJson) {
        @() | ConvertTo-Json
    }
    else {
        Write-Host "servers.txt is empty." -ForegroundColor Red
    }
    exit 1
}

function Get-RDPSessionsFromServer {
    param(
        [string]$Server,
        [bool]$Silent = $false
    )

    $result = @()

    try {
        $rawLines = query session /server:$Server 2>&1

        if (-not $rawLines) {
            if (-not $Silent) {
                Write-Warning "Server $Server returned no data."
            }
            return @()
        }

        foreach ($line in $rawLines) {
            if ($null -eq $line) {
                continue
            }

            $lineText = [string]$line

            if ([string]::IsNullOrWhiteSpace($lineText)) {
                continue
            }

            $trimmedLine = $lineText.Trim()

            if ($trimmedLine -like 'SESSION*' -or $trimmedLine -like 'СЕАНС*') {
                continue
            }

            $parts = $trimmedLine -split '\s{2,}'

            if ($parts.Count -ne 4) {
                continue
            }

            $sessionName = $parts[0]
            $username    = $parts[1]
            $id          = $parts[2]
            $state       = $parts[3]

            switch ($state) {
                'Active'       { $state = 'Active' }
                'Connected'    { $state = 'Connected' }
                'Disconnected' { $state = 'Disconnected' }
                'Listen'       { $state = 'Listen' }
                default        { }
            }

            if ($sessionName -notmatch '^rdp-tcp#\d+$') {
                continue
            }

            if ([string]::IsNullOrWhiteSpace($username)) {
                continue
            }

            if ($id -notmatch '^\d+$') {
                continue
            }

            $result += [PSCustomObject]@{
                Server      = $Server
                SessionName = $sessionName
                Username    = $username
                SessionID   = [int]$id
                State       = $state
            }
        }
    }
    catch {
        if (-not $Silent) {
            Write-Warning "Error while polling server $Server : $_"
        }
    }

    return $result
}

$allSessions = @()

foreach ($server in $servers) {
    if (-not $AsJson) {
        Write-Host "Checking server: $server" -ForegroundColor Cyan
    }

    $allSessions += Get-RDPSessionsFromServer -Server $server -Silent $AsJson
}

$allSessions = @($allSessions | Sort-Object Server, Username)

if ($AsJson) {
    if ($allSessions.Count -eq 0) {
        Write-Output "[]"
    }
    else {
        $allSessions | ConvertTo-Json -Depth 3
    }
}
else {
    if ($allSessions.Count -eq 0) {
        Write-Host "No RDP sessions found." -ForegroundColor Yellow
    }
    else {
        $allSessions | Format-Table Server, SessionName, Username, SessionID, State -AutoSize
    }
}