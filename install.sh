#!/usr/bin/env bash

# install.sh - Syncs dotfiles using yolk
# Usage: ./install.sh [yolk]

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

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
fi

# Determine if we should run yolk sync automatically
RUN_YOLK=false

if [ "$1" == "yolk" ]; then
    RUN_YOLK=true
else
    # Prompt the user
    read -p "Do you want to run 'yolk sync' now? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        RUN_YOLK=true
    fi
fi

cleanup_old_symlinks() {
    echo "Checking for old symlinks to clean up..."
    local targets=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.gitconfig"
        "$HOME/scripts"
        "$HOME/.config/bash"
        "$HOME/.config/zsh"
        "$HOME/.config/fish"
        "$HOME/.config/nushell"
        "$HOME/.config/starship.toml"
        "$HOME/.config/nvim"
        "$HOME/.config/hypr"
        "$HOME/.config/xdg-desktop-portal"
        "$HOME/.config/niri"
        "$HOME/.config/waybar"
        "$HOME/.config/rofi"
        "$HOME/.config/kitty"
        "$HOME/.config/tmux"
        "$HOME/.config/zellij"
        "$HOME/.config/fastfetch"
        "$HOME/.config/tealdeer"
    )

    for target in "${targets[@]}"; do
        if [ -e "$target" ] || [ -L "$target" ]; then
            # Check if it points to DOTS_DIR
            local real_path
            real_path=$(readlink -f "$target")
            
            if [[ "$real_path" == "$DOTS_DIR"* ]]; then
                echo "Removing old symlink: $target -> $real_path"
                rm "$target"
            else
                echo "Backing up existing file/dir: $target"
                local backup_name
                backup_name="$(basename "$target")_$(date +%s)"
                mv "$target" "$BACKUP_DIR/$backup_name"
            fi
        fi
    done
}

if [ "$RUN_YOLK" = true ]; then
    # Run cleanup of old symlinks to avoid overwriting source files
    cleanup_old_symlinks

    # Ensure yolk is installed
    if ! command -v yolk &> /dev/null; then
        if [ -f "$HOME/.cargo/bin/yolk" ]; then
            export PATH="$HOME/.cargo/bin:$PATH"
        elif command -v cargo &> /dev/null; then
            echo "Installing yolk via cargo..."
            cargo install yolk_dots
            export PATH="$HOME/.cargo/bin:$PATH"
        else
            echo "Error: 'yolk' and 'cargo' not found. Please run setup.sh first to install dependencies."
            exit 1
        fi
    fi

    echo "Syncing dotfiles with yolk..."
    # Run yolk sync
    if yolk sync; then
        echo "Dotfiles synced successfully!"
    else
        echo "Error: yolk sync failed."
        exit 1
    fi
else
    echo "Skipping yolk sync."
fi
