#!/bin/bash
# substitute-variables.sh - Replace {{VARIABLES}} in configs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.yaml"
VARS_FILE="$SCRIPT_DIR/variables.env"

# Load variables from variables.env
if [ -f "$VARS_FILE" ]; then
    set -a  # Auto-export variables
    source "$VARS_FILE"
    set +a
fi

# Check if yq is available
if ! command -v yq &> /dev/null; then
    echo "⚠️  yq not found, skipping variable substitution"
    exit 0
fi

# Load variables from config.yaml
for key in $(yq eval '.variables | keys | .[]' "$CONFIG_FILE" 2>/dev/null); do
    VALUE=$(yq eval ".variables.$key" "$CONFIG_FILE")
    export "$key=$VALUE"
done

echo "🔄 Substituting variables in configuration files..."

# Get number of substitution rules
NUM_RULES=$(yq eval '.substitutions | length' "$CONFIG_FILE" 2>/dev/null)

# Process each substitution rule
for ((i=0; i<$NUM_RULES; i++)); do
    # Get files for this rule
    for file in $(yq eval ".substitutions[$i].files[]" "$CONFIG_FILE"); do
        FILE_PATH="$PROJECT_ROOT/$file"

        if [ ! -f "$FILE_PATH" ]; then
            continue
        fi

        echo "   📝 Processing $file"

        # Create backup
        cp "$FILE_PATH" "$FILE_PATH.bak"

        # Get variables for this rule and replace each
        for var in $(yq eval ".substitutions[$i].variables[]" "$CONFIG_FILE"); do
            VALUE="${!var}"
            if [ -n "$VALUE" ]; then
                sed -i "s|{{${var}}}|${VALUE}|g" "$FILE_PATH"
            fi
        done

        # Remove backup if identical
        if diff -q "$FILE_PATH" "$FILE_PATH.bak" >/dev/null 2>&1; then
            rm "$FILE_PATH.bak"
        else
            echo "      ✓ Substituted variables"
            rm "$FILE_PATH.bak"
        fi
    done
done

echo "✅ Variable substitution complete"
