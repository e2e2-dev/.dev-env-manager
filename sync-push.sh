#!/bin/bash
# sync-push.sh - Push changes to central repos

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$DEVENV_DIR/config.yaml"
TARGET="${1:-all}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "📤 Pushing changes to central repositories..."
echo ""

# Check if yq is available
if ! command -v yq &> /dev/null; then
    echo "❌ yq is required. Install: https://github.com/mikefarah/yq"
    exit 1
fi

# Function to push via subtree
push_subtree() {
    local name=$1
    local repo=$2
    local target=$3

    log_info "Processing $name..."

    cd "$PROJECT_ROOT"

    # Check if there are changes (both working tree and staged)
    if git diff HEAD --quiet "$target" 2>/dev/null; then
        log_success "No changes to push"
        return 0
    fi

    echo "   Changes detected:"
    git diff HEAD --stat "$target" 2>/dev/null | sed 's/^/     /'
    echo ""

    # Create feature branch name
    BRANCH_NAME="feature/update-from-$(basename "$PROJECT_ROOT")-$(date +%Y%m%d-%H%M%S)"

    echo "   This will:"
    echo "   1. Create branch: $BRANCH_NAME"
    echo "   2. Push changes to central repo"
    echo "   3. Allow you to create a PR"
    echo ""

    read -p "   Continue? (y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0

    # Push to new branch via subtree
    log_info "Pushing to $BRANCH_NAME..."
    git subtree push --prefix "$target" "https://github.com/$repo.git" "$BRANCH_NAME"

    echo ""
    log_success "Pushed to branch: $BRANCH_NAME"
    echo ""
    echo "   Create PR with:"
    echo "   gh pr create --repo $repo --head $BRANCH_NAME --title \"feat: update from $(basename "$PROJECT_ROOT")\" --fill"
    echo ""
}

# Process each source
for source_name in $(yq eval '.sources | keys | .[]' "$CONFIG_FILE"); do
    # Skip if not target
    if [ "$TARGET" != "all" ] && [ "$source_name" != "$TARGET" ]; then
        continue
    fi

    REPO=$(yq eval ".sources.$source_name.repo" "$CONFIG_FILE")
    TARGET_DIR=$(yq eval ".sources.$source_name.target" "$CONFIG_FILE")

    push_subtree "$source_name" "$REPO" "$TARGET_DIR"
done

log_success "Push complete!"
