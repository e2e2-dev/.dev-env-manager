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

# Function to push via direct file copy (works with gitignored directories)
push_subtree() {
    local name=$1
    local repo=$2
    local branch=$3
    local target=$4

    log_info "Processing $name..."

    cd "$PROJECT_ROOT"

    # Check if directory exists
    if [ ! -d "$PROJECT_ROOT/$target" ]; then
        log_warning "Directory not found: $target"
        return 0
    fi

    # Check if directory has VERSION file to determine it was properly pulled
    if [ ! -f "$PROJECT_ROOT/$target/VERSION" ]; then
        log_warning "No VERSION file found. Run 'devenv pull $name' first."
        return 0
    fi

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Clone remote repo
    log_info "Cloning remote repository..."
    if ! git clone -q "git@github.com:$repo.git" "$TEMP_DIR/remote" 2>/dev/null; then
        log_warning "Failed to clone remote repository"
        rm -rf "$TEMP_DIR"
        return 0
    fi

    cd "$TEMP_DIR/remote"

    # Checkout the branch
    if ! git checkout -q "$branch" 2>/dev/null; then
        log_warning "Cannot checkout branch $branch"
        cd "$PROJECT_ROOT"
        rm -rf "$TEMP_DIR"
        return 0
    fi

    # Create restored directory with placeholders
    mkdir -p "$TEMP_DIR/restored"
    log_info "Restoring placeholders in local files for comparison..."

    # Copy local files and restore placeholders
    if [ -d "$PROJECT_ROOT/$target" ]; then
        # Copy entire directory structure first
        cp -r "$PROJECT_ROOT/$target/"* "$TEMP_DIR/restored/" 2>/dev/null || true

        # Restore placeholders using our script
        "$SCRIPT_DIR/restore-placeholders.sh" "$TEMP_DIR/restored" "$TEMP_DIR/restored" "$name" 2>/dev/null || true
    fi

    # Compare restored local files (with placeholders) with remote (also with placeholders)
    LOCAL_CHANGES=$(diff -r -q "$TEMP_DIR/restored" "$TEMP_DIR/remote" 2>/dev/null | grep -v "^Only in $TEMP_DIR/remote" | wc -l || echo "0")

    if [ "$LOCAL_CHANGES" -eq 0 ]; then
        log_success "No changes to push"
        cd "$PROJECT_ROOT"
        rm -rf "$TEMP_DIR"
        return 0
    fi

    echo "   Changes detected (comparing files with placeholders restored):"
    diff -r -q "$TEMP_DIR/restored" "$TEMP_DIR/remote" 2>/dev/null | grep -v "^Only in $TEMP_DIR/remote" | sed 's|'"$TEMP_DIR/restored"'|local|g' | sed 's|'"$TEMP_DIR/remote"'|remote|g' | sed 's/^/     /' || true
    echo ""

    # Create feature branch name
    BRANCH_NAME="feature/update-from-$(basename "$PROJECT_ROOT")-$(date +%Y%m%d-%H%M%S)"

    echo "   This will:"
    echo "   1. Create branch: $BRANCH_NAME"
    echo "   2. Copy local files to remote repo"
    echo "   3. Commit and push changes"
    echo "   4. Allow you to create a PR"
    echo ""

    read -p "   Continue? (y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0

    # Create new branch
    git checkout -b "$BRANCH_NAME" 2>/dev/null

    # Copy files from restored directory (with placeholders) to remote
    log_info "Copying changes with placeholders restored..."
    rsync -av --delete --exclude='.git' "$TEMP_DIR/restored/" "$TEMP_DIR/remote/" > /dev/null

    # Check if there are actual changes to commit
    if git diff --quiet && git diff --cached --quiet; then
        log_warning "No changes after file copy"
        cd "$PROJECT_ROOT"
        rm -rf "$TEMP_DIR"
        return 0
    fi

    # Stage all changes
    git add -A

    # Create commit
    COMMIT_MSG="feat: update from $(basename "$PROJECT_ROOT")

Changes synchronized from local project.

Updated files:
$(git diff --cached --name-only | sed 's/^/- /')"

    git commit -m "$COMMIT_MSG" 2>/dev/null

    # Push to remote
    log_info "Pushing to $BRANCH_NAME..."
    if git push -u origin "$BRANCH_NAME" 2>&1; then
        echo ""
        log_success "Pushed to branch: $BRANCH_NAME"
        echo ""
        echo "   Create PR with:"
        echo "   gh pr create --repo $repo --head $BRANCH_NAME --title \"feat: update from $(basename "$PROJECT_ROOT")\" --fill"
        echo ""
    else
        log_warning "Push failed"
    fi

    cd "$PROJECT_ROOT"
    rm -rf "$TEMP_DIR"
}

# Process each source
for source_name in $(yq eval '.sources | keys | .[]' "$CONFIG_FILE"); do
    # Skip if not target
    if [ "$TARGET" != "all" ] && [ "$source_name" != "$TARGET" ]; then
        continue
    fi

    REPO=$(yq eval ".sources.$source_name.repo" "$CONFIG_FILE")
    BRANCH=$(yq eval ".sources.$source_name.branch // \"main\"" "$CONFIG_FILE")
    TARGET_DIR=$(yq eval ".sources.$source_name.target" "$CONFIG_FILE")

    push_subtree "$source_name" "$REPO" "$BRANCH" "$TARGET_DIR"
done

log_success "Push complete!"
