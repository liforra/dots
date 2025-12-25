# Dots

This is my personal dotfiles repository, managed with custom shell scripts for easy installation, updates, and uninstallation.

## 🚀 Installation

### Fresh System (Arch Linux or Ubuntu/Debian)

To set up these dotfiles on a new machine (or an existing one), clone the repository and run the setup script:

```bash
git clone https://github.com/liforra/dots.git ~/.dots
cd ~/.dots
./setup.sh
```

**`setup.sh` will:**

1. **Detect your OS** (Arch Linux or Ubuntu/Debian).
2. **Install dependencies** (git, starship, zoxide, fastfetch, eza, oh-my-bash, ble.sh).
    * *Note:* On Ubuntu, it automatically handles PPAs/repositories for `fastfetch` and `eza`.
3. **Run `install.sh`** to link all configuration files.

## 📂 Structure & Scripts

The repository contains several management scripts to keep your environment consistent and safe.

### `setup.sh`

* **Purpose:** The main entry point for a fresh install.
* **Actions:** Installs system packages and external tools (Starship, Oh My Bash, Ble.sh), then triggers `install.sh`.

### `install.sh`

* **Purpose:** Links configuration files from `~/.dots` to your home directory (`~` and `~/.config`).
* **Safeguards:**
  * **Backups:** If a config file already exists at the target location, it is moved to `~/.dots-bak/` with a timestamp.
  * **Logging:** Every backup operation is logged to `~/.dots-bak/restore_log.txt` for easy restoration.
  * **Idempotent:** Safe to run multiple times; it skips files that are already correctly linked.

### `uninstall.sh`

* **Purpose:** Removes the dotfiles from your system.
* **Actions:**
    1. Removes all symlinks created by `install.sh`.
    2. **Interactive Restoration:** Reads `~/.dots-bak/restore_log.txt` and asks if you want to restore your original files to their previous locations.
    3. Optionally deletes the backup directory.

### `update.sh`

* **Purpose:** Updates the repository and refreshes links.
* **Actions:** Runs `git pull` to get the latest changes, then runs `install.sh` to apply them.

## 📦 Managed Configurations

This repository manages configurations for:

### Shells & Terminals

* **Bash** (`.bashrc`, `.profile`, `.config/bash`)
* **Zsh** (`.zshrc`, `.config/zsh`)
* **Fish** (`.config/fish`)
* **Nushell** (`.config/nushell`)
* **Kitty** (`.config/kitty`)
* **Starship** (Prompt)

### Editors

* **Neovim** (`.config/nvim`)

### Window Managers & Desktop (Linux)

* **Hyprland** (`.config/hypr`)
* **Niri** (`.config/niri`)
* **Waybar** (`.config/waybar`)
* **Rofi** (`.config/rofi`)

### Tools & Utilities

* **Tmux** (`.config/tmux`)
* **Zellij** (`.config/zellij`)
* **Fastfetch** (`.config/fastfetch`)
* **Git** (`.gitconfig`)
* **Scripts** (`~/scripts`)

## 🛡️ Backup Details

When `install.sh` encounters an existing file that isn't a symlink to this repo:

1. It creates a directory: `~/.dots-bak`
2. It moves the existing file there (e.g., `.bashrc` -> `.dots-bak/.bashrc_20251225_120000`).
3. It logs the path mapping.

Running `uninstall.sh` allows you to automatically undo these moves and restore your system to its previous state.

