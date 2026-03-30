#!/usr/bin/env bash

# Ensure readlink -f is available
if ! readlink -f "$0" >/dev/null 2>&1; then
  echo "Error: 'readlink -f' is required. Please install coreutils."
  echo "  On Termux: pkg install coreutils"
  echo "  On macOS:  brew install coreutils"
  exit 1
fi

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dots-bak"
LOG_FILE="$BACKUP_DIR/restore_log.txt"

# Infrastructure files to ignore for auto-linking to ~/.config
IGNORE=(
  "." ".." ".git" ".gitignore" ".github" "README.md" "LICENSE" 
  "install.sh" "setup.sh" "uninstall.sh" "update.sh" "ascii" "yolk.rhai"
  ".bashrc" ".zshrc" ".profile" ".gitconfig" "scripts" ".bin"
)

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  echo "Created backup directory: $BACKUP_DIR"
fi

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
fi

echo "Setting up dotfiles (autodetect mode) from $DOTS_DIR..."
echo "Backups will be stored in $BACKUP_DIR"

link_config() {
  local source="$1"
  local target="$2"

  if [ ! -e "$source" ]; then
    return
  fi

  # Expand ~ if present in target
  target="${target/#\~/$HOME}"

  # Check if target exists or is a broken link
  if [ -e "$target" ] || [ -L "$target" ]; then
    # Check if it's already the correct symlink
    if [ -L "$target" ] && [ "$(readlink -f "$target")" == "$source" ]; then
      echo "Skipping $target (already correctly linked)"
      return
    fi

    # Generate unique backup name
    local filename=$(basename "$target")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/${filename}_${timestamp}"

    echo "Backing up $target -> $backup_path"
    mv "$target" "$backup_path"

    # Log the operation: ORIGINAL_PATH|BACKUP_PATH
    echo "$target|$backup_path" >>"$LOG_FILE"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")"

  echo "Linking $source -> $target"
  ln -s "$source" "$target"
}

# --- 1. Manual Mappings (Root level & Special cases) ---
link_config "$DOTS_DIR/.bashrc" "$HOME_DIR/.bashrc"
link_config "$DOTS_DIR/.zshrc" "$HOME_DIR/.zshrc"
link_config "$DOTS_DIR/.profile" "$HOME_DIR/.profile"
link_config "$DOTS_DIR/.gitconfig" "$HOME_DIR/.gitconfig"
link_config "$DOTS_DIR/scripts" "$HOME_DIR/scripts"

# --- 2. Autodetect remaining configs for ~/.config/ ---
# We loop through all files and directories in DOTS_DIR
for item in "$DOTS_DIR"/{*,.*}; do
  basename=$(basename "$item")
  
  # Skip if in ignore list
  skip=0
  for i in "${IGNORE[@]}"; do
    if [[ "$basename" == "$i" ]]; then
      skip=1
      break
    fi
  done
  
  if [[ $skip -eq 1 ]]; then
    continue
  fi

  # Skip if it doesn't exist (e.g. glob didn't match anything)
  if [ ! -e "$item" ]; then
    continue
  fi

  # Link everything else to ~/.config/
  link_config "$item" "$CONFIG_DIR/$basename"
done

echo "Dotfiles installation complete!"
