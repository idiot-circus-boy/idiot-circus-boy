Skill: browser-agent

Purpose:
- Provide focused automation and guidance for browser-related tasks in this repo: previewing static HTML, checking links/assets, and safe deploy guidance.

When to use:
- The user asks to "open" or "preview" pages, validate links/assets, or prepare a deploy of site files.

Behavior:
- Inventory relevant files under `projects/website` and `projects/HL-PRESSURE-WASHING`.
- Provide exact commands the user can run locally for previewing (`python -m http.server`) and deploying (`.
scripts\deploy.ps1`).
- Never surface secrets from `keyring/` files; instead provide steps asking the user to run scripts locally.

Examples:
- "Preview the raising canes report": give the `http.server` command and the local URL to open.
- "Check relative links": run a quick parse of HTML link targets and report any suspicious relative paths (but do not modify files without confirmation).

Notes:
- Keep guidance minimal and actionable; link to relevant files rather than copying their full contents.
