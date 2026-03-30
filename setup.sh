#!/usr/bin/env bash

# setup.sh - Installs dependencies and sets up dotfiles
# Supports Arch, Debian/Ubuntu, Fedora, Alpine, NixOS, Bedrock, Termux

set -e

DOTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- 1. Detect OS ---
if [ -n "$TERMUX_VERSION" ] || [[ "$(uname -o 2>/dev/null)" == "Android" ]]; then
    OS="Termux"
    ID="termux"
elif [ -f /etc/bedrock-release ] || command -v brl &>/dev/null; then
    OS="Bedrock Linux"
    ID="bedrock"
    # Try to detect a suitable stratum for package management if needed, 
    # but for now we'll rely on available commands or user prompt.
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    # Normalize ID
    if [[ "$ID" == "nixos" ]]; then
        ID="nixos"
    elif [[ "$ID" == "alpine" ]]; then
        ID="alpine"
    elif [[ "$ID" == "fedora" ]]; then
        ID="fedora"
    fi
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS ($ID)"

# --- 2. Define Install Commands ---
install_package() {
    PACKAGE=$1
    echo "Installing $PACKAGE..."
    
    case "$ID" in
        termux)
            pkg install -y "$PACKAGE"
            ;;
        arch)
            sudo pacman -S --noconfirm --needed "$PACKAGE"
            ;;
        ubuntu|debian)
            sudo apt-get update -y
            sudo apt-get install -y "$PACKAGE"
            ;;
        fedora)
            sudo dnf install -y "$PACKAGE"
            ;;
        alpine)
            sudo apk add "$PACKAGE"
            ;;
        nixos)
            # NixOS is declarative. We can try nix-env but it's not ideal.
            if command -v nix-env &>/dev/null; then
                nix-env -iA "nixos.$PACKAGE" || nix-env -iA "nixpkgs.$PACKAGE" || echo "Could not install $PACKAGE via nix-env."
            else
                echo "NixOS detected but nix-env not found. Skipping $PACKAGE."
            fi
            ;;
        bedrock)
            # Bedrock is complex. Try to use apt or pacman if available via strat.
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "$PACKAGE"
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm --needed "$PACKAGE"
            else
                echo "Bedrock Linux: No known package manager found for $PACKAGE. Install manually."
            fi
            ;;
        *)
            if [[ "$ID_LIKE" == *"arch"* ]]; then
                sudo pacman -S --noconfirm --needed "$PACKAGE"
            elif [[ "$ID_LIKE" == *"debian"* ]]; then
                 sudo apt-get update -y
                 sudo apt-get install -y "$PACKAGE"
            else
                echo "Unsupported OS for automatic package installation. Please install '$PACKAGE' manually."
            fi
            ;;
    esac
}

# --- 3. Prompt User ---
MODE=""
if [ -z "$1" ]; then
    echo "Is this a Server or a PC?"
    select type in "Server" "PC"; do
        case $type in
            Server) MODE="server"; break;;
            PC) MODE="pc"; break;;
        esac
    done
else
    MODE="$1" # Allow passing mode as argument
fi

# --- 4. Install Dependencies ---
read -p "Do you want to install core dependencies (git, starship, zoxide, fastfetch, eza, ble.sh)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    
    # Core tools
    install_package git
    install_package curl
    install_package wget

    # xz-utils
    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        install_package xz
    else
        install_package xz-utils
    fi

    # Starship
    if [[ "$ID" == "termux" ]]; then
        install_package starship
    else
        if ! command -v starship &> /dev/null; then
            echo "Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        else
            echo "Starship already installed."
        fi
    fi

    # Zoxide, Fastfetch, Eza (Distro specific logic)
    # Simplified for brevity, relying on install_package mostly
    # For Ubuntu PPA logic, we keep it if ID is ubuntu/debian
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
         install_package zoxide
         
         # Fastfetch PPA
         if ! command -v fastfetch &> /dev/null; then
            if ! grep -q "^deb .*ppa.launchpadcontent.net/zhangsongcui3371/fastfetch" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
                sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
                sudo apt-get update -y
            fi
            install_package fastfetch
         fi

         # Eza repo
         if ! command -v eza &> /dev/null; then
             sudo mkdir -p /etc/apt/keyrings
             wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes
             echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de/ stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
             sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
             sudo apt-get update -y
             install_package eza
         fi
    else
        # Arch, Fedora, Alpine, etc. usually have these or we fail gracefully
        install_package zoxide
        install_package fastfetch
        install_package eza
    fi

    # Oh My Bash
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        echo "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
    fi

    # Ble.sh
    if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "Installing Ble.sh..."
        curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
        mkdir -p "$HOME/.local/share"
        bash ble-nightly/ble.sh --install "$HOME/.local/share"
        rm -rf ble-nightly
    fi
fi

# --- 5. Mode Specific Installs ---

if [ "$MODE" == "server" ]; then
    echo "--- Server Configuration ---"
    read -p "Install Docker? [y/N] " install_docker
    if [[ "$install_docker" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_package docker
        # Docker compose plugin often needed
        install_package docker-compose-plugin || install_package docker-compose
    fi

    read -p "Install Podman? [y/N] " install_podman
    if [[ "$install_podman" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_package podman
    fi

elif [ "$MODE" == "pc" ]; then
    echo "--- PC Configuration ---"
    # Check for configured DEs in dotfiles
    if [ -d "$DOTS_DIR/hypr" ]; then
        read -p "Found Hyprland configuration. Install Hyprland? [y/N] " install_hypr
        if [[ "$install_hypr" =~ ^([yY][eE][sS]|[yY])$ ]]; then
             install_package hyprland
             install_package waybar
             install_package rofi
             install_package kitty
             install_package xdg-desktop-portal-hyprland
        fi
    fi

    if [ -d "$DOTS_DIR/niri" ]; then
        read -p "Found Niri configuration. Install Niri? [y/N] " install_niri
        if [[ "$install_niri" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            install_package niri
            # Common tools likely shared but good to ensure
            install_package waybar
            install_package fuzzel # Niri often uses fuzzel, but config says rofi?
            install_package xdg-desktop-portal-gnome # or similar for niri
        fi
    fi
fi

# --- 6. Run Dotfiles Linker ---
echo "Linking dotfiles for current user..."
"$DOTS_DIR/install.sh"

# --- 7. Extended Installation (Root/Other Users) ---
if [[ "$ID" == "termux" ]]; then
    echo "Skipping multi-user/root setup on Termux."
else
    read -p "Do you want to install dotfiles for root as well? [y/N/e] (e = specify users): " extra_response

    TARGET_USERS=()

    if [[ "$extra_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        TARGET_USERS+=("root")
    elif [[ "$extra_response" =~ ^[eE]$ ]]; then
        read -p "Enter usernames separated by commas (e.g. root, bob): " user_input
        IFS=',' read -ra RAW_USERS <<< "$user_input"
        for u in "${RAW_USERS[@]}"; do
            TARGET_USERS+=("$u")
        done
    fi

    if [ ${#TARGET_USERS[@]} -gt 0 ]; then
        echo "Adjusting permissions..."
        chmod o+x "$HOME"
        chmod -R o+rX "$DOTS_DIR"

        for target in "${TARGET_USERS[@]}"; do
            target=$(echo "$target" | xargs)
            if [ -z "$target" ]; then continue; fi
            if id "$target" &>/dev/null; then
                echo "Installing dotfiles for user: $target"
                if [ "$target" == "root" ]; then
                    sudo "$DOTS_DIR/install.sh"
                else
                    sudo -u "$target" "$DOTS_DIR/install.sh"
                fi
            fi
        done
    fi
fi

echo "Setup complete! Please restart your shell."
