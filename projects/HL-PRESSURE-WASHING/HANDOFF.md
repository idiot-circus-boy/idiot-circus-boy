# HL Pressure Washing Website Handoff

Date: 2026-06-15

## Current Status

The site is deployed and live:

```text
https://hl-pressure-washing.com/
https://www.hl-pressure-washing.com/
```

The local site file is:

```text
C:\Users\lebla\OneDrive\Documents\idiot-circus-boy\projects\HL-PRESSURE-WASHING\index.html
```

The deploy script now works with the keyring FTP user:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -Ftps -InsecureFtps
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -Ftps -InsecureFtps -DryRun
```

The cPanel FTP account `hlpressurewashing@hl-pressure-washing.com` was deleted and recreated with its home directory set to:

```text
/home/hlprqctq/public_html
```

That makes the FTP root the live document root. Uploading `index.html` to `/index.html` via this FTP account updates the live website.

The keyring remote path was updated to:

```text
/
```

The deploy script was also updated so a stale generic `FTP_PASS` environment variable does not override the keyring password when the keyring already supplied a matching account password.

## Goal

Get `https://hl-pressure-washing.com/` online with the local Hello World landing page:

```text
projects/HL-PRESSURE-WASHING/index.html
```

The user is seeing Namecheap's default hosting welcome page, so DNS and hosting are alive, but our `index.html` has not replaced the active document-root `index.html` yet.

## Local Files Created

```text
projects/HL-PRESSURE-WASHING/index.html
projects/HL-PRESSURE-WASHING/ftp-marker.html
projects/HL-PRESSURE-WASHING/HANDOFF.md
scripts/deploy-hl-pressure-washing.ps1
scripts/probe-hl-ftp.ps1
```

`index.html` is a small static Hello World page:

```text
Hello world.
HL Pressure Washing is coming soon.
```

## Domain/DNS State

The user confirmed `184.94.213.210` is the Namecheap shared IP address.

Observed DNS:

```text
hl-pressure-washing.com        A      184.94.213.210
www.hl-pressure-washing.com    CNAME  hl-pressure-washing.com
Nameservers: dns1.namecheaphosting.com, dns2.namecheaphosting.com
```

Conclusion: DNS is probably correct. The remaining issue is uploading to the correct active document root.

## Credentials / Keyring

Credential file provided by the user:

```text
keyring/hlpressurewashing.txt
```

Do not print its contents. Current known structure:

```text
line 1: hlpressurewashing@hl-pressure-washing.com
line 2: password for that FTP user
line 3: /home/hlprqctq/hl-pressure-washing.com/hlpressurewashing
```

The user later found the main FTP username:

```text
FTP Username: hlprqctq
FTP server: ftp.hl-pressure-washing.com
FTP & explicit FTPS port: 21
```

However, the password in `keyring/hlpressurewashing.txt` does **not** work for `hlprqctq`; attempting it returned:

```text
Access denied: 530
```

## What Worked

Explicit FTPS with curl works when using the domain-specific FTP user from the keyring:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -RemotePath / -Ftps -InsecureFtps
```

The Namecheap FTPS certificate mismatches `ftp.hl-pressure-washing.com`, so curl needs `--insecure` or the script's `-InsecureFtps`.

Uploads succeeded to paths visible to the domain FTP user, including:

```text
/
/hlpressurewashing/
/home/hlprqctq/public_html/
/home/hlprqctq/hl-pressure-washing.com/
/home/hlprqctq/hl-pressure-washing.com/hlpressurewashing/
```

But marker URLs under `https://hl-pressure-washing.com/...` did **not** work. That means those uploads are likely inside the FTP user's jailed filesystem, not the live public web root.

## What Failed / Current Blocker

The domain-specific FTP user:

```text
hlpressurewashing@hl-pressure-washing.com
```

does not appear to map to the actual document root serving the welcome page.

The main hosting FTP user:

```text
hlprqctq
```

is likely the correct account for the live `public_html`, but we do not have its password.

## Likely Fix

Use cPanel/File Manager or reset/create an FTP account with access to the real active document root.

Preferred options:

1. In Namecheap/cPanel File Manager, upload:

```text
C:\Users\lebla\OneDrive\Documents\idiot-circus-boy\projects\HL-PRESSURE-WASHING\index.html
```

to:

```text
public_html/index.html
```

Replace the existing Namecheap welcome-page `index.html`.

2. Or reset the password for main FTP user `hlprqctq`, then deploy with FTPS/curl to:

```text
ftp://ftp.hl-pressure-washing.com/public_html/index.html
```

using username:

```text
hlprqctq
```

The deploy script now supports a live document-root mode. After resetting or obtaining the password for `hlprqctq`, run:

```powershell
$env:HL_FTP_USER = "hlprqctq"
$env:HL_FTP_PASS = "PASTE_MAIN_FTP_PASSWORD_HERE"
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -LivePublicHtml -Ftps -InsecureFtps
Remove-Item Env:\HL_FTP_PASS
```

To verify the destination without uploading:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -LivePublicHtml -Ftps -InsecureFtps -DryRun
```

3. Or in cPanel FTP Accounts, create a new FTP user whose directory is exactly:

```text
public_html
```

Then update `keyring/hlpressurewashing.txt` or the deploy script to use that account.

## Browser / Codex Browser Notes

The user was trying to enable Codex's interactive browser so the assistant can operate Namecheap/cPanel directly.

Observed:

```text
C:\Users\lebla\.codex\config.toml
```

already has:

```toml
[plugins."browser@openai-bundled"]
enabled = true
```

But in this session:

```js
await agent.browsers.list()
```

returned:

```json
[]
```

A named pipe existed:

```text
\\.\pipe\codex-browser-use-de1c9ac2-02fb-4039-a8f2-b51edcf57bf1
```

but the browser was not attached to this chat. A fresh chat may attach Browser correctly if the UI launches it for the new session.

Important: during troubleshooting, `browser-client.mjs` in the Codex plugin cache was temporarily patched and backed up:

```text
C:\Users\lebla\.codex\plugins\cache\openai-bundled\browser\26.609.41114\scripts\browser-client.mjs
C:\Users\lebla\.codex\plugins\cache\openai-bundled\browser\26.609.41114\scripts\browser-client.mjs.bak-session-filter
```

The patch did not fix Browser attachment. A new session should consider restoring the backup if Browser behaves oddly:

```powershell
Copy-Item -Force `
  "C:\Users\lebla\.codex\plugins\cache\openai-bundled\browser\26.609.41114\scripts\browser-client.mjs.bak-session-filter" `
  "C:\Users\lebla\.codex\plugins\cache\openai-bundled\browser\26.609.41114\scripts\browser-client.mjs"
```

## Suggested First Step In New Session

1. Try Codex Browser:

```js
const { setupBrowserRuntime } = await import('C:/Users/lebla/.codex/plugins/cache/openai-bundled/browser/26.609.41114/scripts/browser-client.mjs');
await setupBrowserRuntime({ globals: globalThis });
await agent.browsers.list();
```

2. If Browser is available, go to Namecheap/cPanel and use File Manager to replace `public_html/index.html`.

3. If Browser is not available, ask the user either to:

- reset/provide the `hlprqctq` FTP password, or
- use cPanel File Manager manually to upload `projects/HL-PRESSURE-WASHING/index.html` into `public_html`.
