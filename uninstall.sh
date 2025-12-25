#!/bin/bash

HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dots-bak"
LOG_FILE="$BACKUP_DIR/restore_log.txt"

echo "Uninstalling dotfiles (removing symlinks)..."

unlink_config() {
    local target="$1"
    if [ -L "$target" ]; then
        echo "Removing symlink $target"
        rm "$target"
    fi
}

# 1. Remove Symlinks
# Root level
unlink_config "$HOME_DIR/.bashrc"
unlink_config "$HOME_DIR/.zshrc"
unlink_config "$HOME_DIR/.profile"
unlink_config "$HOME_DIR/.gitconfig"

# Scripts
unlink_config "$HOME_DIR/scripts"

# Configs
unlink_config "$CONFIG_DIR/bash"
unlink_config "$CONFIG_DIR/zsh"
unlink_config "$CONFIG_DIR/fish"
unlink_config "$CONFIG_DIR/nushell"
unlink_config "$CONFIG_DIR/starship.toml"
unlink_config "$CONFIG_DIR/nvim"
unlink_config "$CONFIG_DIR/hypr"
unlink_config "$CONFIG_DIR/niri"
unlink_config "$CONFIG_DIR/waybar"
unlink_config "$CONFIG_DIR/rofi"
unlink_config "$CONFIG_DIR/kitty"
unlink_config "$CONFIG_DIR/tmux"
unlink_config "$CONFIG_DIR/zellij"
unlink_config "$CONFIG_DIR/fastfetch"

echo "Symlinks removed."

# 2. Ask to Restore Backups
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "Found backup history in $LOG_FILE."
    read -p "Do you want to undo changes and restore files from $BACKUP_DIR? (This will overwrite current files at target locations) [y/N] " response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Restoring backups..."
        
        # Read log file line by line
        # Format: TARGET|BACKUP_PATH
        while IFS='|' read -r target backup_path || [ -n "$target" ]; do
            # Skip empty lines
            [ -z "$target" ] && continue
            
            if [ -e "$backup_path" ]; then
                # Ensure parent dir exists
                mkdir -p "$(dirname "$target")"
                
                echo "Restoring $backup_path -> $target"
                mv "$backup_path" "$target"
            else
                echo "Warning: Backup file $backup_path not found. Skipping."
            fi
        done < "$LOG_FILE"
        
        echo "Restoration complete."
        
        read -p "Do you want to delete the backup directory $BACKUP_DIR? [y/N] " del_response
        if [[ "$del_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "$BACKUP_DIR"
            echo "Backup directory deleted."
        fi
    else
        echo "Backups were kept in $BACKUP_DIR."
    fi
else
    echo "No backup log found at $LOG_FILE. Nothing to restore."
fi

echo "Uninstallation finished."
