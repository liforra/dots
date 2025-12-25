#!/bin/bash

DOTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dots-bak"
LOG_FILE="$BACKUP_DIR/restore_log.txt"

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Created backup directory: $BACKUP_DIR"
fi

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

echo "Setting up dotfiles from $DOTS_DIR..."
echo "Backups will be stored in $BACKUP_DIR"

link_config() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        echo "Warning: Source $source does not exist. Skipping."
        return
    fi

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
        echo "$target|$backup_path" >> "$LOG_FILE"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    echo "Linking $source -> $target"
    ln -s "$source" "$target"
}

# --- Root level files ---
link_config "$DOTS_DIR/.bashrc" "$HOME_DIR/.bashrc"
link_config "$DOTS_DIR/.zshrc" "$HOME_DIR/.zshrc"
link_config "$DOTS_DIR/.profile" "$HOME_DIR/.profile"
link_config "$DOTS_DIR/.gitconfig" "$HOME_DIR/.gitconfig"

# --- Scripts Directory (Mapped to ~/scripts) ---
link_config "$DOTS_DIR/scripts" "$HOME_DIR/scripts"

# --- Config Directories (Mapped to ~/.config/...) ---
link_config "$DOTS_DIR/bash" "$CONFIG_DIR/bash"
link_config "$DOTS_DIR/zsh" "$CONFIG_DIR/zsh"
link_config "$DOTS_DIR/fish" "$CONFIG_DIR/fish"
link_config "$DOTS_DIR/nushell" "$CONFIG_DIR/nushell"
link_config "$DOTS_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
link_config "$DOTS_DIR/nvim" "$CONFIG_DIR/nvim"
link_config "$DOTS_DIR/hypr" "$CONFIG_DIR/hypr"
link_config "$DOTS_DIR/niri" "$CONFIG_DIR/niri"
link_config "$DOTS_DIR/waybar" "$CONFIG_DIR/waybar"
link_config "$DOTS_DIR/rofi" "$CONFIG_DIR/rofi"
link_config "$DOTS_DIR/kitty" "$CONFIG_DIR/kitty"
link_config "$DOTS_DIR/tmux" "$CONFIG_DIR/tmux"
link_config "$DOTS_DIR/zellij" "$CONFIG_DIR/zellij"
link_config "$DOTS_DIR/fastfetch" "$CONFIG_DIR/fastfetch"

echo "Dotfiles installation complete!"
