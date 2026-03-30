---
name: secure-git-commit
description: "Use when: committing and pushing changes to GitHub with secure SSH authentication. Handles staging, committing with a message, and pushing to the configured remote without exposing credentials."
---

# Secure Git Commit Skill

A reusable workflow for securely committing and pushing changes to GitHub using SSH key authentication.

## How It Works

This skill uses SSH-based authentication (more secure than tokens or embedded credentials). Your SSH key is stored locally and used by git to authenticate with GitHub, with no credentials exposed in scripts or shared configurations.

## Prerequisites for Use

Each developer using this skill needs to set up SSH authentication **once**:

1. **Generate SSH key** (if not already done):
   ```powershell
   mkdir $HOME\.ssh
   ssh-keygen -t ed25519 -C "your-email@github.com" -f $HOME\.ssh\id_ed25519 -N '""'
   ```

2. **Configure SSH for GitHub** (`~/.ssh/config`):
   ```
   Host github.com
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519
       StrictHostKeyChecking no
   ```

3. **Add public key to GitHub**:
   - Go to https://github.com/settings/keys
   - Click "New SSH key"
   - Paste contents of `~/.ssh/id_ed25519.pub`

4. **Configure git identity** (global or per-repo):
   ```powershell
   git config --global user.email "your-email@example.com"
   git config --global user.name "Your Name"
   ```

5. **Configure remote for SSH** (if using HTTPS):
   ```powershell
   git remote set-url origin git@github.com:username/repo.git
   ```

## Usage

Ask me to commit changes with a message:

```
Commit my changes with message "Add user authentication feature"
```

I will then:
1. Stage all changes (`git add .`)
2. Create a commit with your message (`git commit -m "..."`))
3. Push to the configured remote (`git push`)

## Why SSH Over Tokens?

- **No stored secrets**: Your SSH key lives locally; nothing is embedded in code or scripts
- **Reusable**: Works for all your repositories without per-repo configuration
- **Shareable**: Other developers can use this exact workflow with their own SSH keys—no credential sharing needed
- **Standard practice**: Industry best practice for automation and CI/CD

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Permission denied (publickey)` | Verify SSH key is added to GitHub and SSH config is correct |
| `Bad configuration option` | Ensure `~/.ssh/config` is saved as ASCII (not UTF-8 with BOM) |
| `Author identity unknown` | Run `git config --global user.email` and `git config --global user.name` |
| Remote is HTTPS not SSH | Run `git remote set-url origin git@github.com:user/repo.git` |

## Example Commands

When you ask me to commit changes:

```powershell
# Stage all changes
git add .

# Commit with message
git commit -m "Fix authentication bug"

# Push to remote
git push
```

No credentials are passed in these commands—authentication happens through your local SSH key.
