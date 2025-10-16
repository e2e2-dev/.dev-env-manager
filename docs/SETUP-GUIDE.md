# Centralized Development Environment Configuration

**Get your entire dev environment configured in under 5 minutes.**

---

## 🚀 Quick Setup

Choose your scenario and follow the steps:

### For New Projects

```bash
# 1. Run the installer (one command)
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash

# 2. Edit configuration (2 variables)
vim .devenv/config.yaml
# Update: PROJECT_NAME and WORKSPACE_PATH

# 3. Pull configurations
./.devenv/devenv pull all

# 4. Commit
git add .devenv/ .gitignore
git commit -m "feat: add devenv configuration"

# ✅ Done! Dev environment configured.
```

**Time**: ~3 minutes

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
│   ├── config.yaml          # ← Your 2 variables (PROJECT_NAME, WORKSPACE_PATH)
│   ├── devenv              # ← CLI tool (symlink)
│   └── scripts/            # ← Auto-synced via git subtree
│
├── .devcontainer/          # ← VS Code Dev Container config (auto-synced)
├── .claude/                # ← Claude Code AI config (auto-synced)
└── .continue/              # ← Continue.dev AI config (auto-synced)
```

**Key Benefits:**
- ✅ Consistent dev environment across all projects
- ✅ One-command updates when configs improve
- ✅ Contribute improvements back easily
- ✅ No manual script maintenance

---

## 🔧 Common Tasks

### Update Scripts

```bash
# Pull latest devenv scripts
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
| Scripts out of date | `git subtree pull --prefix .devenv/scripts git@github.com:e2e2-dev/.dev-env-manager.git main --squash` |

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
│ Tier 1: Bootstrap (.dev-env-manager)                       │
│                                                             │
│  GitHub: e2e2-dev/.dev-env-manager                         │
│  - install.sh (one-command installer)                      │
│  - scripts/ (devenv CLI, sync-pull, sync-push, etc.)       │
│  - templates/config.yaml.template                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    (git subtree pull)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: Project Configuration (.devenv/)                   │
│                                                             │
│  In your project: /path/to/my-project/.devenv/             │
│  - config.yaml (PROJECT_NAME, WORKSPACE_PATH)              │
│  - scripts/ (synced from .dev-env-manager)                 │
│  - devenv (symlink to scripts/devenv)                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    (devenv pull all)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: Configurations (Central Repos)                     │
│                                                             │
│  e2e2-dev/.dev-env-container → .devcontainer/              │
│  e2e2-dev/.dev-env-claude → .claude/                       │
│  e2e2-dev/.dev-env-continue → .continue/                   │
│                                                             │
│  (Synced via git subtree with variable substitution)       │
└─────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

**Separation of Concerns:**
1. **Bootstrap Layer** - Generic installer and scripts (one repo)
2. **Project Layer** - Your project-specific variables (your repo)
3. **Configuration Layer** - Reusable configs (three central repos)

**Benefits:**
- Scripts stay updated automatically (git subtree)
- Configurations are project-agnostic (variable substitution)
- Each project only stores 2 variables
- Improvements propagate to all projects

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

#### 6. Configure .gitignore

Adds these patterns:
```gitignore
# DevEnv scripts (synced via git subtree)
.devenv/scripts/

# Configurations (synced from central repos)
.devcontainer/
.claude/
.continue/

# Keep local configuration
!.devenv/config.yaml
!.devenv/devenv
```

**Why these patterns?**
- `.devenv/scripts/` managed by git subtree (not project git)
- Configuration directories synced from central repos
- Only `config.yaml` tracked in project repo

#### 7. Install yq

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
```

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

## Git Subtree Internals

### How Git Subtree Works

Git subtree allows you to include one repository within another while maintaining independent histories.

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

#### Pulling Updates

```bash
git subtree pull --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash
```

**What happens:**
1. Fetches latest changes from remote
2. Identifies last sync point from previous subtree metadata
3. Merges changes into your `.devenv/scripts/`
4. Creates merge commit with updated metadata

#### Pushing Changes

```bash
git subtree push --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git feature/my-improvement
```

**What happens:**
1. Extracts commits that modified `.devenv/scripts/`
2. Creates temporary branch with just those changes
3. Pushes to specified branch in remote repo
4. You then create PR in central repo

### Why Subtree vs Submodule?

| Feature | Git Subtree | Git Submodule |
|---------|-------------|---------------|
| **Simplicity** | ✅ Simple (just git commands) | ❌ Complex (extra .gitmodules) |
| **Cloning** | ✅ Files included in clone | ❌ Requires `git submodule init` |
| **Visibility** | ✅ Files visible in project | ❌ Pointer only |
| **Merging** | ✅ Easy merges | ❌ Conflict-prone |
| **History** | ⚠️ Can bloat (use --squash) | ✅ Separate history |

**We chose subtree because:**
- Developers don't need to know about subtrees
- `git clone` just works (no extra steps)
- Scripts are immediately visible/executable
- `--squash` keeps history clean

### Subtree States

Your project can be in these states:

**1. No Subtree**
```bash
# No .devenv/scripts/ directory exists
# Not in git history
```

**2. Subtree Added**
```bash
# .devenv/scripts/ exists
# Git knows it's a subtree (from commit metadata)
```

**3. Subtree Modified Locally**
```bash
# You edited files in .devenv/scripts/
# Ready to push back to central repo
```

**4. Subtree Out of Sync**
```bash
# Central repo has updates
# Need to pull to get latest
```

### Detecting Subtree Status

The scripts check subtree state:

```bash
# Check if subtree exists in git history
SUBTREE_IN_HISTORY=$(git log --all --grep="git-subtree-dir: .devenv/scripts" \
  --pretty=format:"%H" | head -1)

# Check if directory exists on disk
if [ -d ".devenv/scripts" ]; then
  SUBTREE_ON_DISK=true
fi

# Decision logic
if [ -n "$SUBTREE_IN_HISTORY" ] && [ "$SUBTREE_ON_DISK" = true ]; then
  # UPDATE: Use git subtree pull
  git subtree pull --prefix .devenv/scripts ...
elif [ -n "$SUBTREE_IN_HISTORY" ]; then
  # RESTORE: Directory deleted, use git subtree add to restore
  git subtree add --prefix .devenv/scripts ...
else
  # NEW: First time, use git subtree add
  git subtree add --prefix .devenv/scripts ...
fi
```

This handles edge cases like:
- Directory manually deleted
- Fresh clone
- Corrupted state

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

**Step 1: Pull from central repo**
```bash
git subtree pull --prefix .devcontainer \
  git@github.com:e2e2-dev/.dev-env-container.git main --squash
```

Files now in `.devcontainer/` with placeholders intact.

**Step 2: Read variables from config.yaml**
```bash
# Using yq
PROJECT_NAME=$(yq eval '.variables.PROJECT_NAME' .devenv/config.yaml)
WORKSPACE_PATH=$(yq eval '.variables.WORKSPACE_PATH' .devenv/config.yaml)
PYTHON_VERSION=$(yq eval '.variables.PYTHON_VERSION' .devenv/config.yaml)
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

**Full implementation:**

```bash
#!/bin/bash
# substitute-variables.sh - Replace {{VARIABLE}} placeholders

set -e

CONFIG_FILE="${1:-.devenv/config.yaml}"

# Read all variables from config.yaml
declare -A VARS

while IFS= read -r line; do
    # Parse YAML variables section
    if [[ "$line" =~ ^[[:space:]]*([A-Z_]+):[[:space:]]*\"?([^\"]*)\"?$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        VARS["$var_name"]="$var_value"
    fi
done < <(yq eval '.variables' "$CONFIG_FILE" -o=yaml)

# For each substitution rule
while IFS= read -r file; do
    if [ -f "$file" ]; then
        echo "Substituting variables in: $file"

        # Replace each variable
        for var_name in "${!VARS[@]}"; do
            var_value="${VARS[$var_name]}"
            sed -i "s|{{${var_name}}}|${var_value}|g" "$file"
        done
    fi
done < <(yq eval '.substitutions[].files[]' "$CONFIG_FILE")
```

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

# Output shows:
# - Changed files
# - Line changes
# - Feature branch name
# - PR creation command
```

**Example output:**
```
📤 Pushing changes to central repositories...

ℹ Processing claude...
   Changes detected:
     .claude/CLAUDE.md | 15 +++++++++------
     .claude/knowledge/standards/coding-standards.md | 25 ++++++++++++++++++++++
     2 files changed, 34 insertions(+), 6 deletions(-)

   This will:
   1. Create branch: feature/update-from-my-project-20251016-230145
   2. Push changes to central repo
   3. Allow you to create a PR

   Continue? (y/N) y

ℹ Pushing to feature/update-from-my-project-20251016-230145...
✅ Pushed to branch: feature/update-from-my-project-20251016-230145

   Create PR with:
   gh pr create --repo e2e2-dev/.dev-env-claude \
     --head feature/update-from-my-project-20251016-230145 \
     --title "feat: improve coding standards" \
     --fill
```

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
- ✅ Automatic yq installation
- ✅ Auto-configured .gitignore

**Improved:**
- ✅ Made all `.claude/` configurations project-agnostic
- ✅ Removed 117KB of project-specific content
- ✅ Enhanced variable substitution system
- ✅ Fixed sync-push/pull bugs

**Removed:**
- ❌ Manual script downloads (now via git subtree)
- ❌ Complex config.yaml (now minimal template)
- ❌ Project-specific documentation from central repos

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
