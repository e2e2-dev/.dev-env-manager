# DevEnv Configuration Manager - Complete Setup Guide

**Get your entire dev environment configured in under 5 minutes.**

This guide provides comprehensive documentation for developers using the DevEnv Configuration Manager.

---

## 🚀 Quick Setup

Choose your scenario and follow the steps:

### For New Projects

```bash
# 1. Run the installer (one command)
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash

# 2. Edit configuration (2 required variables)
vim .devenv/config.yaml
# Update: PROJECT_NAME and WORKSPACE_PATH

# 3. (Optional) Add API keys if needed
vim .env.local
# Uncomment and fill in any API keys you need:
#   GEMINI_API_KEY, ANTHROPIC_API_KEY, GITHUB_TOKEN

# 4. Pull configurations
./.devenv/devenv pull all

# 5. Commit
git add .devenv/ .gitignore
git commit -m "feat: add devenv configuration"

# ✅ Done! Dev environment configured.
```

**Time**: ~3 minutes (or ~4 minutes if adding API keys)

---

### For Existing Projects

```bash
# 1. Run the installer (detects existing setup)
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash

# 2. Review/update configuration if needed
vim .devenv/config.yaml

# 3. Update configurations
./.devenv/devenv pull all

# 4. Commit changes
git add .devenv/ .gitignore
git commit -m "chore: update to centralized devenv manager"

# ✅ Done! Now using centralized manager.
```

**Time**: ~2 minutes (if config already exists)

---

## 📋 Daily Commands

```bash
# Check what's synced and if updates available
./.devenv/devenv status

# Pull latest configurations
./.devenv/devenv pull all              # All configs
./.devenv/devenv pull claude           # Specific config

# Push improvements to central repos
./.devenv/devenv push claude           # Creates PR automatically
```

---

## 🎯 What You Get

After setup, your project has:

```
my-project/
├── .devenv/
│   ├── config.yaml          # ← Project config (PROJECT_NAME, WORKSPACE_PATH)
│   ├── config.yaml.example  # ← Optional: Template for team (can be tracked)
│   ├── devenv              # ← CLI tool (symlink to scripts/devenv)
│   └── scripts/            # ← Synced via git subtree from .dev-env-manager
│
├── .env.local              # ← Optional API keys (gitignored, all commented by default)
│
├── .devcontainer/          # ← Cloned from .dev-env-container, vars substituted
├── .claude/                # ← Cloned from .dev-env-claude, vars substituted
└── .continue/              # ← Cloned from .dev-env-continue, vars substituted
```

**Key Benefits:**
- ✅ Consistent dev environment across all projects
- ✅ Scripts managed via git subtree (version tracked, easy updates)
- ✅ Configurations synced via direct clone (no git history mixing)
- ✅ Optional secrets management with commented templates
- ✅ One-command updates when configs improve
- ✅ Contribute improvements back easily

---

## 🔧 Common Tasks

### Update Scripts

```bash
# Use built-in command (recommended)
./.devenv/devenv self-update

# Or manually via git subtree
git subtree pull --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash
```

### Add Custom Variables

Edit `.devenv/config.yaml`:

```yaml
variables:
  PROJECT_NAME: my-project
  WORKSPACE_PATH: /workspaces/my-project

  # Add your custom variables
  DATABASE_PORT: "5432"
  API_VERSION: "v2"
```

Then use in templates: `{{DATABASE_PORT}}`

### Contribute Improvements

```bash
# 1. Edit config locally
vim .claude/CLAUDE.md

# 2. Test changes
# (rebuild container, test Claude, etc.)

# 3. Push to central repo
./.devenv/devenv push claude

# 4. Follow PR link shown
```

---

## 🆘 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| `yq: command not found` | Installer auto-installs it. If failed: `wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x ~/.local/bin/yq` |
| Wrong workspace path | Edit `.devenv/config.yaml`, then `./.devenv/devenv pull all` |
| Permission denied | Check SSH: `ssh -T git@github.com` |
| Scripts out of date | `./.devenv/devenv self-update` or `git subtree pull --prefix .devenv/scripts git@github.com:e2e2-dev/.dev-env-manager.git main --squash` |
| Configs not syncing | Run `./.devenv/devenv pull all` - configs are cloned fresh each time |

---

## 📖 Need More Details?

See sections below for in-depth explanations:
- [How It Works](#how-it-works) - Architecture and design
- [Installation Details](#installation-details) - What the installer does
- [Configuration Reference](#configuration-reference) - All config options
- [Git Subtree Internals](#git-subtree-internals) - How syncing works
- [Variable Substitution](#variable-substitution) - Template system
- [Contributing Back](#contributing-back) - Workflow for improvements
- [Advanced Usage](#advanced-usage) - Power user features

---

# 📚 Complete Guide: Internals & Details

## How It Works

### Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: Manager (.dev-env-manager)                         │
│                                                             │
│  GitHub: e2e2-dev/.dev-env-manager                         │
│  - install.sh (bootstrap installer via curl)               │
│  - scripts/ (devenv CLI, sync-pull, sync-push, etc.)       │
│  - templates/ (config.yaml, .env.local)                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                 (git subtree to .devenv/scripts/)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: Project Layer (.devenv/)                           │
│                                                             │
│  In your project: /path/to/my-project/.devenv/             │
│  - config.yaml (PROJECT_NAME, WORKSPACE_PATH, secrets)      │
│  - config.yaml.example (optional team template)             │
│  - scripts/ (synced via git subtree from manager)           │
│  - devenv (symlink to scripts/devenv)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
              (clone, copy & substitute via devenv pull)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: Configurations (Central Repos)                     │
│                                                             │
│  e2e2-dev/.dev-env-container → .devcontainer/              │
│  e2e2-dev/.dev-env-claude → .claude/                       │
│  e2e2-dev/.dev-env-continue → .continue/                   │
│                                                             │
│  (Cloned via shallow git clone, then variables substituted)│
└─────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

**Separation of Concerns:**
1. **Manager Layer** - Generic installer and scripts (one repo, git subtree)
2. **Project Layer** - Your project-specific variables (your repo, minimal config)
3. **Configuration Layer** - Reusable configs (three central repos, direct clone)

**Benefits:**
- ✅ Scripts version-tracked via git subtree (know which version you have)
- ✅ Configurations pulled fresh each time (no git history mixing)
- ✅ Configurations are project-agnostic (variable substitution)
- ✅ Each project only stores minimal configuration
- ✅ Improvements propagate to all projects
- ✅ Simple to understand and debug

**Why Two Different Sync Methods?**

- **Scripts** (git subtree): Need version tracking, rarely change, no variables
- **Configurations** (direct clone): Change frequently, need variable substitution, don't need history in your project

---

## Installation Details

### What `install.sh` Does

When you run:
```bash
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash
```

**Step-by-step execution:**

#### 1. Verify Git Repository
```bash
# Checks you're in a git repo
git rev-parse --git-dir
```

#### 2. Create Directory Structure
```bash
mkdir -p .devenv
```

#### 3. Setup Scripts via Git Subtree

**For new installation:**
```bash
git subtree add --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash \
  -m "chore: add devenv scripts from central repo"
```

**For existing installation:**
```bash
git subtree pull --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash \
  -m "chore: update devenv scripts from central repo"
```

**What this does:**
- Adds all files from `.dev-env-manager/scripts/` to your `.devenv/scripts/`
- Maintains git history linkage for future pulls
- Uses `--squash` to keep your history clean

#### 4. Create Symlink
```bash
cd .devenv
ln -sf scripts/devenv devenv
chmod +x devenv
```

**Why symlink?**
- `.devenv/devenv` is what developers run
- `scripts/devenv` is synced from central repo
- Symlink connects them (no duplicate files)

#### 5. Download Config Template
```bash
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/templates/config.yaml.template \
  -o .devenv/config.yaml
```

**Only if** `.devenv/config.yaml` doesn't exist.

#### 6. Download .env.local Template
```bash
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/templates/.env.local.template \
  -o .env.local
```

**Only if** `.env.local` doesn't exist.

**What's in .env.local?**
- All API keys commented out by default
- Instructions on where to get each key
- Uncomment only what you need

**Example .env.local:**
```bash
# Google Gemini API Key
# Get your key at: https://makersuite.google.com/app/apikey
# GEMINI_API_KEY=your-gemini-api-key-here

# Anthropic Claude API Key
# Get your key at: https://console.anthropic.com/
# ANTHROPIC_API_KEY=your-anthropic-api-key-here

# GitHub Personal Access Token
# Create one at: https://github.com/settings/tokens
# GITHUB_TOKEN=your-github-token-here
```

#### 7. Configure .gitignore

Adds these patterns:
```gitignore
# DevEnv scripts (synced via git subtree)
.devenv/scripts/

# Configurations (synced from central repos)
.devcontainer/
.claude/
.continue/

# Secrets (NEVER commit!)
.env.local

# Keep local configuration
!.devenv/config.yaml
!.devenv/devenv
```

**Why these patterns?**
- `.devenv/scripts/` managed by git subtree (not project git)
- Configuration directories synced from central repos
- `.env.local` contains secrets (never commit!)
- Only `config.yaml` and `devenv` symlink tracked in project repo

#### 8. Install yq

```bash
# Check if yq exists
command -v yq

# If not, install it
mkdir -p ~/.local/bin
curl -sSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

**What is yq?**
- YAML processor (like `jq` for JSON)
- Required for parsing `config.yaml`
- Used by `devenv` CLI and helper scripts

---

## Configuration Reference

### config.yaml Structure

```yaml
# ============================================================================
# CENTRAL REPOSITORY SOURCES (Usually don't change)
# ============================================================================

sources:
  devcontainer:
    repo: e2e2-dev/.dev-env-container  # GitHub repo (org/name format)
    branch: main                        # Branch to sync from
    target: .devcontainer              # Where to sync in your project

  claude:
    repo: e2e2-dev/.dev-env-claude
    branch: main
    target: .claude

  continue:
    repo: e2e2-dev/.dev-env-continue
    branch: main
    target: .continue

# ============================================================================
# PROJECT-SPECIFIC VARIABLES (Edit these!)
# ============================================================================

variables:
  # Required: Project identity
  PROJECT_NAME: my-awesome-project      # Used in container name, configs
  WORKSPACE_PATH: /workspaces/my-awesome-project  # Dev container mount path

  # Required: Technology versions
  PYTHON_VERSION: "3.11"                # Python version for dev container
  NODE_VERSION: "22"                    # Node.js version

  # Required: AI models
  CLAUDE_MODEL: claude-sonnet-4-5-20250929  # Claude Code model

  # Optional: Custom paths (uncomment if needed)
  # OBSIDIAN_VAULT_PATH: /data/vaults/my-vault
  # KNOWLEDGE_BASES_PATH: /data/knowledge-bases
  # DATA_WORKSPACE_PATH: /data/workspaces

# ============================================================================
# SECRETS (NEVER COMMIT VALUES HERE!)
# ============================================================================
# Secrets are loaded from .env.local which is gitignored
# Uncomment the secrets you need and add values to .env.local
# The installer creates .env.local from .env.local.template

# Optional secrets (uncomment if needed):
secrets:
  - GEMINI_API_KEY
  - ANTHROPIC_API_KEY
  - GITHUB_TOKEN

# ============================================================================
# VARIABLE SUBSTITUTION RULES (Advanced)
# ============================================================================

substitutions:
  # Defines which variables get substituted in which files

  - files:
      - .devcontainer/devcontainer.json
    variables:
      - PROJECT_NAME
      - WORKSPACE_PATH
      - PYTHON_VERSION
      - NODE_VERSION

  - files:
      - .devcontainer/docker-compose.yml
    variables:
      - PROJECT_NAME
      - WORKSPACE_PATH
      - OBSIDIAN_VAULT_PATH
      - KNOWLEDGE_BASES_PATH
      - DATA_WORKSPACE_PATH

  - files:
      - .claude/settings.local.json
    variables:
      - PROJECT_NAME
      - WORKSPACE_PATH
      - CLAUDE_MODEL

  - files:
      - .continue/config.json
    variables:
      - PROJECT_NAME
      - WORKSPACE_PATH

  # Optional: Secrets substitution (uncomment if using secrets above)
  # - files:
  #     - .devcontainer/.env
  #   variables:
  #     - GEMINI_API_KEY
  #     - ANTHROPIC_API_KEY
  #     - GITHUB_TOKEN
```

### Secrets Management

**How it works:**

1. **Declare secrets in config.yaml** (no values!)
   ```yaml
   secrets:
     - GEMINI_API_KEY
     - ANTHROPIC_API_KEY
   ```

2. **Store values in .env.local** (gitignored)
   ```bash
   # .env.local
   GEMINI_API_KEY=your-actual-key-here
   # ANTHROPIC_API_KEY=not-needed-yet
   ```

3. **Scripts auto-load from .env.local**
   - `substitute-variables.sh` loads `.env.local`
   - Secrets get substituted into configs
   - `.env.local` never committed (gitignored)

4. **Secrets substituted into .devcontainer/.env**
   ```yaml
   # In config.yaml substitutions:
   - files:
       - .devcontainer/.env
     variables:
       - GEMINI_API_KEY
       - ANTHROPIC_API_KEY
   ```

**Security:**
- ✅ `.env.local` is gitignored (never committed)
- ✅ `config.yaml` only lists secret names (no values)
- ✅ Template created with all secrets commented out
- ✅ Developers uncomment only what they need
- ✅ Each developer has their own `.env.local`

### Variable Naming Conventions

**Recommended patterns:**
- `PROJECT_NAME`: lowercase-with-hyphens (e.g., `my-awesome-app`)
- `WORKSPACE_PATH`: `/workspaces/{PROJECT_NAME}` (matches PROJECT_NAME)
- Custom variables: UPPERCASE_WITH_UNDERSCORES

**Examples:**
```yaml
# Good
PROJECT_NAME: user-auth-service
WORKSPACE_PATH: /workspaces/user-auth-service
DATABASE_PORT: "5432"

# Avoid
PROJECT_NAME: UserAuthService      # Not lowercase
WORKSPACE_PATH: /workspace/users   # Doesn't match PROJECT_NAME
database_port: "5432"              # Not uppercase
```

---

## Synchronization Internals

The DevEnv Manager uses two different synchronization strategies:

### 1. Scripts Sync (Git Subtree)

**Only `.devenv/scripts/` uses git subtree** for version tracking and bidirectional sync.

#### Initial Add

```bash
git subtree add --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash
```

**What happens:**
1. Git fetches the remote repository
2. Creates a merge commit with all files from `main` branch
3. Places files in `.devenv/scripts/` directory
4. Uses `--squash` to create single commit (not full history)
5. Stores subtree metadata in commit message

**Commit message includes:**
```
git-subtree-dir: .devenv/scripts
git-subtree-split: abc123... (commit hash from source)
```

#### Pulling Script Updates

```bash
# Via devenv command (recommended)
./.devenv/devenv self-update

# Or manually
git subtree pull --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash
```

**What happens:**
1. Fetches latest changes from remote
2. Identifies last sync point from previous subtree metadata
3. Merges changes into your `.devenv/scripts/`
4. Creates merge commit with updated metadata

#### Pushing Script Improvements

```bash
# Via devenv command
./.devenv/devenv push devenv-scripts

# Or manually
git subtree push --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git feature/my-improvement
```

**What happens:**
1. Extracts commits that modified `.devenv/scripts/`
2. Creates temporary branch with just those changes
3. Pushes to specified branch in remote repo
4. You then create PR in central repo

### 2. Configuration Sync (Direct Clone & Copy)

**Configurations (`.devcontainer/`, `.claude/`, `.continue/`) use direct cloning** - NOT git subtree.

#### Why Not Git Subtree for Configs?

**Reasons for direct clone:**
- ✅ **No git history mixing** - Your project history stays clean
- ✅ **Simpler gitignore** - Just ignore the directories
- ✅ **Faster syncing** - Shallow clone is quick
- ✅ **No conflicts** - Fresh copy each time
- ✅ **Variable substitution** - Files are modified after copying

**Downsides (acceptable trade-offs):**
- ⚠️ No git tracking of config changes in your project
- ⚠️ Must use `devenv push` to contribute back (can't use `git subtree push`)

#### How Configuration Pull Works

When you run `./.devenv/devenv pull devcontainer`:

```bash
# 1. Create temp directory
TEMP_DIR=$(mktemp -d)

# 2. Shallow clone (depth=1, fast)
git clone --depth 1 --branch main --single-branch \
  git@github.com:e2e2-dev/.dev-env-container.git "$TEMP_DIR/devcontainer"

# 3. Remove .git to avoid tracking
rm -rf "$TEMP_DIR/devcontainer/.git"

# 4. Remove old target directory
rm -rf .devcontainer

# 5. Move files to target
mv "$TEMP_DIR/devcontainer" .devcontainer

# 6. Load variables and substitute
source .env.local
substitute-variables.sh  # Replaces {{VARIABLES}}

# 7. Cleanup
rm -rf "$TEMP_DIR"
```

#### How Configuration Push Works

When you run `./.devenv/devenv push claude`:

```bash
# 1. Clone remote repo
git clone git@github.com:e2e2-dev/.dev-env-claude.git /tmp/remote

# 2. Restore placeholders in local files
restore-placeholders.sh .claude /tmp/restored
# my-awesome-project → {{PROJECT_NAME}}
# /workspaces/my-awesome-project → {{WORKSPACE_PATH}}

# 3. Compare restored files with remote
diff -r /tmp/restored /tmp/remote

# 4. If changes exist, create feature branch
cd /tmp/remote
git checkout -b feature/update-from-my-project-20251023-120000

# 5. Copy restored files (with placeholders) to remote
rsync -av /tmp/restored/ /tmp/remote/

# 6. Commit and push
git add -A
git commit -m "feat: update from my-project"
git push origin feature/update-from-my-project-20251023-120000

# 7. Show PR creation command
echo "gh pr create --repo e2e2-dev/.dev-env-claude ..."
```

### Why Git Subtree for Scripts?

| Feature | Git Subtree | Direct Clone |
|---------|-------------|--------------|
| **Simplicity** | ⚠️ More complex | ✅ Very simple |
| **Cloning** | ✅ Files included | ❌ Need to pull after clone |
| **Visibility** | ✅ Files visible | ✅ Files visible |
| **History Tracking** | ✅ Tracked in git | ❌ Not tracked |
| **Bidirectional** | ✅ Push/pull easily | ⚠️ Custom push logic |
| **Version Control** | ✅ In your repo | ❌ Gitignored |

**We use subtree for scripts because:**
- Scripts need version tracking (know which version you have)
- Scripts rarely change per-project (no variable substitution)
- Important to track which script version introduced issues
- Developers may improve scripts (bidirectional sync)

**We use direct clone for configurations because:**
- Configurations change frequently (new features, improvements)
- Need variable substitution after copying
- Don't want config history in your project
- Simpler to reason about (just files in directories)
- Faster to pull fresh configs

---

## Variable Substitution

### How Templates Work

Central repositories contain files with `{{VARIABLE}}` placeholders:

**Example: `.devcontainer/devcontainer.json`**
```json
{
  "name": "{{PROJECT_NAME}}",
  "dockerComposeFile": "docker-compose.yml",
  "service": "{{PROJECT_NAME}}",
  "workspaceFolder": "{{WORKSPACE_PATH}}",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "{{PYTHON_VERSION}}"
    }
  }
}
```

### Substitution Process

When you run `.devenv/devenv pull all`:

**Step 1: Clone from central repo**
```bash
# Shallow clone to temp directory
git clone --depth 1 --branch main --single-branch \
  git@github.com:e2e2-dev/.dev-env-container.git /tmp/devcontainer

# Remove .git to avoid tracking conflicts
rm -rf /tmp/devcontainer/.git

# Copy to target
rm -rf .devcontainer
mv /tmp/devcontainer .devcontainer
```

Files now in `.devcontainer/` with placeholders intact.

**Step 2: Load variables and secrets**

From `config.yaml`:
```bash
# Using yq
PROJECT_NAME=$(yq eval '.variables.PROJECT_NAME' .devenv/config.yaml)
WORKSPACE_PATH=$(yq eval '.variables.WORKSPACE_PATH' .devenv/config.yaml)
PYTHON_VERSION=$(yq eval '.variables.PYTHON_VERSION' .devenv/config.yaml)
```

From `.env.local` (if exists):
```bash
# Source .env.local to load secrets
if [ -f .env.local ]; then
  set -a  # Auto-export variables
  source .env.local
  set +a
fi

# Now $GEMINI_API_KEY, $ANTHROPIC_API_KEY, etc. are available
```

**Step 3: Substitute in target files**

For each file listed in `substitutions:`:
```bash
# For .devcontainer/devcontainer.json
sed -i "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" .devcontainer/devcontainer.json
sed -i "s|{{WORKSPACE_PATH}}|${WORKSPACE_PATH}|g" .devcontainer/devcontainer.json
sed -i "s|{{PYTHON_VERSION}}|${PYTHON_VERSION}|g" .devcontainer/devcontainer.json
```

**Result:**
```json
{
  "name": "my-awesome-project",
  "dockerComposeFile": "docker-compose.yml",
  "service": "my-awesome-project",
  "workspaceFolder": "/workspaces/my-awesome-project",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  }
}
```

### The substitute-variables.sh Script

**Core logic (simplified):**

```bash
#!/bin/bash
# substitute-variables.sh - Replace {{VARIABLE}} placeholders

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$DEVENV_DIR/config.yaml"

# Load variables from config.yaml using yq
for key in $(yq eval '.variables | keys | .[]' "$CONFIG_FILE"); do
    VALUE=$(yq eval ".variables.$key" "$CONFIG_FILE")
    export "$key=$VALUE"
done

# Also load secrets from .env.local if it exists
if [ -f "$PROJECT_ROOT/.env.local" ]; then
    set -a  # Auto-export variables
    source "$PROJECT_ROOT/.env.local"
    set +a
fi

# Get number of substitution rules
NUM_RULES=$(yq eval '.substitutions | length' "$CONFIG_FILE")

# Process each substitution rule
for ((i=0; i<$NUM_RULES; i++)); do
    # Get files for this rule
    for file in $(yq eval ".substitutions[$i].files[]" "$CONFIG_FILE"); do
        FILE_PATH="$PROJECT_ROOT/$file"

        if [ ! -f "$FILE_PATH" ]; then
            continue
        fi

        echo "   📝 Processing $file"

        # Get variables for this rule and replace each
        for var in $(yq eval ".substitutions[$i].variables[]" "$CONFIG_FILE"); do
            VALUE="${!var}"
            if [ -n "$VALUE" ]; then
                sed -i "s|{{${var}}}|${VALUE}|g" "$FILE_PATH"
            fi
        done
    done
done

echo "✅ Variable substitution complete"
```

**Key points:**
- Loads variables from `config.yaml` using `yq`
- Loads secrets from `.env.local` (gitignored)
- Processes each substitution rule
- Uses `sed` to replace `{{VARIABLE}}` with actual values
- Only modifies files listed in `config.yaml`

### Adding Custom Variables

**1. Add variable to config.yaml:**
```yaml
variables:
  PROJECT_NAME: my-app
  WORKSPACE_PATH: /workspaces/my-app

  # New custom variable
  API_BASE_URL: https://api.myapp.com
```

**2. Add substitution rule:**
```yaml
substitutions:
  - files:
      - .devcontainer/devcontainer.json
    variables:
      - PROJECT_NAME
      - WORKSPACE_PATH
      - API_BASE_URL  # ← New
```

**3. Use in template:**

In central repo's `.devcontainer/devcontainer.json`:
```json
{
  "containerEnv": {
    "API_BASE_URL": "{{API_BASE_URL}}"
  }
}
```

**4. Pull and substitute:**
```bash
./.devenv/devenv pull all
```

Result:
```json
{
  "containerEnv": {
    "API_BASE_URL": "https://api.myapp.com"
  }
}
```

### Substitution Gotchas

**Issue: Variable not substituted**

Check these:
1. Variable defined in `config.yaml` variables section?
2. Variable listed in appropriate `substitutions` rule?
3. File path correct in `substitutions.files`?
4. Template uses correct syntax: `{{VARIABLE}}` (not `${VARIABLE}`)?

**Issue: Partial substitution**

```json
// Wrong - mixed template styles
"path": "${PROJECT_NAME}/{{WORKSPACE_PATH}}"

// Right - consistent template style
"path": "{{PROJECT_NAME}}/{{WORKSPACE_PATH}}"
```

**Issue: Substitution in wrong files**

Only files listed in `substitutions.files` get processed:
```yaml
substitutions:
  - files:
      - .devcontainer/devcontainer.json  # ✅ Processed
      - .devcontainer/docker-compose.yml # ✅ Processed
    variables:
      - PROJECT_NAME

# .devcontainer/Dockerfile NOT processed (not in list)
```

---

## Contributing Back

### Complete Workflow

#### 1. Make Local Changes

Edit configuration files in your project:

```bash
# Example: Improve Claude configuration
vim .claude/CLAUDE.md

# Add new coding standards
vim .claude/knowledge/standards/coding-standards.md
```

#### 2. Test Thoroughly

**For .devcontainer/ changes:**
```bash
# Rebuild container
Dev Containers: Rebuild Container

# Test all features work
# - Extensions load
# - Python version correct
# - Tools available
```

**For .claude/ changes:**
```bash
# Test Claude commands
/help
/initiate test-scope

# Verify new features
# Check CLAUDE.md applies correctly
```

**For .continue/ changes:**
```bash
# Test Continue.dev
# - Autocomplete works
# - Chat works
# - Configuration loads
```

#### 3. Review Changes

```bash
# See what you changed
git diff .claude/

# See which files changed
git status .claude/
```

#### 4. Push to Central Repo

```bash
# Push changes (interactive)
./.devenv/devenv push claude

# What happens:
# 1. Restores {{PLACEHOLDERS}} in your files (my-project → {{PROJECT_NAME}})
# 2. Clones central repo for comparison
# 3. Shows you the changes
# 4. Asks for confirmation
# 5. Creates feature branch
# 6. Commits and pushes
# 7. Shows gh pr create command
```

**Example output:**
```
📤 Pushing changes to central repositories...

ℹ Processing claude...
ℹ Cloning remote repository...
ℹ Restoring placeholders in local files for comparison...
   Changes detected (comparing files with placeholders restored):
     Files .claude/CLAUDE.md differ
     Files .claude/knowledge/standards/coding-standards.md differ

   This will:
   1. Create branch: feature/update-from-my-project-20251023-120000
   2. Copy local files to remote repo
   3. Commit and push changes
   4. Allow you to create a PR

   Continue? (y/N) y

ℹ Copying changes with placeholders restored...
ℹ Pushing to feature/update-from-my-project-20251023-120000...
✅ Pushed to branch: feature/update-from-my-project-20251023-120000

   Create PR with:
   gh pr create --repo e2e2-dev/.dev-env-claude --head feature/update-from-my-project-20251023-120000 --title "feat: update from my-project" --fill
```

**Important:** The push process:
1. **Restores placeholders** - Your project-specific values are replaced back to `{{VARIABLE}}`
2. **Compares with remote** - Only files with actual changes (after placeholder restoration) are shown
3. **Creates clean PR** - Remote repo gets generic templates, not your project-specific values

#### 5. Create Pull Request

```bash
# Create PR with gh CLI
gh pr create --repo e2e2-dev/.dev-env-claude \
  --head feature/update-from-my-project-20251016-230145 \
  --title "feat: enhance coding standards and CLAUDE.md" \
  --body "## Changes

- Enhanced CLAUDE.md with better examples
- Added comprehensive coding standards
- Fixed typos and improved clarity

## Testing

- ✅ Tested in my-project
- ✅ All Claude commands work correctly
- ✅ New standards are clear and actionable

## Impact

- Improves developer experience
- Provides clearer guidance
- Makes configurations more useful"
```

Or use GitHub web interface:
1. Go to https://github.com/e2e2-dev/.dev-env-claude/pulls
2. Click "New Pull Request"
3. Select your branch: `feature/update-from-my-project-20251016-230145`
4. Fill in title and description
5. Create PR

#### 6. Review and Merge

**PR Review Checklist:**
- [ ] Changes are generic (no project-specific content)
- [ ] Variables use `{{VARIABLE}}` placeholders
- [ ] Documentation updated if needed
- [ ] No secrets or credentials
- [ ] Tested in at least one project
- [ ] Benefits multiple projects

**After merge:**
```bash
# PR approved and merged to main
```

#### 7. Sync to Other Projects

```bash
# In other projects
cd /path/to/other-project
./.devenv/devenv pull claude

# Pulls latest including your improvements
```

### Best Practices

**DO:**
- ✅ Test changes thoroughly before pushing
- ✅ Write clear PR descriptions
- ✅ Explain why changes are beneficial
- ✅ Use descriptive commit messages
- ✅ Keep changes focused (one improvement per PR)
- ✅ Update documentation if behavior changes
- ✅ Use `{{VARIABLE}}` for project-specific values

**DON'T:**
- ❌ Push untested changes
- ❌ Include project-specific content (hardcoded paths, names)
- ❌ Push secrets or credentials
- ❌ Make breaking changes without discussion
- ❌ Push directly to main branch
- ❌ Mix unrelated changes in one PR
- ❌ Forget to pull before editing

---

## Advanced Usage

### Custom Scripts

Add project-specific scripts to `.devenv/`:

```bash
# .devenv/project-setup.sh
#!/bin/bash
# Custom setup for this project only

echo "Running project-specific setup..."
# Your custom logic here
```

**Call from config:**
```yaml
# In config.yaml (custom section)
hooks:
  post_pull: .devenv/project-setup.sh
```

### Multiple Environments

Different configs for different environments:

```yaml
# .devenv/config.yaml
variables:
  PROJECT_NAME: my-app
  WORKSPACE_PATH: /workspaces/my-app

  # Environment-specific
  ENVIRONMENT: development

# .devenv/config.production.yaml
variables:
  PROJECT_NAME: my-app
  WORKSPACE_PATH: /workspaces/my-app

  # Environment-specific
  ENVIRONMENT: production
```

Use different configs:
```bash
# Development (default)
./.devenv/devenv pull all

# Production
CONFIG=.devenv/config.production.yaml ./.devenv/devenv pull all
```

### Conditional Substitutions

Skip substitution for missing variables:

```bash
# In substitute-variables.sh, add:
if [ -n "${var_value}" ]; then
    sed -i "s|{{${var_name}}}|${var_value}|g" "$file"
else
    echo "Warning: Variable $var_name not set, skipping"
fi
```

### Debugging

Enable debug mode:

```bash
# Run devenv with debug output
DEBUG=1 ./.devenv/devenv pull all

# Or manually trace
bash -x ./.devenv/devenv pull all
```

### Version Pinning

Pin to specific commits instead of branches:

```yaml
sources:
  claude:
    repo: e2e2-dev/.dev-env-claude
    branch: main
    commit: abc123def456  # Pin to specific commit
    target: .claude
```

Modify sync-pull.sh to use commit hash:
```bash
if [ -n "$COMMIT" ]; then
    git subtree pull --prefix "$TARGET" "$REPO_URL" "$COMMIT" --squash
else
    git subtree pull --prefix "$TARGET" "$REPO_URL" "$BRANCH" --squash
fi
```

---

## Repository Links

### Central Repositories

- 🚀 **Bootstrap**: https://github.com/e2e2-dev/.dev-env-manager
  - Installation script
  - CLI tools and helper scripts
  - Configuration templates

- 📦 **Container**: https://github.com/e2e2-dev/.dev-env-container
  - Dev Container configuration
  - Dockerfile and docker-compose
  - Container features

- 🤖 **Claude**: https://github.com/e2e2-dev/.dev-env-claude
  - Claude Code configuration
  - Workflow commands
  - Knowledge base structure

- 🔄 **Continue**: https://github.com/e2e2-dev/.dev-env-continue
  - Continue.dev configuration
  - Model settings
  - Prompt templates

---

## Changelog

### 2025-10-16 - v1.0.0

**Added:**
- ✅ Centralized `.dev-env-manager` repository
- ✅ One-command installer via curl
- ✅ Git subtree-based script synchronization
- ✅ Minimal `config.yaml` template (2 required variables)
- ✅ Optional secrets management with `.env.local` template
- ✅ Automatic yq installation
- ✅ Auto-configured .gitignore

**Improved:**
- ✅ Made all `.claude/` configurations project-agnostic
- ✅ Removed 117KB of project-specific content
- ✅ Enhanced variable substitution system with secrets support
- ✅ Fixed sync-push/pull bugs
- ✅ All secrets commented out by default (opt-in pattern)

**Removed:**
- ❌ Manual script downloads (now via git subtree)
- ❌ Complex config.yaml (now minimal template)
- ❌ Project-specific documentation from central repos
- ❌ Hardcoded API keys (now in gitignored .env.local)

---

## Support

**Questions?**
- 💬 Discussions: https://github.com/e2e2-dev/.dev-env-manager/discussions
- 🐛 Issues: https://github.com/e2e2-dev/.dev-env-manager/issues
- 📖 Docs: https://github.com/e2e2-dev/.dev-env-manager/blob/main/README.md

**Quick Help:**
```bash
./.devenv/devenv --help
```
