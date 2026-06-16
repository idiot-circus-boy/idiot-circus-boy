# AGENTS.md — Agent guidance for this repository

Purpose: Short, actionable guidance for AI agents working in this repo, with a focus on browser-related tasks and local website review.

Quick facts
- Repo contains simple static website files under [projects/website](projects/website/index.html) and [projects/HL-PRESSURE-WASHING](projects/HL-PRESSURE-WASHING/index.html).
- Deployment helpers live in `scripts/` (see [scripts/deploy.ps1](scripts/deploy.ps1) and [scripts/deploy-hl-pressure-washing.ps1](scripts/deploy-hl-pressure-washing.ps1)).
- There is no automated build or test system present — changes are typically static edits and manual verification.

Browser-focused tasks (when the user asks for "browser")
- Open and review HTML pages under [projects/website](projects/website/index.html) and [projects/HL-PRESSURE-WASHING](projects/HL-PRESSURE-WASHING/index.html).
- Check linking between pages, assets, and relative paths.
- For visual verification, instruct the user how to open files in a local browser (e.g., open the HTML file in their OS or use a simple static server).
- For deployments, prefer PowerShell scripts in `scripts/` and always ask for confirmation before running any deploy that requires secrets.

Agent behavior rules
- Link, don't copy: Reference files by path and link to them; do not paste large source files inline unless asked.
- Secrets: `keyring/hlpressurewashing.txt` contains sensitive data — never display or commit secrets. If a deploy requires credentials, ask the user to run the script locally or provide a safe, manual step-by-step guide.
- Minimal edits: Create focused PR suggestions with exact diffs (patches) and small, self-contained changes.
- Ask before running: If an action would run scripts or modify remote resources, prompt the user and show the exact command to run locally.

Key paths
- [projects/website/index.html](projects/website/index.html)
- [projects/website/raising-canes-report.html](projects/website/raising-canes-report.html)
- [projects/website/shake-shack-report.html](projects/website/shake-shack-report.html)
- [projects/HL-PRESSURE-WASHING/index.html](projects/HL-PRESSURE-WASHING/index.html)
- [scripts/deploy.ps1](scripts/deploy.ps1)
- [scripts/deploy-hl-pressure-washing.ps1](scripts/deploy-hl-pressure-washing.ps1)
- [keyring/hlpressurewashing.txt](keyring/hlpressurewashing.txt) (sensitive)

How to run common tasks (examples)
- Preview a page: open the file in your OS file explorer or run a tiny static server from the repo root (PowerShell):

```powershell
# from repository root
python -m http.server 8000
# then open http://localhost:8000/projects/website/index.html in a browser
```

- Deploy (manual): review `scripts/deploy.ps1` and `scripts/deploy-hl-pressure-washing.ps1`, then run them locally in PowerShell after confirming credentials are available.

If you want a specialized agent or automated checks for browser tasks, request `create-skill browser` and I will scaffold a skill that provides commands and checks specific to this repo.

Current HL Pressure Washing deploy
- Local site file: `projects/HL-PRESSURE-WASHING/index.html`
- Live document root: `/home/hlprqctq/public_html`
- FTP keyring account: `hlpressurewashing@hl-pressure-washing.com`
- Do not print or commit `keyring/hlpressurewashing.txt`.

Deploy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -Ftps -InsecureFtps
```

Dry run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy-hl-pressure-washing.ps1 -FtpServer ftp://ftp.hl-pressure-washing.com -Ftps -InsecureFtps -DryRun
```
