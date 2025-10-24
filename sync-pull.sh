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

    # Create temp directory for cloning
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Clone the repo to temp directory (shallow clone for speed)
    git clone --depth 1 --branch "$BRANCH" --single-branch \
        "git@github.com:$REPO.git" "$TEMP_DIR/$source_name" 2>&1 | \
        grep -v "^Cloning into" || true

    # Remove .git directory from cloned repo to avoid git tracking
    rm -rf "$TEMP_DIR/$source_name/.git"

    # Remove target directory if it exists
    rm -rf "$TARGET_DIR"

    # Copy contents to target directory
    mkdir -p "$(dirname "$TARGET_DIR")"
    mv "$TEMP_DIR/$source_name" "$TARGET_DIR"

    # Clean up temp directory
    rm -rf "$TEMP_DIR"

    log_success "$source_name updated"
    echo ""
done

# Load variables for generation
# First load from variables.env if it exists (legacy support)
if [ -f "$SCRIPT_DIR/variables.env" ]; then
    set -a  # Auto-export variables
    source "$SCRIPT_DIR/variables.env"
    set +a
fi

# Then load from config.yaml (takes precedence)
if [ -f "$CONFIG_FILE" ]; then
    log_info "Loading variables from config.yaml..."
    for key in $(yq eval '.variables | keys | .[]' "$CONFIG_FILE" 2>/dev/null); do
        VALUE=$(yq eval ".variables.$key" "$CONFIG_FILE")
        export "$key=$VALUE"
    done
fi

# Also load secrets from .env.local
ENV_LOCAL="$PROJECT_ROOT/.env.local"
if [ -f "$ENV_LOCAL" ]; then
    set -a  # Auto-export variables
    source "$ENV_LOCAL"
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
if [ -f "$CONFIG_FILE" ] && ([ "$TARGET" = "all" ] || [ "$TARGET" = "devcontainer" ]); then
    log_info "Generating .devcontainer/.env for Docker Compose..."

    cat > "$PROJECT_ROOT/.devcontainer/.env" <<EOF
# Generated from .devenv/config.yaml - DO NOT EDIT MANUALLY
# Edit .devenv/config.yaml and run: .devenv/devenv pull devcontainer

OBSIDIAN_VAULT_PATH=${OBSIDIAN_VAULT_PATH}
PRACTICES_PATH=${PRACTICES_PATH}
KNOWLEDGE_BASES_PATH=${KNOWLEDGE_BASES_PATH}
DATA_WORKSPACE_PATH=${DATA_WORKSPACE_PATH}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GEMINI_API_KEY=${GEMINI_API_KEY}
EOF

    log_success ".devcontainer/.env generated"
fi

# Generate .env.local for Continue.dev
if [ -f "$CONFIG_FILE" ] && ([ "$TARGET" = "all" ] || [ "$TARGET" = "continue" ]); then
    log_info "Generating .env.local for Continue.dev..."

    cat > "$PROJECT_ROOT/.env.local" <<EOF
# Generated from .devenv/config.yaml and .env.local - DO NOT EDIT MANUALLY
# Edit .devenv/config.yaml or .env.local and run: .devenv/devenv pull continue

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
