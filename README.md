# DevEnv Configuration Manager

**Centralized development environment configuration management for all projects.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

DevEnv Manager provides a simple, centralized way to manage development environment configurations across multiple projects. Manager scripts are downloaded fresh (like node_modules) and kept outside git tracking, while configurations are pulled directly from central repositories with variable substitution.

### What it manages:

- **`.devcontainer/`** - VS Code Dev Container configuration
- **`.claude/`** - Claude Code AI assistant configuration
- **`.continue/`** - Continue.dev AI coding assistant configuration

### Key Benefits:

✅ **One-Command Setup** - Install with a single curl command
✅ **Minimal Configuration** - Only edit project-specific variables
✅ **Auto-Updates** - Pull latest configurations easily
✅ **Consistent Across Projects** - Same setup everywhere
✅ **Smart Syncing** - Scripts downloaded fresh, configs cloned with variable substitution

---

## Quick Start

### Installation (3 steps)

#### 1. Run the installer

From your project root:

```bash
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash
```

This will:
- Download `.devenv/scripts/` from central repo (not tracked in git)
- Create `.devenv/config.yaml` from template
- Configure `.gitignore` to exclude `.devenv/scripts/`
- Install `yq` if needed

#### 2. Edit your configuration

```bash
vim .devenv/config.yaml
```

Update these two variables:
```yaml
variables:
  PROJECT_NAME: my-awesome-project       # ← Change this
  WORKSPACE_PATH: /workspaces/my-awesome-project  # ← Change this
```

#### 3. Pull configurations

```bash
./.devenv/devenv pull all
```

This clones and syncs:
- `.devcontainer/` from `e2e2-dev/.dev-env-container`
- `.claude/` from `e2e2-dev/.dev-env-claude`
- `.continue/` from `e2e2-dev/.dev-env-continue`

Then automatically substitutes your project-specific variables.

**Done!** 🎉 Your project now has centralized dev environment configuration.

---

## Daily Usage

### Check status

```bash
./.devenv/devenv status
```

Shows what's synced and if updates are available.

### Pull updates

When central configurations are updated:

```bash
# Pull all configurations
./.devenv/devenv pull all

# Or pull specific config
./.devenv/devenv pull claude
./.devenv/devenv pull devcontainer
./.devenv/devenv pull continue
```

### Push improvements

Made improvements to shared configs?

```bash
# Push changes to central repo
./.devenv/devenv push claude

# Creates feature branch and shows PR creation command
```

---

## Repository Structure

```
.dev-env-manager/
├── README.md                      # This file (Quick start & overview)
├── VERSION                        # Version tracking
├── LICENSE                        # MIT License
│
├── install.sh                     # One-command installer (bootstrap)
│
├── devenv                         # Main CLI tool
├── sync-pull.sh                   # Pull configs from central repos
├── sync-push.sh                   # Push improvements to central repos
├── substitute-variables.sh        # Replace {{VARIABLES}} in configs
├── restore-placeholders.sh        # Restore {{PLACEHOLDERS}} for comparison
│
├── templates/
│   ├── config.yaml.template       # Project configuration template
│   └── .env.local.template        # Secrets template (all commented)
│
└── docs/
    └── SETUP-GUIDE.md             # Detailed setup & internals guide
```

**Key Files:**

- **`install.sh`** - Bootstrap installer run via curl, sets up `.devenv/` in projects
- **`devenv`** - Main CLI with commands: pull, push, status, scripts-status, self-update
- **`sync-pull.sh`** - Clones central repos, copies files, runs variable substitution
- **`sync-push.sh`** - Compares local changes, restores placeholders, creates PRs
- **`substitute-variables.sh`** - Replaces `{{VARIABLE}}` with actual values
- **`restore-placeholders.sh`** - Reverse operation: replaces values with `{{VARIABLE}}`

---

## How It Works

### Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: MANAGER (.dev-env-manager)                         │
│  GitHub: e2e2-dev/.dev-env-manager                         │
│  - devenv CLI & helper scripts                              │
│  - install.sh (bootstrap installer)                         │
│  - Templates (config.yaml, .env.local)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
                  (shallow clone to .devenv/scripts/)
                  (NOT tracked in project git)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: PROJECT LAYER (.devenv/)                           │
│  In your project: my-project/.devenv/                       │
│  - config.yaml (PROJECT_NAME, WORKSPACE_PATH, secrets)      │
│  - scripts/ (downloaded fresh, gitignored)                  │
│  - devenv (symlink to scripts/devenv)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
                  (clone, copy & substitute via devenv pull)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: CONFIGURATIONS (Central Repos)                     │
│  - e2e2-dev/.dev-env-container → .devcontainer/            │
│  - e2e2-dev/.dev-env-claude → .claude/                     │
│  - e2e2-dev/.dev-env-continue → .continue/                 │
│                                                             │
│  (Cloned, copied, and variables substituted)                │
└─────────────────────────────────────────────────────────────┘
```

### How Syncing Works

**DevEnv Scripts (Tier 1 → Tier 2):**
- Downloaded via **shallow git clone** (not tracked in your project git)
- Scripts live in `.devenv/scripts/` (gitignored, like `node_modules`)
- Update with `devenv self-update` (downloads fresh copy)
- VERSION file tracks which version you have
- Push improvements via `devenv push devenv-scripts` (creates PR)

**Configurations (Tier 3 → Tier 2):**
- Managed via **shallow clone and copy** (also not tracked in git)
- Cloned to temp directory, .git removed, files copied
- No git history mixing with your project
- Variable substitution applied after copying
- Push improvements via `devenv push <target>` (creates PR)

### Variable Substitution

Configuration templates use `{{VARIABLE}}` placeholders:

```json
// Template in central repo
{
  "name": "{{PROJECT_NAME}}",
  "workspaceFolder": "{{WORKSPACE_PATH}}"
}

// After substitution in your project
{
  "name": "my-awesome-project",
  "workspaceFolder": "/workspaces/my-awesome-project"
}
```

**Substitution happens automatically** when you run `devenv pull`.

---

## Project Setup

### In Your Project

After installation, your project will have:

```
my-project/
├── .devenv/
│   ├── config.yaml          # ← Only file you edit (tracked in git)
│   ├── config.yaml.example  # ← Template (tracked in git)
│   ├── devenv              # ← Symlink to scripts/devenv (gitignored)
│   └── scripts/            # ← Downloaded from central repo (gitignored)
│       ├── devenv
│       ├── sync-pull.sh
│       ├── sync-push.sh
│       └── substitute-variables.sh
├── .devcontainer/          # ← Synced from .dev-env-container (gitignored)
├── .claude/                # ← Synced from .dev-env-claude (gitignored)
├── .continue/              # ← Synced from .dev-env-continue (gitignored)
└── .gitignore             # ← Updated to ignore synced dirs
```

### .gitignore Pattern

The installer configures:

```gitignore
# Development environment & AI assistants
# DevEnv: Everything managed by .dev-env-manager installer
# https://github.com/e2e2-dev/.dev-env-manager
.devcontainer/
.claude/
.continue/
.devenv/scripts/     # Downloaded from central repo, not tracked in project
.devenv/devenv       # Symlink to scripts/devenv
.devenv/.env         # Generated from config.yaml

# Environment variables & secrets
# NEVER commit these files - they contain secrets!
.env.local
```

This ensures:
- ✅ **Scripts** in `.devenv/scripts/` downloaded fresh (not tracked, like `node_modules`)
- ✅ **Configurations** (`.devcontainer/`, `.claude/`, `.continue/`) pulled fresh each time
- ✅ **Config files** (`.devenv/config.yaml`) can be tracked or gitignored (your choice)
- ✅ **Config examples** (`.devenv/config.yaml.example`) can be tracked if desired
- ✅ **Secrets** (`.env.local`) never committed

---

## Updating Scripts

### Update DevEnv Manager scripts in your project

```bash
# Use the built-in command
./.devenv/devenv self-update
```

The `self-update` command:
- Downloads latest scripts from central `.dev-env-manager` repo
- Replaces `.devenv/scripts/` with fresh copy
- Updates VERSION file to track which version you have
- Warns if you need to restart active shells

**Note**: Since scripts are downloaded fresh (not tracked in git), you can safely delete `.devenv/scripts/` anytime and re-run the installer to get a clean copy.

### Contributing Script Improvements

When you improve the manager scripts themselves:

1. **Edit scripts** locally in `.devenv/scripts/`
2. **Test thoroughly** in your project
3. **Check status** to see what changed:
   ```bash
   ./.devenv/devenv scripts-status
   ```
4. **Push to central repo** using the devenv command:
   ```bash
   ./.devenv/devenv push devenv-scripts
   ```
   This creates a feature branch in `.dev-env-manager` repo
5. **Create PR** in `.dev-env-manager` repository
6. **After merge**, other projects can pull updates with `devenv self-update`

---

## Requirements

- **Git** - Version control
- **yq** - YAML processor (auto-installed by installer)
- **SSH access** to GitHub (for private repos)

---

## Commands Reference

### devenv CLI

```bash
# Status & Information
./.devenv/devenv status               # Show configuration sync status
./.devenv/devenv scripts-status       # Show DevEnv scripts status
./.devenv/devenv help                 # Show help message

# Pull configurations from central repos
./.devenv/devenv pull all             # Pull all configs
./.devenv/devenv pull devcontainer    # Pull specific config
./.devenv/devenv pull claude
./.devenv/devenv pull continue

# Push improvements to central repos
./.devenv/devenv push devcontainer    # Push changes (creates PR)
./.devenv/devenv push claude
./.devenv/devenv push continue
./.devenv/devenv push devenv-scripts  # Push script improvements

# Update DevEnv scripts
./.devenv/devenv self-update          # Pull latest scripts from central repo
```

### What Each Command Does

**`status`** - Shows configuration sync status:
- Checks each configuration directory (`.devcontainer/`, `.claude/`, `.continue/`)
- Compares local files (with placeholders restored) against remote versions
- Detects local modifications and upstream changes
- Shows if pull is needed

**`scripts-status`** - Shows DevEnv scripts status:
- Checks if `.devenv/scripts/` has local modifications
- Suggests `self-update` to check for upstream updates
- Suggests `push devenv-scripts` if you made improvements

**`pull [target]`** - Pulls configurations:
- Clones central repo to temp directory (shallow clone)
- Removes `.git` to avoid tracking conflicts
- Copies files to target directory
- Loads variables from `config.yaml` and `.env.local`
- Substitutes `{{VARIABLES}}` in configuration files
- Generates environment files (`.devcontainer/.env`, `.env.local`)

**`push [target]`** - Pushes improvements:
- Restores `{{PLACEHOLDERS}}` in your modified files
- Clones central repo and compares changes
- Creates feature branch with timestamp
- Commits and pushes changes
- Shows `gh pr create` command for creating PR

**`self-update`** - Updates DevEnv scripts:
- Reads devenv-scripts source from `config.yaml`
- Downloads latest scripts via shallow clone
- Replaces `.devenv/scripts/` with fresh copy
- Updates VERSION file for version tracking

---

## Troubleshooting

### `yq: command not found`

The installer should install yq automatically. If it doesn't:

```bash
mkdir -p ~/.local/bin
wget -qO ~/.local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x ~/.local/bin/yq
export PATH="$HOME/.local/bin:$PATH"
```

### Scripts not executable

```bash
chmod +x .devenv/scripts/*
chmod +x .devenv/devenv
```

### Scripts directory missing or corrupted

Since `.devenv/scripts/` is downloaded fresh (not tracked in git), you can easily fix issues:

```bash
# Delete the scripts directory
rm -rf .devenv/scripts

# Re-run the installer to download fresh copy
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash

# Or use self-update if devenv is still working
./.devenv/devenv self-update
```

This is much simpler than the old git subtree approach!

---

## Documentation

- **Quick Start**: This README
- **Detailed Guide**: [docs/SETUP-GUIDE.md](docs/SETUP-GUIDE.md)
- **Central Repos**:
  - [.dev-env-container](https://github.com/e2e2-dev/.dev-env-container) - Dev Container configs
  - [.dev-env-claude](https://github.com/e2e2-dev/.dev-env-claude) - Claude Code configs
  - [.dev-env-continue](https://github.com/e2e2-dev/.dev-env-continue) - Continue.dev configs

---

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test in a real project
5. Submit a pull request

---

## License

MIT License - See LICENSE file for details

---

## Support

- **Issues**: [GitHub Issues](https://github.com/e2e2-dev/.dev-env-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/e2e2-dev/.dev-env-manager/discussions)

---

**Made with ❤️ for developers who value consistency and simplicity.**
