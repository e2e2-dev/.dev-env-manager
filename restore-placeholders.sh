#!/bin/bash
# restore-placeholders.sh - Restore {{PLACEHOLDERS}} in files for comparison/push
#
# Usage:
#   restore-placeholders.sh <source_dir> <dest_dir> [target_name]
#
# Arguments:
#   source_dir  - Directory containing files with actual values
#   dest_dir    - Directory to write files with restored placeholders
#   target_name - Optional: only restore for specific target (claude, devcontainer, continue)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEVENV_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$DEVENV_DIR/config.yaml"

SOURCE_DIR="${1:-$PROJECT_ROOT}"
DEST_DIR="${2:-$SOURCE_DIR}"
TARGET_FILTER="${3:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check if yq is available
if ! command -v yq &> /dev/null; then
    echo "⚠️  yq not found, skipping placeholder restoration"
    exit 0
fi

# Load variables from config.yaml
declare -A VARIABLES
for key in $(yq eval '.variables | keys | .[]' "$CONFIG_FILE" 2>/dev/null); do
    VALUE=$(yq eval ".variables.$key" "$CONFIG_FILE")
    VARIABLES["$key"]="$VALUE"
done

# Also load from .env.local if it exists (to get actual runtime values)
ENV_LOCAL="$PROJECT_ROOT/.env.local"
if [ -f "$ENV_LOCAL" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # Remove quotes from value
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        VARIABLES["$key"]="$value"
    done < "$ENV_LOCAL"
fi

# Function to escape string for use in sed replacement
escape_for_sed() {
    local string="$1"
    # Escape special characters: / \ & $ * . [ ] ^ |
    echo "$string" | sed -e 's/[\/&]/\\&/g' -e 's/\$/\\$/g' -e 's/\./\\./g'
}

log_info "Restoring placeholders from $SOURCE_DIR to $DEST_DIR..."

# Get number of substitution rules
NUM_RULES=$(yq eval '.substitutions | length' "$CONFIG_FILE" 2>/dev/null)

# Track if any files were processed
FILES_PROCESSED=0

# Process each substitution rule
for ((i=0; i<$NUM_RULES; i++)); do
    # Get files for this rule
    for file in $(yq eval ".substitutions[$i].files[]" "$CONFIG_FILE"); do
        # If target filter is set, check if this file belongs to the target
        if [ -n "$TARGET_FILTER" ]; then
            FILE_TARGET=$(echo "$file" | cut -d'/' -f1 | sed 's/^\.//')
            if [ "$FILE_TARGET" != "$TARGET_FILTER" ]; then
                continue
            fi
            # Strip the target prefix from the file path
            FILE_RELATIVE=$(echo "$file" | sed "s|^\.${TARGET_FILTER}/||" | sed "s|^${TARGET_FILTER}/||")
        else
            FILE_RELATIVE="$file"
        fi

        SOURCE_FILE="$SOURCE_DIR/$FILE_RELATIVE"
        DEST_FILE="$DEST_DIR/$FILE_RELATIVE"

        # Skip if source file doesn't exist
        if [ ! -f "$SOURCE_FILE" ]; then
            continue
        fi

        # Create destination directory if it doesn't exist
        DEST_DIR_PATH=$(dirname "$DEST_FILE")
        mkdir -p "$DEST_DIR_PATH"

        # Copy file to destination
        cp "$SOURCE_FILE" "$DEST_FILE"

        # Get variables for this rule and restore placeholders
        VAR_COUNT=0
        for var in $(yq eval ".substitutions[$i].variables[]" "$CONFIG_FILE"); do
            VALUE="${VARIABLES[$var]}"

            if [ -n "$VALUE" ]; then
                # Escape the value for sed
                ESCAPED_VALUE=$(escape_for_sed "$VALUE")

                # Replace value with {{VARIABLE_NAME}}
                sed -i "s|${ESCAPED_VALUE}|{{${var}}}|g" "$DEST_FILE"
                VAR_COUNT=$((VAR_COUNT + 1))
            fi
        done

        if [ $VAR_COUNT -gt 0 ]; then
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
            if [ "$SOURCE_DIR" != "$DEST_DIR" ]; then
                echo "   📝 Restored placeholders in $FILE_RELATIVE ($VAR_COUNT variables)"
            fi
        fi
    done
done

if [ $FILES_PROCESSED -gt 0 ]; then
    log_success "Restored placeholders in $FILES_PROCESSED file(s)"
else
    log_info "No files needed placeholder restoration"
fi
