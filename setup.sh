#!/usr/bin/env bash
set -euo pipefail

timestamp=$(date +%Y%m%d-%H%M%S)
dots_dir=$(pwd) # current dir is your ~/.dots
config_dir="$HOME/.config"

backup_and_remove() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Backing up $target → ${target}.bak-${timestamp}"
        mv "$target" "${target}.bak-${timestamp}"
    fi
}

# 1. Ensure ~/.config exists
mkdir -p "$config_dir"

# 2. Symlink all directories from ~/.dots to ~/.config, skipping excluded ones
shopt -s nullglob dotglob
for entry in "$dots_dir"/*; do
    name=$(basename "$entry")

    # Skip unwanted entries
    case "$name" in
        LICENCE|.git|.gitignore|setup.sh) continue ;;
    esac
    if [[ "$name" == *".nosym."* ]]; then
        continue
    fi
    # Skip root-level scripts/config files
    if [[ "$name" == *.sh || "$name" == *.nu || "$name" == *.py || "$name" == *.bash || "$name" == *.zsh ]]; then
        continue
    fi
    # Only process directories
    if [[ ! -d "$entry" ]]; then
        continue
    fi

    target="$config_dir/$name"
    backup_and_remove "$target"
    ln -s "$entry" "$target"
    echo "Linked $target → $entry"
done

# 3. Special handling for bashrc
if [ -f "$dots_dir/bash/config.bash" ]; then
    backup_and_remove "$HOME/.bashrc"
    ln -s "$config_dir/bash/config.bash" "$HOME/.bashrc"
    echo "Linked ~/.bashrc → $config_dir/bash/config.bash"
fi

# 4. Special handling for zshrc
if [ -f "$dots_dir/zsh/zsh.config" ]; then
    backup_and_remove "$HOME/.zshrc"
    ln -s "$config_dir/zsh/zsh.config" "$HOME/.zshrc"
    echo "Linked ~/.zshrc → $config_dir/zsh/zsh.config"
fi

echo "✅ All symlinks created successfully."
