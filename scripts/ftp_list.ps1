# FTP directory listing script
$ftpServer = "ftp://server166.web-hosting.com"
$ftpUser = "idiotcircusboy@jojos-circus.org"

# Use FTP_PASS env var if set, otherwise prompt
if ($env:FTP_PASS) {
    $credential = New-Object System.Net.NetworkCredential($ftpUser, $env:FTP_PASS)
} else {
    $securePass = Read-Host -Prompt "Enter FTP password" -AsSecureString
    $credential = New-Object System.Net.NetworkCredential($ftpUser, $securePass)
}

# List root directory
Write-Host "`n=== ROOT (/) ===" -ForegroundColor Cyan
try {
    $ftpRequest = [System.Net.FtpWebRequest]::Create("$ftpServer/")
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $ftpRequest.Credentials = $credential
    $ftpRequest.UsePassive = $true
    $response = $ftpRequest.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    Write-Host $reader.ReadToEnd()
    $reader.Close()
    $response.Close()
} catch { Write-Host "Error: $_" -ForegroundColor Red }

# List public_html
Write-Host "`n=== /public_html ===" -ForegroundColor Cyan
try {
    $ftpRequest = [System.Net.FtpWebRequest]::Create("$ftpServer/public_html/")
    $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $ftpRequest.Credentials = $credential
    $ftpRequest.UsePassive = $true
    $response = $ftpRequest.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    Write-Host $reader.ReadToEnd()
    $reader.Close()
    $response.Close()
} catch { Write-Host "Error: $_" -ForegroundColor Red }
