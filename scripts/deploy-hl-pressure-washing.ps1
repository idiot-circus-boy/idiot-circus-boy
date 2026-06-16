# FTP Deployment Script for HL-PRESSURE-WASHING.com
# Uploads the static site to the domain's hosting directory.

param(
    [string]$FtpServer = "ftp://ftp.hl-pressure-washing.com",
    [string]$FtpUser = "hlprqctq",
    [string]$RemotePath = "",
    [string]$KeyringPath = "",
    [switch]$Ftps,
    [switch]$InsecureFtps,
    [switch]$NoCurlFallback,
    [switch]$LivePublicHtml,
    [switch]$DryRun
)

$explicitFtpUser = $PSBoundParameters.ContainsKey("FtpUser")
$explicitRemotePath = $PSBoundParameters.ContainsKey("RemotePath")

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

    $remotePath = $items["path"]
    if (-not $remotePath) { $remotePath = $items["remote_path"] }
    if (-not $remotePath) { $remotePath = $items["remotepath"] }
    if (-not $remotePath) { $remotePath = $items["directory"] }
    if (-not $remotePath) { $remotePath = $items["dir"] }

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
            continue
        }

        if (-not $remotePath -and $value -match "/") {
            $remotePath = $value
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
            RemotePath = $remotePath
        }
    }

    return $null
}

$defaultKeyring = Join-Path (Split-Path $PSScriptRoot) "keyring\hlpressurewashing.txt"
if (-not $KeyringPath -and (Test-Path $defaultKeyring)) {
    $KeyringPath = $defaultKeyring
}

$keyringCredential = Get-KeyringCredential -Path $KeyringPath
$ftpPassword = $null
$usedEnvPassword = $false
if ($keyringCredential) {
    if ($keyringCredential.Server) {
        $FtpServer = $keyringCredential.Server
    }
    if (-not $LivePublicHtml -and -not $explicitRemotePath -and -not $RemotePath -and $keyringCredential.RemotePath) {
        $RemotePath = "/" + $keyringCredential.RemotePath.TrimStart("/")
    }
    if (-not $LivePublicHtml -and -not $explicitFtpUser) {
        $FtpUser = $keyringCredential.User
    }
    if ($FtpUser -eq $keyringCredential.User) {
        $ftpPassword = $keyringCredential.Password
    }
}

if ($env:HL_FTP_USER) {
    $FtpUser = $env:HL_FTP_USER
}

if ($env:HL_FTP_PASS) {
    $ftpPassword = $env:HL_FTP_PASS
    $usedEnvPassword = $true
} elseif ($env:FTP_PASS -and -not $ftpPassword) {
    $ftpPassword = $env:FTP_PASS
    $usedEnvPassword = $true
}

if ($ftpPassword) {
    $credential = New-Object System.Net.NetworkCredential($FtpUser, $ftpPassword)
}

if ($LivePublicHtml) {
    $RemotePath = "/public_html"
}

if ($credential -and $keyringCredential -and -not $usedEnvPassword) {
    Write-Host "Using FTP credentials from keyring for $FtpUser" -ForegroundColor Cyan
} elseif ($credential -and $usedEnvPassword) {
    Write-Host "Using FTP credentials from environment for $FtpUser" -ForegroundColor Cyan
} elseif ($credential) {
    Write-Host "Using FTP credentials for $FtpUser" -ForegroundColor Cyan
} elseif ($DryRun) {
    Write-Host "No FTP password needed for dry run." -ForegroundColor Cyan
} else {
    $securePass = Read-Host -Prompt "Enter FTP password" -AsSecureString
    $credential = New-Object System.Net.NetworkCredential($FtpUser, $securePass)
}

$siteDir = Join-Path (Split-Path $PSScriptRoot) "projects\HL-PRESSURE-WASHING"
$localFiles = @(
    "$siteDir\index.html"
)

function Ensure-FtpDirectory {
    param(
        [string]$Url,
        [System.Net.NetworkCredential]$Credential
    )

    try {
        $request = [System.Net.FtpWebRequest]::Create($Url)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $request.Credentials = $Credential
        $request.UsePassive = $true
        $request.EnableSsl = $false
        $response = $request.GetResponse()
        $response.Close()
        Write-Host "Created remote directory." -ForegroundColor Green
    }
    catch {
        Write-Host "Remote directory already exists or cannot be created." -ForegroundColor DarkYellow
    }
}

function Upload-WithCurl {
    param(
        [string]$LocalFile,
        [string]$UploadUrl,
        [System.Net.NetworkCredential]$Credential,
        [bool]$UseFtps,
        [bool]$AllowInsecureFtps
    )

    if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw "curl.exe is not available."
    }

    $netrc = New-TemporaryFile
    $uri = [Uri]$UploadUrl
    $netrcContent = @(
        "machine $($uri.Host)"
        "login $($Credential.UserName)"
        "password $($Credential.Password)"
    )

    try {
        Set-Content -LiteralPath $netrc.FullName -Value $netrcContent -Encoding ASCII
        $curlArgs = @("--fail", "--silent", "--show-error", "--connect-timeout", "20", "--max-time", "60", "--ftp-create-dirs")
        if ($UseFtps) {
            $curlArgs += "--ssl-reqd"
        }
        if ($AllowInsecureFtps) {
            $curlArgs += "--insecure"
        }

        & curl.exe @curlArgs --netrc-file $netrc.FullName -T $LocalFile $UploadUrl
        if ($LASTEXITCODE -eq 28) {
            Write-Host "  -> Passive FTP timed out; retrying active FTP..." -ForegroundColor DarkYellow
            & curl.exe @curlArgs --ftp-port - --netrc-file $netrc.FullName -T $LocalFile $UploadUrl
        }
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe exited with code $LASTEXITCODE."
        }
    }
    finally {
        Remove-Item -LiteralPath $netrc.FullName -Force -ErrorAction SilentlyContinue
    }
}

if (-not $RemotePath) {
    $RemotePath = "/home/hlprqctq/public_html"
}

$RemotePath = $RemotePath.TrimEnd("/")
$remoteUrl = "$FtpServer$RemotePath"

Write-Host "FTP server: $FtpServer" -ForegroundColor Cyan
Write-Host "Remote path: $RemotePath" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "Dry run only. No files were uploaded." -ForegroundColor Yellow
    foreach ($localFile in $localFiles) {
        $fileName = Split-Path $localFile -Leaf
        Write-Host "Would upload $localFile to $remoteUrl/$fileName" -ForegroundColor Yellow
    }
    exit 0
}

Ensure-FtpDirectory -Url $remoteUrl -Credential $credential

foreach ($localFile in $localFiles) {
    $fileName = Split-Path $localFile -Leaf
    $uploadUrl = "$remoteUrl/$fileName"

    if (-not (Test-Path $localFile)) {
        Write-Host "ERROR: File not found: $localFile" -ForegroundColor Red
        continue
    }

    Write-Host "Uploading $fileName..." -ForegroundColor Cyan

    try {
        $ftpRequest = [System.Net.FtpWebRequest]::Create($uploadUrl)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $ftpRequest.Credentials = $credential
        $ftpRequest.UseBinary = $true
        $ftpRequest.UsePassive = $true
        $ftpRequest.EnableSsl = [bool]$Ftps

        $fileContent = [System.IO.File]::ReadAllBytes($localFile)
        $ftpRequest.ContentLength = $fileContent.Length

        $requestStream = $ftpRequest.GetRequestStream()
        $requestStream.Write($fileContent, 0, $fileContent.Length)
        $requestStream.Close()

        $response = $ftpRequest.GetResponse()
        Write-Host "  -> $fileName uploaded successfully ($($response.StatusDescription))" -ForegroundColor Green
        $response.Close()
    }
    catch {
        Write-Host "  -> PowerShell FTP upload failed: $_" -ForegroundColor DarkYellow

        if ($NoCurlFallback) {
            Write-Host "  -> FAILED to upload $fileName" -ForegroundColor Red
            exit 1
        }

        Write-Host "  -> Retrying $fileName with curl.exe..." -ForegroundColor Cyan
        try {
            Upload-WithCurl -LocalFile $localFile -UploadUrl $uploadUrl -Credential $credential -UseFtps ([bool]$Ftps) -AllowInsecureFtps ([bool]$InsecureFtps)
            Write-Host "  -> $fileName uploaded successfully with curl.exe" -ForegroundColor Green
        }
        catch {
            Write-Host "  -> FAILED to upload $fileName with curl.exe : $_" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "`nDone! Visit https://HL-PRESSURE-WASHING.com to see your site." -ForegroundColor Yellow
