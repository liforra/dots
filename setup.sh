#!/bin/bash

# setup.sh - Installs dependencies and sets up dotfiles
# Supports Arch Linux and Ubuntu/Debian

set -e

DOTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# --- 1. Detect OS ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    ID=$ID
    VERSION_CODENAME=$VERSION_CODENAME
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS ($ID)"

# --- 2. Define Install Commands ---
install_package() {
    PACKAGE=$1
    echo "Installing $PACKAGE..."
    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        sudo pacman -S --noconfirm --needed "$PACKAGE"
    elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        sudo apt-get update -y
        sudo apt-get install -y "$PACKAGE"
    else
        echo "Unsupported OS for automatic package installation. Please install '$PACKAGE' manually."
    fi
}

# --- 3. Prompt User ---
read -p "Do you want to install dependencies (git, starship, zoxide, fastfetch, eza, ble.sh)? [y/N] " response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Skipping dependency installation."
else
    # --- 4. Install Dependencies ---
    
    # Core tools
    install_package git
    install_package curl
    install_package wget

    # Starship (Universal installer)
    if ! command -v starship &> /dev/null; then
        echo "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo "Starship already installed."
    fi

    # Distro-specific packages
    if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
        install_package zoxide
        install_package fastfetch
        install_package eza
    elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        # Ubuntu often has old repos. zoxide is usually available.
        install_package zoxide
        
        # fastfetch
        if ! command -v fastfetch &> /dev/null; then
            echo "Attempting to install fastfetch..."
            # Check if PPA already exists
            if ! grep -q "^deb .*ppa.launchpadcontent.net/zhangsongcui3371/fastfetch" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
                echo "Adding fastfetch PPA..."
                sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
                sudo apt-get update -y
            else
                echo "Fastfetch PPA already exists."
            fi
            install_package fastfetch || echo "Fastfetch install failed. You may need to install it manually."
        else
            echo "Fastfetch already installed."
        fi

        # eza
        if ! command -v eza &> /dev/null; then
             echo "Attempting to install eza..."
             # Check if eza repo file already exists
             if [ ! -f /etc/apt/sources.list.d/gierens.list ]; then
                echo "Adding eza repository..."
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de/ stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                sudo apt-get update -y
             else
                echo "Eza repository already exists."
             fi
             install_package eza || echo "Eza install failed."
        else
            echo "Eza already installed."
        fi
    fi

    # Oh My Bash
    if [ ! -d "$HOME/.oh-my-bash" ]; then
        echo "Installing Oh My Bash..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
        # The installer might overwrite .bashrc, we will restore our link later with install.sh
    else
        echo "Oh My Bash already installed."
    fi

    # Ble.sh
    if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "Installing Ble.sh..."
        curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
        mkdir -p "$HOME/.local/share"
        bash ble-nightly/ble.sh --install "$HOME/.local/share"
        rm -rf ble-nightly
    else
        echo "Ble.sh already installed."
    fi
fi

# --- 5. Run Dotfiles Linker ---
echo "Linking dotfiles for current user..."
"$DOTS_DIR/install.sh"

# --- 6. Extended Installation (Root/Other Users) ---
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
    echo "Adjusting permissions for shared access (chmod o+x HOME, chmod -R o+rX DOTS_DIR)..."
    # Ensure parent dir is traversable so others can reach the symlink targets
    chmod o+x "$HOME"
    # Ensure the actual files are readable
    chmod -R o+rX "$DOTS_DIR"

    for target in "${TARGET_USERS[@]}"; do
        # Trim whitespace
        target=$(echo "$target" | xargs)
        
        if [ -z "$target" ]; then continue; fi

        if id "$target" &>/dev/null; then
            echo "Installing dotfiles for user: $target"
            if [ "$target" == "root" ]; then
                # Run install script as root
                sudo "$DOTS_DIR/install.sh"
            else
                # Run install script as target user
                sudo -u "$target" "$DOTS_DIR/install.sh"
            fi
        else
            echo "Warning: User '$target' does not exist. Skipping."
        fi
    done
fi

echo "Setup complete! Please restart your shell."