#!/usr/bin/env bash

NIRI_CONFIG_DIR="$HOME/.config/niri"
NIRI_CONFIG="$NIRI_CONFIG_DIR/config.kdl"
CONFIG_FILES=("keybinds.kdl" "rice.kdl" "extras.kdl")

# Create config directory if it doesn't exist
mkdir -p "$NIRI_CONFIG_DIR"

# Check if niri is installed
if ! command -v niri &> /dev/null; then
    echo "⚠️ Niri not found - skipping validation" >&2
    Niri_validate=false
else
    niri_validate=true
fi

# Find and validate config files
valid_configs=()
invalid_configs=()

for file in "${CONFIG_FILES[@]}"; do
    file_path="$NIRI_CONFIG_DIR/$file"

    if [[ ! -f "$file_path" ]]; then
        echo "⚠️ Config file not found: $file" >&2
        continue
    fi

    if $niri_validate; then
        if niri validate -c "$file_path"; then
            valid_configs+=("$file_path")
        else
            invalid_configs+=("$file")
        fi
    else
        valid_configs+=("$file_path")
    fi
done

# If no valid configs, exit early
if [[ ${#valid_configs[@]} -eq 0 ]]; then
    echo "❌ No valid config files found" >&2
    exit 1
fi

# Generate combined config
cat > "$NIRI_CONFIG" <<EOF
niri {
    $(cat "${valid_configs[@]}")
}
EOF

# Final validation if niri is available
if $niri_validate; then
    if ! niri validate "$NIRI_CONFIG"; then
        echo "⚠️ Final config may have issues - validation failed" >&2
    else
        echo "✅ Niri config successfully validated and generated at $NIRI_CONFIG"
    fi
else
    echo "⚠️ Niri not available - config generated but not validated" >&2
fi

# Report invalid files
if [[ ${#invalid_configs[@]} -gt 0 ]]; then
    echo "⚠️ The following config files were invalid and skipped:" >&2
    for file in "${invalid_configs[@]}"; do
        echo "  - $file" >&2
    done
fi
