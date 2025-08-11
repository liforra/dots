 == *.sh || "$name" == *.nu || "$name" == *.py || \
          "$name" == *.bash || "$name" == *.zsh ]]; then
      continue
    fi
    if [[ ! -d "$entry" ]]; then
      continue
    fi
    target="$config_dir/$name"
    backup_and_remove "$target"
    ln -s "$entry" "$target"
    info "Linked $target → $entry"
  done
}

mkdir -p "$config_dir"
link_dir_to_config "$dots_dir"

if [[ -d "$dots_dir/.sys" ]]; then
  read -rp "Link .dots/.sys into ~/.config? (y/N): " sys_choice
  if [[ "${sys_choice,,}" == "y" ]]; then
    link_dir_to_config "$dots_dir/.sys"
  fi
fi

if [ -f "$dots_dir/bash/config.bash" ]; then
  backup_and_remove "$HOME/.bashrc"
  ln -s "$config_dir/bash/config.bash" "$HOME/.bashrc"
fi

if [ -f "$dots_dir/zsh/zsh.config" ]; then
  backup_and_remove "$HOME/.zshrc"
  ln -s "$config_dir/zsh/zsh.config" "$HOME/.zshrc"
fi

info "✅ Setup complete."#!/usr/bin/env bash
set -euo pipefail

timestamp=$(date +%Y%m%d-%H%M%S)
dots_dir=$(pwd)
config_dir="$HOME/.config"

info()  { printf '\e[1;34m[INFO]\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m[WARN]\e[0m %s\n' "$*"; }
error() { printf '\e[1;31m[ERROR]\e[0m %s\n' "$*"; exit 1; }

ver_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

backup_and_remove() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    info "Backing up $target → ${target}.bak-${timestamp}"
    mv "$target" "${target}.bak-${timestamp}"
  fi
}

# Detect package manager
if command -v pacman >/dev/null 2>&1; then
  PKG_MGR="pacman"
elif command -v apt >/dev/null 2>&1; then
  PKG_MGR="apt"
else
  error "No supported package manager found (pacman or apt)."
fi
info "Detected package manager: $PKG_MGR"

# Ask server or desktop
read -rp "Is this a server or desktop? (s/d) [d]: " sys_type
sys_type=${sys_type:-d}
sys_type=${sys_type,,}

common_pkgs=(git neovim nushell starship zoxide tmux fastfetch)
desktop_pkgs=(rofi waybar kitty)

if [[ "$sys_type" == "s" ]]; then
  pkgs=("${common_pkgs[@]}")
else
  pkgs=("${common_pkgs[@]}" "${desktop_pkgs[@]}")
fi

# Check installed packages
missing_pkgs=()
for p in "${pkgs[@]}"; do
  if ! command -v "$p" >/dev/null 2>&1; then
    missing_pkgs+=("$p")
  fi
done

if [ ${#missing_pkgs[@]} -eq 0 ]; then
  info "✅ All packages are already installed. Skipping installation."
else
  info "Missing packages: ${missing_pkgs[*]}"
  read -rp "Install missing packages? (y = yes, e = edit, n = no): " choice
  choice=${choice:-y}
  if [[ "$choice" == "e" ]]; then
    tmpfile=$(mktemp)
    printf "%s\n" "${missing_pkgs[@]}" > "$tmpfile"
    env ${EDITOR:-nano} "$tmpfile"
    mapfile -t missing_pkgs < "$tmpfile"
    rm -f "$tmpfile"
  elif [[ "$choice" == "n" ]]; then
    info "Skipping package installation."
    missing_pkgs=()
  fi
fi

# Install missing packages
if [ ${#missing_pkgs[@]} -gt 0 ]; then
  if [[ "$PKG_MGR" == "pacman" ]]; then
    sudo pacman -S --needed "${missing_pkgs[@]}"
  else
    sudo apt update -y
    for pkg in "${missing_pkgs[@]}"; do
      case "$pkg" in
        neovim)
          if command -v nvim >/dev/null 2>&1; then
            ver=$(nvim --version | head -n1 | awk '{print $2}')
            if ! ver_ge "$ver" "0.8.0"; then
              warn "Upgrading Neovim via PPA..."
              sudo apt install -y software-properties-common
              sudo add-apt-repository -y ppa:neovim-ppa/unstable
              sudo apt update -y
              sudo apt install -y neovim
            fi
          else
            sudo apt install -y software-properties-common
            sudo add-apt-repository -y ppa:neovim-ppa/unstable
            sudo apt update -y
            sudo apt install -y neovim
          fi
          ;;
        nushell)
          url=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest \
            | grep "browser_download_url" | grep "linux-x86_64\.deb" | cut -d '"' -f 4 | head -n1)
          tmp=$(mktemp)
          curl -L "$url" -o "$tmp"
          sudo dpkg -i "$tmp" || sudo apt -f install -y
          rm -f "$tmp"
          ;;
        starship)
          curl -sS https://starship.rs/install.sh | sh -s -- -y
          ;;
        fastfetch)
          url=$(curl -s https://api.github.com/repos/LinusDierheimer/fastfetch/releases/latest \
            | grep "browser_download_url" | grep "amd64\.deb" | cut -d '"' -f 4 | head -n1)
          tmp=$(mktemp)
          curl -L "$url" -o "$tmp"
          sudo dpkg -i "$tmp" || sudo apt -f install -y
          rm -f "$tmp"
          ;;
        *)
          sudo apt install -y "$pkg"
          ;;
      esac
    done
  fi
fi

# Symlink function
link_dir_to_config() {
  local source_dir="$1"
  info "Linking from $source_dir → $config_dir"
  shopt -s nullglob dotglob
  for entry in "$source_dir"/*; do
    name=$(basename "$entry")
    case "$name" in
      LICENSE|.git|.gitignore|setup.sh) continue ;;
    esac
    if [[ "$name" == *".nosym."* ]]; then
      continue
    fi
    if [[ "$name"
