# Centralized Configuration Setup Guide

**Step-by-step guide for setting up centralized development environment configuration across projects.**

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Daily Usage](#daily-usage)
5. [Making Changes](#making-changes)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Topics](#advanced-topics)

---

## Overview

### What is Centralized Configuration?

This system synchronizes common development environment configurations across all your Python projects:

- **`.devcontainer/`** - VS Code Dev Container configuration
- **`.claude/`** - Claude Code AI assistant configuration
- **`.continue/`** - Continue.dev AI coding assistant configuration

### How It Works

```
Central GitHub Repositories          Your Project
┌─────────────────────────┐         ┌──────────────────┐
│ .dev-env-container      │ ──────> │ .devcontainer/   │
│ .dev-env-claude         │ ──────> │ .claude/         │
│ .dev-env-continue       │ ──────> │ .continue/       │
└─────────────────────────┘         └──────────────────┘
         (via git subtree)
```

**Key Benefits:**
- ✅ **Consistency**: All projects use same configuration
- ✅ **Easy Updates**: Pull changes from central repos
- ✅ **Project-Agnostic**: Generic configs work everywhere
- ✅ **Version Control**: Changes tracked in central repos

---

## Prerequisites

### 1. Install Required Tools

```bash
# Install yq (YAML processor)
mkdir -p ~/.local/bin
wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x ~/.local/bin/yq

# Add to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
yq --version
```

### 2. Verify Git Configuration

```bash
# Check git is configured
git config --global user.name
git config --global user.email

# If not configured, set them:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. GitHub SSH Authentication

```bash
# Test GitHub SSH access
ssh -T git@github.com

# Should see: "Hi username! You've successfully authenticated..."
# If not, set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
```

---

## Initial Setup

### Step 1: Create `.devenv/config.yaml`

**Location**: `<your-project>/.devenv/config.yaml`

```yaml
# Central repository sources
sources:
  devcontainer:
    repo: "e2e2-dev/.dev-env-container"
    branch: "main"
    target: ".devcontainer"

  claude:
    repo: "e2e2-dev/.dev-env-claude"
    branch: "main"
    target: ".claude"

  continue:
    repo: "e2e2-dev/.dev-env-continue"
    branch: "main"
    target: ".continue"

# Project-specific variables (non-secret)
variables:
  PROJECT_NAME: my-project-name              # ← Change this
  WORKSPACE_PATH: /workspaces/my-project     # ← Change this
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "22"
  CLAUDE_MODEL: claude-sonnet-4-5-20250929
```

**⚠️ IMPORTANT**: Update `PROJECT_NAME` and `WORKSPACE_PATH` to match your project!

### Step 2: Download the `devenv` CLI Tool

```bash
# From your project root
cd /path/to/your/project

# Download the devenv script
curl -o .devenv/devenv https://raw.githubusercontent.com/e2e2-dev/.dev-env-container/main/.devenv/devenv
chmod +x .devenv/devenv

# Or if you already have it, ensure it's executable
chmod +x .devenv/devenv
```

### Step 3: Initial Pull (First Time Setup)

```bash
# Pull all configurations from central repos
.devenv/devenv pull all

# This will:
# 1. Clone .dev-env-container → .devcontainer/
# 2. Clone .dev-env-claude → .claude/
# 3. Clone .dev-env-continue → .continue/
# 4. Apply variable substitutions (PROJECT_NAME, WORKSPACE_PATH, etc.)
```

**Expected Output:**
```
📥 Pulling from central repositories...
✅ Pulled devcontainer from e2e2-dev/.dev-env-container
✅ Pulled claude from e2e2-dev/.dev-env-claude
✅ Pulled continue from e2e2-dev/.dev-env-continue
🔄 Applying variable substitutions...
✅ Pull complete!
```

### Step 4: Verify Setup

```bash
# Check synchronized directories exist
ls -la .devcontainer/
ls -la .claude/
ls -la .continue/

# Check status
.devenv/devenv status

# Should show:
# 📦 devcontainer (synced from: e2e2-dev/.dev-env-container)
# 📦 claude (synced from: e2e2-dev/.dev-env-claude)
# 📦 continue (synced from: e2e2-dev/.dev-env-continue)
```

### Step 5: Configure `.gitignore`

**Add to your project's `.gitignore`:**

```gitignore
# Centralized configurations (managed via git subtree)
.devcontainer/
.claude/
.continue/

# Keep .devenv configuration
!.devenv/
```

**Why?** These directories are managed via git subtree and synced from central repos, so we ignore them in the project's main git history.

### Step 6: Commit `.devenv/config.yaml`

```bash
# Commit the configuration (but not the synced directories)
git add .devenv/config.yaml .devenv/devenv .gitignore
git commit -m "feat: add centralized devenv configuration"
git push origin main
```

---

## Daily Usage

### Checking Status

```bash
# See what's synced and from where
.devenv/devenv status
```

**Output Example:**
```
📦 devcontainer (synced from: e2e2-dev/.dev-env-container)
   Target: .devcontainer
   Status: ✅ Up to date
   Last commit: abc1234 (2025-10-16)

📦 claude (synced from: e2e2-dev/.dev-env-claude)
   Target: .claude
   Status: ⚠️  Updates available
   Last commit: def5678 (2025-10-15)

📦 continue (synced from: e2e2-dev/.dev-env-continue)
   Target: .continue
   Status: ✅ Up to date
   Last commit: ghi9012 (2025-10-14)
```

### Pulling Updates

When central repos are updated by other team members:

```bash
# Pull updates for all configurations
.devenv/devenv pull all

# Or pull specific configuration
.devenv/devenv pull claude
.devenv/devenv pull devcontainer
.devenv/devenv pull continue
```

**When to pull:**
- ✅ Start of each day
- ✅ Before starting new features
- ✅ After team updates central configs
- ✅ When you see "Updates available" in status

### Applying Variable Substitutions

After pulling, variables from `config.yaml` are automatically substituted:

```yaml
# In config.yaml
variables:
  PROJECT_NAME: my-awesome-project
  WORKSPACE_PATH: /workspaces/my-awesome-project
```

```json
// In .devcontainer/devcontainer.json (after substitution)
{
  "name": "my-awesome-project",        // ← Replaced from {{PROJECT_NAME}}
  "workspaceFolder": "/workspaces/my-awesome-project"  // ← Replaced from {{WORKSPACE_PATH}}
}
```

---

## Making Changes

### Workflow for Updating Central Configurations

When you need to improve the shared configurations:

#### Step 1: Edit Files Locally

```bash
# Edit configurations in your project
vim .claude/CLAUDE.md
# or
vim .devcontainer/devcontainer.json
```

#### Step 2: Test Changes

```bash
# Test that changes work in your project
# - Rebuild dev container if changed .devcontainer/
# - Test Claude commands if changed .claude/
# - Test Continue.dev if changed .continue/
```

#### Step 3: Push to Central Repository

```bash
# Push changes to central repo on a feature branch
.devenv/devenv push claude

# Interactive prompts will ask:
# 1. Show you the changes
# 2. Ask for confirmation
# 3. Create a feature branch: feature/update-from-<project>-<timestamp>
# 4. Push to central repository
```

**Example Session:**
```
📤 Pushing changes to central repositories...

ℹ Processing claude...
   Changes detected:
     .claude/CLAUDE.md | 10 +++++-----
     .claude/knowledge/development.md | 3 ++-
     2 files changed, 7 insertions(+), 6 deletions(-)

   This will:
   1. Create branch: feature/update-from-my-project-20251016-143022
   2. Push changes to central repo
   3. Allow you to create a PR

   Continue? (y/N) y

ℹ Pushing to feature/update-from-my-project-20251016-143022...
✅ Pushed to branch: feature/update-from-my-project-20251016-143022

   Create PR with:
   gh pr create --repo e2e2-dev/.dev-env-claude \
     --head feature/update-from-my-project-20251016-143022 \
     --title "feat: update from my-project" \
     --fill
```

#### Step 4: Create Pull Request

```bash
# Create PR in central repository
gh pr create --repo e2e2-dev/.dev-env-claude \
  --head feature/update-from-my-project-20251016-143022 \
  --title "feat: improve Claude configuration" \
  --body "## Changes
- Enhanced CLAUDE.md with better examples
- Updated knowledge files to be more generic

## Testing
- Tested in my-project
- All Claude commands work correctly"
```

#### Step 5: Merge and Sync

1. **Review PR** in central repository
2. **Merge** once approved
3. **Pull updates** in other projects:

```bash
# In other projects
cd /path/to/other-project
.devenv/devenv pull claude
```

### Important Rules

**✅ DO:**
- Test changes thoroughly in your project first
- Create descriptive PR titles and descriptions
- Use feature branches (auto-created by `devenv push`)
- Review changes before pushing

**❌ DON'T:**
- Push directly to main branch
- Include project-specific content in shared configs
- Skip testing before pushing
- Push secrets or credentials

---

## Troubleshooting

### Issue: `yq: command not found`

**Solution:**
```bash
# Install yq
mkdir -p ~/.local/bin
wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x ~/.local/bin/yq

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Issue: `fatal: '.devcontainer' does not exist; use 'git subtree add'`

**Cause:** Directory was removed from disk but git still thinks it's a subtree.

**Solution:**
```bash
# The pull script automatically detects this and uses 'git subtree add'
.devenv/devenv pull all

# It checks both git history AND disk existence
```

### Issue: `No changes to push`

**Cause:** Using `git diff` instead of `git diff HEAD` (only checks working tree, not staged changes).

**Solution:** This was fixed in recent sync-push.sh updates. Update your devenv script:
```bash
curl -o .devenv/devenv https://raw.githubusercontent.com/e2e2-dev/.dev-env-container/main/.devenv/devenv
chmod +x .devenv/devenv
```

### Issue: Container mounts wrong workspace path

**Symptom:** Container shows `/workspaces/data-my-project` but config expects `/workspaces/my-project`

**Solution:** Fix `WORKSPACE_PATH` in `.devenv/config.yaml`:
```yaml
variables:
  PROJECT_NAME: my-project              # Must match
  WORKSPACE_PATH: /workspaces/my-project  # Must match
```

Then regenerate:
```bash
.devenv/devenv pull devcontainer
```

### Issue: Git subtree conflicts

**Symptom:** Merge conflicts when pulling updates

**Solution:**
```bash
# 1. Stash local changes
git stash

# 2. Pull fresh copy
.devenv/devenv pull all

# 3. Apply stash
git stash pop

# 4. Resolve conflicts manually if needed
```

### Issue: Permission denied when pushing

**Symptom:** `Permission denied (publickey)` when running `devenv push`

**Solution:**
```bash
# 1. Check SSH key is added to GitHub
ssh -T git@github.com

# 2. If needed, add SSH key
ssh-add ~/.ssh/id_rsa  # or your key path

# 3. Verify access to central repos
git ls-remote git@github.com:e2e2-dev/.dev-env-claude.git
```

---

## Advanced Topics

### Understanding Variable Substitution

**In `config.yaml`:**
```yaml
variables:
  PROJECT_NAME: awesome-app
  WORKSPACE_PATH: /workspaces/awesome-app
  PYTHON_VERSION: "3.11"
```

**In template files (before substitution):**
```json
{
  "name": "{{PROJECT_NAME}}",
  "workspaceFolder": "{{WORKSPACE_PATH}}",
  "features": {
    "python": "{{PYTHON_VERSION}}"
  }
}
```

**After substitution:**
```json
{
  "name": "awesome-app",
  "workspaceFolder": "/workspaces/awesome-app",
  "features": {
    "python": "3.11"
  }
}
```

The substitution script (`.devenv/substitute-variables.sh`) automatically:
1. Reads variables from `config.yaml`
2. Finds all `{{VARIABLE}}` placeholders
3. Replaces them with actual values
4. Creates final configuration files

### Git Subtree Internals

**How it works:**
```bash
# Initial add (first time)
git subtree add --prefix .claude \
  git@github.com:e2e2-dev/.dev-env-claude.git main --squash

# Pull updates (subsequent times)
git subtree pull --prefix .claude \
  git@github.com:e2e2-dev/.dev-env-claude.git main --squash

# Push changes
git subtree push --prefix .claude \
  git@github.com:e2e2-dev/.dev-env-claude.git feature-branch
```

**Why `--squash`?**
- Keeps project history clean
- Doesn't include every commit from central repo
- Only includes the "snapshot" of configuration

### Custom Variables

Add project-specific variables in `config.yaml`:

```yaml
variables:
  PROJECT_NAME: my-app
  WORKSPACE_PATH: /workspaces/my-app
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "22"

  # Custom variables
  DATABASE_PORT: "5432"
  REDIS_PORT: "6379"
  API_VERSION: "v2"
```

Then use in configuration files:
```yaml
# In .devcontainer/devcontainer.json
"forwardPorts": [
  {{DATABASE_PORT}},
  {{REDIS_PORT}}
],
```

### Managing Multiple Projects

**Best Practice Structure:**
```
~/projects/
├── project-a/
│   └── .devenv/
│       ├── config.yaml  # PROJECT_NAME: project-a
│       └── devenv
├── project-b/
│   └── .devenv/
│       ├── config.yaml  # PROJECT_NAME: project-b
│       └── devenv
└── project-c/
    └── .devenv/
        ├── config.yaml  # PROJECT_NAME: project-c
        └── devenv
```

Each project:
- ✅ Has own `config.yaml` with unique PROJECT_NAME
- ✅ Syncs from same central repositories
- ✅ Applies project-specific variable substitutions
- ✅ Can push improvements back to central repos

### Updating the `devenv` Script Itself

The `devenv` script can be updated:

```bash
# Check for updates
curl -s https://raw.githubusercontent.com/e2e2-dev/.dev-env-container/main/.devenv/devenv | diff - .devenv/devenv

# Update if needed
curl -o .devenv/devenv https://raw.githubusercontent.com/e2e2-dev/.dev-env-container/main/.devenv/devenv
chmod +x .devenv/devenv

# Commit update
git add .devenv/devenv
git commit -m "chore: update devenv script"
```

---

## Summary: Quick Reference

### Initial Setup (Once per project)
```bash
# 1. Install yq
wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x ~/.local/bin/yq

# 2. Create config.yaml (customize PROJECT_NAME and WORKSPACE_PATH)
# 3. Download devenv script
# 4. Pull configurations
.devenv/devenv pull all

# 5. Update .gitignore
# 6. Commit .devenv/config.yaml
```

### Daily Commands
```bash
# Check status
.devenv/devenv status

# Pull updates
.devenv/devenv pull all

# Push changes
.devenv/devenv push claude
```

### Making Changes Workflow
```bash
# 1. Edit locally
vim .claude/CLAUDE.md

# 2. Test changes
# 3. Push to central repo
.devenv/devenv push claude

# 4. Create PR
gh pr create --repo e2e2-dev/.dev-env-claude --fill

# 5. After merge, pull in other projects
.devenv/devenv pull claude
```

---

## Recent Improvements (2025-10-16)

### What Changed
1. **✅ Removed project-specific content** from `.claude/` configuration:
   - Deleted `ARCHITECTURE_REFERENCE.md` (Knowledge Builder specific)
   - Removed 5 workflow documentation files (test results, enhancements)
   - Total: ~117KB of project-specific content removed

2. **✅ Made all `.claude/knowledge/` files project-agnostic**:
   - Uses `{{WORKSPACE_PATH}}` placeholder instead of hardcoded paths
   - Generic descriptions without project-specific references
   - Deleted `dev-uat.md` (project-specific UAT scenarios)

3. **✅ Enhanced `.claude/CLAUDE.md`**:
   - Generic Python project configuration
   - Removed Knowledge Builder references
   - Added comprehensive coding standards

4. **✅ Fixed `sync-push.sh` and `sync-pull.sh`**:
   - Now detects both staged and working tree changes
   - Checks disk existence before subtree operations
   - Improved yq parsing

### What This Means for You
- **Same configuration works across all Python projects**
- **No manual customization needed** (just update `config.yaml`)
- **Easier to contribute improvements** back to central repos
- **Pull updates without conflicts** or project-specific content

---

**Questions or Issues?**
- File issues: https://github.com/e2e2-dev/.dev-env-container/issues
- Team documentation: Check central repos' README files
- Quick help: `./devenv/devenv --help`
