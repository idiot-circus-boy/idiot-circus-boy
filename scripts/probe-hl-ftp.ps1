param(
    [string]$FtpServer = "ftp://server166.web-hosting.com",
    [string]$KeyringPath = ""
)

function Get-KeyringCredential {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path $Path)) {
        return $null
    }

    $items = @{}
    $loose = @()

    foreach ($line in Get-Content $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -match "^\s*([^:=]+)\s*[:=]\s*(.+)\s*$") {
            $items[$matches[1].Trim().ToLowerInvariant()] = $matches[2].Trim()
        } else {
            $loose += $trimmed
        }
    }

    $server = $items["server"]
    if (-not $server) { $server = $items["host"] }
    if (-not $server) { $server = $items["ftpserver"] }
    if (-not $server) { $server = $items["ftp_server"] }

    $user = $items["user"]
    if (-not $user) { $user = $items["username"] }
    if (-not $user) { $user = $items["ftpuser"] }
    if (-not $user) { $user = $items["ftp_user"] }

    $pass = $items["pass"]
    if (-not $pass) { $pass = $items["password"] }
    if (-not $pass) { $pass = $items["ftp_pass"] }
    if (-not $pass) { $pass = $items["ftppass"] }

    foreach ($value in $loose) {
        if (-not $server -and ($value -match "^ftp://" -or $value -match "web-hosting\.com" -or $value -match "^server\d+")) {
            $server = $value
            continue
        }

        if (-not $user -and ($value -match "@" -or $value -match "^[A-Za-z0-9_.-]+$")) {
            $user = $value
            continue
        }

        if (-not $pass) {
            $pass = $value
        }
    }

    if ($server -and $server -notmatch "^ftp://") {
        $server = "ftp://$server"
    }

    if ($user -and $pass) {
        return [pscustomobject]@{
            Server = $server
            User = $user
            Password = $pass
        }
    }

    return $null
}

$defaultKeyring = Join-Path (Split-Path $PSScriptRoot) "keyring\hlpressurewashing.txt"
if (-not $KeyringPath -and (Test-Path $defaultKeyring)) {
    $KeyringPath = $defaultKeyring
}

$keyringCredential = Get-KeyringCredential -Path $KeyringPath
if (-not $keyringCredential) {
    Write-Host "Could not read FTP credentials from keyring." -ForegroundColor Red
    exit 1
}

if ($keyringCredential.Server) {
    $FtpServer = $keyringCredential.Server
}

$credential = New-Object System.Net.NetworkCredential($keyringCredential.User, $keyringCredential.Password)
$paths = @("/", "/public_html", "/HL-PRESSURE-WASHING.com", "/hl-pressure-washing.com", "/www", ".")

Write-Host "Using FTP credentials from keyring for $($keyringCredential.User)" -ForegroundColor Cyan
Write-Host "FTP server: $FtpServer" -ForegroundColor Cyan

foreach ($path in $paths) {
    $url = "$($FtpServer.TrimEnd("/"))/$($path.TrimStart("/"))"
    Write-Host "`n=== $path ===" -ForegroundColor Cyan

    try {
        $request = [System.Net.FtpWebRequest]::Create($url)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $request.Credentials = $credential
        $request.UsePassive = $true
        $request.EnableSsl = $false
        $request.Timeout = 10000
        $request.ReadWriteTimeout = 10000
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        $text = $reader.ReadToEnd()
        $reader.Close()
        $response.Close()

        if ($text.Trim()) {
            Write-Host $text
        } else {
            Write-Host "<empty>"
        }
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }
}
