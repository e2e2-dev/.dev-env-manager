#!/bin/bash
# sync-pull.sh - Pull configurations from central repositories

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$DEVENV_DIR/config.yaml"
TARGET="${1:-all}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }

echo "📥 Pulling configurations from central repositories..."
echo ""

# Check if yq is available
if ! command -v yq &> /dev/null; then
    echo "❌ yq is required. Install: https://github.com/mikefarah/yq"
    exit 1
fi

# Process each source
for source_name in $(yq eval '.sources | keys | .[]' "$CONFIG_FILE"); do
    # Skip if not target
    if [ "$TARGET" != "all" ] && [ "$source_name" != "$TARGET" ]; then
        continue
    fi

    REPO=$(yq eval ".sources.$source_name.repo" "$CONFIG_FILE")
    BRANCH=$(yq eval ".sources.$source_name.branch // \"main\"" "$CONFIG_FILE")
    TARGET_DIR=$(yq eval ".sources.$source_name.target" "$CONFIG_FILE")

    log_info "Pulling $source_name from $REPO (branch: $BRANCH)..."

    cd "$PROJECT_ROOT"

    # Check if subtree exists in history AND on disk
    SUBTREE_IN_HISTORY=$(git log --all --grep="git-subtree-dir: $TARGET_DIR" --pretty=format:"%H" | head -1)

    if [ -n "$SUBTREE_IN_HISTORY" ] && [ -d "$TARGET_DIR" ]; then
        # Update existing subtree (exists in history AND on disk)
        git subtree pull --prefix "$TARGET_DIR" \
            "git@github.com:$REPO.git" "$BRANCH" --squash
    else
        # Add new subtree (either no history, or directory was removed)
        git subtree add --prefix "$TARGET_DIR" \
            "git@github.com:$REPO.git" "$BRANCH" --squash
    fi

    log_success "$source_name updated"
    echo ""
done

# Load variables for generation
if [ -f "$SCRIPT_DIR/variables.env" ]; then
    set -a  # Auto-export variables
    source "$SCRIPT_DIR/variables.env"
    set +a
fi

# Copy templates from devcontainer
if [ -d "$PROJECT_ROOT/.devcontainer/templates" ]; then
    log_info "Copying templates from .devcontainer/templates..."
    if [ -f "$PROJECT_ROOT/.devcontainer/templates/devcontainer.json.template" ]; then
        cp "$PROJECT_ROOT/.devcontainer/templates/devcontainer.json.template" \
           "$PROJECT_ROOT/.devcontainer/devcontainer.json"
    fi
    if [ -f "$PROJECT_ROOT/.devcontainer/templates/docker-compose.yml.template" ]; then
        cp "$PROJECT_ROOT/.devcontainer/templates/docker-compose.yml.template" \
           "$PROJECT_ROOT/.devcontainer/docker-compose.yml"
    fi
fi

# Run variable substitution
if [ -f "$SCRIPT_DIR/substitute-variables.sh" ]; then
    log_info "Substituting project-specific variables..."
    "$SCRIPT_DIR/substitute-variables.sh"
fi

# Generate .devcontainer/.env for Docker Compose
if [ -f "$SCRIPT_DIR/variables.env" ] && ([ "$TARGET" = "all" ] || [ "$TARGET" = "devcontainer" ]); then
    log_info "Generating .devcontainer/.env for Docker Compose..."

    cat > "$PROJECT_ROOT/.devcontainer/.env" <<EOF
# Generated from .devenv/variables.env - DO NOT EDIT MANUALLY
# Edit .devenv/variables.env and run: .devenv/devenv pull devcontainer

OBSIDIAN_VAULT_PATH=${OBSIDIAN_VAULT_PATH}
KNOWLEDGE_BASES_PATH=${KNOWLEDGE_BASES_PATH}
DATA_WORKSPACE_PATH=${DATA_WORKSPACE_PATH}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GEMINI_API_KEY=${GEMINI_API_KEY}
EOF

    log_success ".devcontainer/.env generated"
fi

# Generate .env.local for Continue.dev
if [ -f "$SCRIPT_DIR/variables.env" ] && ([ "$TARGET" = "all" ] || [ "$TARGET" = "continue" ]); then
    log_info "Generating .env.local for Continue.dev..."

    cat > "$PROJECT_ROOT/.env.local" <<EOF
# Generated from .devenv/variables.env - DO NOT EDIT MANUALLY
# Edit .devenv/variables.env and run: .devenv/devenv pull continue

GEMINI_API_KEY=${GEMINI_API_KEY}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
GITHUB_TOKEN=${GITHUB_TOKEN}
EOF

    log_success ".env.local generated"
fi

# Generate Continue assistant config if needed
if [ "$TARGET" = "all" ] || [ "$TARGET" = "continue" ]; then
    if [ -f "$PROJECT_ROOT/.continue/scripts/generate-assistant-config.sh" ]; then
        log_info "Generating Continue.dev assistant configuration..."
        cd "$PROJECT_ROOT"
        .continue/scripts/generate-assistant-config.sh
    fi
fi

echo ""
log_success "Pull complete!"
