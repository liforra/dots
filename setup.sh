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

link_dir_to_config() {
  local source_dir="$1"
  echo "🔗 Linking from $source_dir to $config_dir"
  shopt -s nullglob dotglob
  for entry in "$source_dir"/*; do
    name=$(basename "$entry")

    # Skip unwanted entries
    case "$name" in
    LICENCE | .git | .gitignore | setup.sh) continue ;;
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
}

# 1. Ensure ~/.config exists
mkdir -p "$config_dir"

# 2. Link from main .dots to ~/.config
link_dir_to_config "$dots_dir"

# 3. Ask user if they want to link .dots/.sys
if [[ -d "$dots_dir/.sys" ]]; then
  read -rp "Do you want to link .dots/.sys into ~/.config? (y/N): " sys_choice
  if [[ "$sys_choice" =~ ^[Yy]$ ]]; then
    link_dir_to_config "$dots_dir/.sys"
  else
    echo "Skipping .sys linking."
  fi
fi

# 4. Special handling for bashrc
if [ -f "$dots_dir/bash/config.bash" ]; then
  backup_and_remove "$HOME/.bashrc"
  ln -s "$config_dir/bash/config.bash" "$HOME/.bashrc"
  echo "Linked ~/.bashrc → $config_dir/bash/config.bash"
fi

# 5. Special handling for zshrc
if [ -f "$dots_dir/zsh/zsh.config" ]; then
  backup_and_remove "$HOME/.zshrc"
  ln -s "$config_dir/zsh/zsh.config" "$HOME/.zshrc"
  echo "Linked ~/.zshrc → $config_dir/zsh/zsh.config"
fi

# 6. Link from .dots/etc to /etc (only if root)
if [[ -d "$dots_dir/etc" ]]; then
  if [[ $EUID -eq 0 ]]; then
    echo "⚙️ Linking from $dots_dir/etc to /etc"
    chown -R root:root "$dots_dir/etc"
    shopt -s nullglob dotglob
    for etc_entry in "$dots_dir/etc"/*; do
      etc_name=$(basename "$etc_entry")
      target="/etc/$etc_name"

      if [[ -d "$etc_entry" ]]; then
        if [[ -f "$etc_entry/.lnkfile" ]]; then
          echo "📄 Linking files inside $etc_entry individually..."
          mkdir -p "$target"
          for file in "$etc_entry"/*; do
            [[ "$(basename "$file")" == ".lnkfile" ]] && continue
            backup_and_remove "$target/$(basename "$file")"
            ln -s "$file" "$target/$(basename "$file")"
            echo "Linked $target/$(basename "$file") → $file"
          done
        else
          backup_and_remove "$target"
          ln -s "$etc_entry" "$target"
          echo "Linked $target → $etc_entry"
        fi
      else
        backup_and_remove "$target"
        ln -s "$etc_entry" "$target"
        echo "Linked $target → $etc_entry"
      fi
    done
  else
    echo "⚠️ Skipping /etc linking — not running as root."
  fi
fi

echo "✅ All symlinks created successfully."
