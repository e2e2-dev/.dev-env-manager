#!/bin/bash
# install.sh - One-command installer for DevEnv Configuration Manager
# Usage: curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/install.sh | bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   DevEnv Configuration Manager - Installation Script     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository. Please run this from your project root."
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
log_info "Installing in: $PROJECT_ROOT"

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    log_error "Working tree has uncommitted changes."
    log_info "Please commit or stash your changes first:"
    echo "   git status"
    echo "   git add ."
    echo "   git commit -m 'your message'"
    exit 1
fi

# Check if .devenv already exists
if [ -d "$PROJECT_ROOT/.devenv/scripts" ]; then
    log_warning ".devenv/scripts already exists"
    read -p "   Reinstall? This will update scripts. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
fi

# Create .devenv directory
log_info "Creating .devenv directory..."
mkdir -p "$PROJECT_ROOT/.devenv"

# Add .devenv/scripts via git subtree
log_info "Setting up DevEnv scripts via git subtree..."
if [ -d "$PROJECT_ROOT/.devenv/scripts" ]; then
    log_info "Updating existing scripts..."
    git subtree pull --prefix .devenv/scripts \
        git@github.com:e2e2-dev/.dev-env-manager.git main --squash \
        -m "chore: update devenv scripts from central repo"
else
    log_info "Adding scripts for the first time..."
    git subtree add --prefix .devenv/scripts \
        git@github.com:e2e2-dev/.dev-env-manager.git main --squash \
        -m "chore: add devenv scripts from central repo"
fi

# Create symlink to devenv CLI
log_info "Creating devenv CLI symlink..."
cd "$PROJECT_ROOT/.devenv"
ln -sf scripts/devenv devenv
chmod +x scripts/devenv 2>/dev/null || true

# Download config.yaml.example if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.devenv/config.yaml.example" ]; then
    log_info "Creating config.yaml.example from template..."
    curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/templates/config.yaml.template \
        -o "$PROJECT_ROOT/.devenv/config.yaml.example"
    log_success "config.yaml.example created!"
else
    log_info "config.yaml.example already exists, skipping"
fi

# Create config.yaml from example if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.devenv/config.yaml" ]; then
    log_info "Creating config.yaml from config.yaml.example..."
    cp "$PROJECT_ROOT/.devenv/config.yaml.example" "$PROJECT_ROOT/.devenv/config.yaml"

    log_success "config.yaml created!"
    log_warning "IMPORTANT: Edit .devenv/config.yaml and update:"
    echo "  - PROJECT_NAME"
    echo "  - WORKSPACE_PATH"
else
    log_info "config.yaml already exists, skipping"
fi

# Download .env.local template if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.env.local" ]; then
    log_info "Creating .env.local from template..."
    curl -sSL https://raw.githubusercontent.com/e2e2-dev/.dev-env-manager/main/templates/.env.local.template \
        -o "$PROJECT_ROOT/.env.local"
    log_success ".env.local created!"
    log_info "Edit .env.local to add your API keys (optional)"
else
    log_info ".env.local already exists, skipping template download"
fi

# Update .gitignore
log_info "Updating .gitignore..."
GITIGNORE="$PROJECT_ROOT/.gitignore"

if [ -f "$GITIGNORE" ]; then
    # Check if patterns already exist
    if ! grep -q "^\.devenv/scripts/" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# DevEnv Configuration Manager (synced via git subtree)" >> "$GITIGNORE"
        echo ".devenv/scripts/" >> "$GITIGNORE"
        echo ".devenv/config.yaml" >> "$GITIGNORE"
        echo "" >> "$GITIGNORE"
        echo "# Keep templates and symlink" >> "$GITIGNORE"
        echo "!.devenv/config.yaml.example" >> "$GITIGNORE"
        echo "!.devenv/devenv" >> "$GITIGNORE"
        log_success "Updated .gitignore"
    else
        log_info ".gitignore already configured"
    fi
else
    log_warning ".gitignore not found, creating one..."
    cat > "$GITIGNORE" << 'EOF'
# DevEnv Configuration Manager (synced via git subtree)
.devenv/scripts/
.devenv/config.yaml

# Centralized configurations (synced from central repos)
.devcontainer/
.claude/
.continue/

# Secrets (NEVER commit!)
.env.local

# Keep templates and symlink
!.devenv/config.yaml.example
!.devenv/devenv
EOF
    log_success "Created .gitignore"
fi

# Check for yq installation
log_info "Checking for yq..."
if ! command -v yq &> /dev/null; then
    log_warning "yq not found. Installing to ~/.local/bin/yq..."
    mkdir -p ~/.local/bin
    curl -sSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
        -o ~/.local/bin/yq
    chmod +x ~/.local/bin/yq

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_info "Adding ~/.local/bin to PATH..."
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi

    log_success "yq installed successfully"
else
    log_success "yq already installed"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation Complete! 🎉                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Edit configuration:"
echo -e "   ${BLUE}vim .devenv/config.yaml${NC}"
echo "   Update PROJECT_NAME and WORKSPACE_PATH"
echo ""
echo "2. Pull centralized configurations:"
echo -e "   ${BLUE}./.devenv/devenv pull all${NC}"
echo ""
echo "3. Commit the changes:"
echo -e "   ${BLUE}git add .devenv/config.yaml.example .devenv/devenv .gitignore${NC}"
echo -e "   ${BLUE}git commit -m 'feat: add devenv configuration manager'${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} .devenv/config.yaml is gitignored (local only)"
echo "      Only .devenv/config.yaml.example is tracked"
echo ""
echo -e "${BLUE}For help: ./.devenv/devenv --help${NC}"
echo -e "${BLUE}For status: ./.devenv/devenv status${NC}"
echo ""
