# FTP Deployment Script for jojos-circus.org
# Uploads index.html and Jody_LeBlanc_Resume.pdf to public_html

$ftpServer = "ftp://server166.web-hosting.com"
$ftpUser = "idiotcircusboy@jojos-circus.org"
$remotePath = ""

# Use FTP_PASS env var if set, otherwise prompt
if ($env:FTP_PASS) {
    $credential = New-Object System.Net.NetworkCredential($ftpUser, $env:FTP_PASS)
} else {
    $securePass = Read-Host -Prompt "Enter FTP password" -AsSecureString
    $credential = New-Object System.Net.NetworkCredential($ftpUser, $securePass)
}

$localFiles = @(
    "$PSScriptRoot\index.html"
)

foreach ($localFile in $localFiles) {
    $fileName = Split-Path $localFile -Leaf
    $uploadUrl = "$ftpServer$remotePath/$fileName"

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
        $ftpRequest.EnableSsl = $false

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
        Write-Host "  -> FAILED to upload $fileName : $_" -ForegroundColor Red
    }
}

Write-Host "`nDone! Visit https://jojos-circus.org to see your site." -ForegroundColor Yellow
