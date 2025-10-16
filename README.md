# DevEnv Configuration Manager

**Centralized development environment configuration management for all Python projects.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

DevEnv Manager provides a simple, centralized way to manage development environment configurations across multiple projects using git subtree.

### What it manages:

- **`.devcontainer/`** - VS Code Dev Container configuration
- **`.claude/`** - Claude Code AI assistant configuration
- **`.continue/`** - Continue.dev AI coding assistant configuration

### Key Benefits:

✅ **One-Command Setup** - Install with a single curl command
✅ **Minimal Configuration** - Only edit project-specific variables
✅ **Auto-Updates** - Pull latest configurations easily
✅ **Consistent Across Projects** - Same setup everywhere
✅ **Version Controlled** - Track all changes via git

---

## Quick Start

### Installation (3 steps)

#### 1. Run the installer

From your project root:

```bash
curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash
```

This will:
- Set up `.devenv/scripts/` via git subtree
- Create `.devenv/config.yaml` from template
- Configure `.gitignore`
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

This pulls:
- `.devcontainer/` from `e2e2-dev/.dev-env-container`
- `.claude/` from `e2e2-dev/.dev-env-claude`
- `.continue/` from `e2e2-dev/.dev-env-continue`

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
├── README.md                      # This file
├── install.sh                     # One-command installer
├── scripts/
│   ├── devenv                     # Main CLI tool
│   ├── sync-pull.sh              # Pull from central repos
│   ├── sync-push.sh              # Push to central repos
│   └── substitute-variables.sh   # Variable substitution
├── templates/
│   └── config.yaml.template      # Configuration template
└── docs/
    └── SETUP-GUIDE.md            # Detailed setup guide
```

---

## How It Works

### Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: MANAGER (.dev-env-manager)                         │
│  - devenv CLI                                               │
│  - Helper scripts (sync-pull, sync-push, substitute)        │
│  - Documentation & templates                                │
└─────────────────────────────────────────────────────────────┘
                            ↓ (git subtree)
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: PROJECT (.devenv/config.yaml)                      │
│  - Only project-specific variables                          │
│  - Minimal configuration                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓ (pulls via devenv CLI)
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: CONFIGURATIONS                                      │
│  - .dev-env-container → .devcontainer/                     │
│  - .dev-env-claude → .claude/                              │
│  - .dev-env-continue → .continue/                          │
└─────────────────────────────────────────────────────────────┘
```

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

---

## Project Setup

### In Your Project

After installation, your project will have:

```
my-project/
├── .devenv/
│   ├── config.yaml          # ← Only file you edit
│   ├── devenv              # ← Symlink to scripts/devenv
│   └── scripts/            # ← Synced via git subtree
│       ├── devenv
│       ├── sync-pull.sh
│       ├── sync-push.sh
│       └── substitute-variables.sh
├── .devcontainer/          # ← Synced from .dev-env-container
├── .claude/                # ← Synced from .dev-env-claude
├── .continue/              # ← Synced from .dev-env-continue
└── .gitignore             # ← Updated to ignore synced dirs
```

### .gitignore Pattern

The installer adds:

```gitignore
# DevEnv Configuration Manager (synced via git subtree)
.devenv/scripts/

# Centralized configurations (synced from central repos)
.devcontainer/
.claude/
.continue/

# Keep local configuration
!.devenv/config.yaml
!.devenv/devenv
```

This ensures:
- ✅ Scripts are synced via git subtree (not duplicated)
- ✅ Config stays in your project repo
- ✅ Configurations are synced from central repos

---

## Updating Scripts

### Update DevEnv Manager scripts in your project

```bash
# Pull latest scripts from .dev-env-manager
git subtree pull --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash

# Or use convenience command (if implemented)
./.devenv/devenv self-update
```

### Contributing improvements

1. Edit scripts locally in `.devenv/scripts/`
2. Test in your project
3. Push to central repo:

```bash
git subtree push --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git feature/my-improvement
```

4. Create PR in `.dev-env-manager` repo
5. After merge, other projects can pull updates

---

## Requirements

- **Git** - Version control
- **yq** - YAML processor (auto-installed by installer)
- **SSH access** to GitHub (for private repos)

---

## Commands Reference

### devenv CLI

```bash
# Status
./.devenv/devenv status               # Show sync status

# Pull configurations
./.devenv/devenv pull all             # Pull all configs
./.devenv/devenv pull claude          # Pull specific config
./.devenv/devenv pull devcontainer
./.devenv/devenv pull continue

# Push improvements
./.devenv/devenv push claude          # Push changes to central repo
./.devenv/devenv push devcontainer
./.devenv/devenv push continue

# Help
./.devenv/devenv --help               # Show help
```

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

### Git subtree errors

If you get subtree conflicts:

```bash
# Remove and re-add
rm -rf .devenv/scripts
git subtree add --prefix .devenv/scripts \
  git@github.com:e2e2-dev/.dev-env-manager.git main --squash
```

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
