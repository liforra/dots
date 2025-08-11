#!/usr/bin/env bash
set -u # stop only on unset variables; don't exit on individual errors

timestamp=$(date +%Y%m%d-%H%M%S)
dots_dir=$(pwd)
config_dir="$HOME/.config"

info() { printf '\e[1;34m[INFO]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[WARN]\e[0m %s\n' "$*"; }
error() { printf '\e[1;31m[ERROR]\e[0m %s\n' "$*"; }

ver_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

backup_and_remove() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    info "Backing up $target → ${target}.bak-${timestamp}"
    mv "$target" "${target}.bak-${timestamp}" ||
      warn "Failed to backup $target"
  fi
}

wait_for_apt_lock() {
  local locks=(
    "/var/lib/apt/lists/lock"
    "/var/lib/dpkg/lock-frontend"
    "/var/lib/dpkg/lock"
  )
  for lock in "${locks[@]}"; do
    while sudo fuser "$lock" >/dev/null 2>&1; do
      echo -ne "\r[WAIT] apt/dpkg is locked by another process. Waiting..."
      sleep 2
    done
  done
  echo -e "\r[INFO] apt/dpkg lock released. Continuing...       "
}

wait_for_pacman_lock() {
  local lock="/var/lib/pacman/db.lck"
  while [ -e "$lock" ]; do
    echo -ne "\r[WAIT] pacman is locked by another process. Waiting..."
    sleep 2
  done
  echo -e "\r[INFO] pacman lock released. Continuing...       "
}

safe_apt_update() {
  wait_for_apt_lock
  sudo apt update -y --allow-releaseinfo-change ||
    warn "apt update failed/returned non-zero, continuing..."
}

# map uname architecture to the naming used by release assets
arch_maps() {
  local uname_m
  uname_m=$(uname -m)
  case "$uname_m" in
  x86_64 | amd64)
    echo "FF=amd64 NU=x86_64"
    ;;
  aarch64 | arm64)
    echo "FF=aarch64 NU=aarch64"
    ;;
  armv7l | armv7)
    echo "FF=armv7 NU=armv7"
    ;;
  loongarch64)
    echo "FF=loongarch64 NU=loongarch64"
    ;;
  riscv64)
    echo "FF=riscv64 NU=riscv64gc"
    ;;
  *)
    echo "FF=$uname_m NU=$uname_m"
    ;;
  esac
}

# map package name -> binary name (used to check presence)
pkg_bin() {
  case "$1" in
  neovim) echo "nvim" ;;
  nushell) echo "nu" ;;
  starship) echo "starship" ;;
  fastfetch) echo "fastfetch" ;;
  zoxide) echo "zoxide" ;;
  tmux) echo "tmux" ;;
  git) echo "git" ;;
  rofi) echo "rofi" ;;
  waybar) echo "waybar" ;;
  kitty) echo "kitty" ;;
  rclone) echo "rclone" ;;
  obs-studio) echo "obs" ;;
  obsidian) echo "obsidian" ;;
  *) echo "$1" ;;
  esac
}

# Install Nushell (best-effort: apt -> Fury apt -> snap -> tarball)
install_nushell() {
  info "Installing nushell (best-effort)..."

  if command -v nu >/dev/null 2>&1; then
    info "nushell already installed"
    return
  fi

  if [[ "$PKG_MGR" == "pacman" ]]; then
    sudo pacman -S --needed nushell || warn "pacman install nushell failed"
    return
  fi

  # apt world:
  if apt-cache show nushell >/dev/null 2>&1; then
    safe_apt_update
    sudo apt install -y nushell || warn "apt install nushell failed"
    if command -v nu >/dev/null 2>&1; then
      info "nushell installed via apt"
      return
    fi
  fi

  # Try the official Fury apt repo
  info "Trying official nushell apt repo (apt.fury.io)..."
  sudo apt install -y gnupg curl ca-certificates >/dev/null 2>&1 ||
    warn "failed to ensure gnupg/curl"
  curl -fsSL https://apt.fury.io/nushell/gpg.key |
    sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg ||
    warn "Failed to add Fury GPG key"
  echo "deb https://apt.fury.io/nushell/ /" |
    sudo tee /etc/apt/sources.list.d/fury-nushell.list >/dev/null ||
    warn "Failed to add Fury apt repo"
  safe_apt_update
  sudo apt install -y nushell || warn "apt (fury) install nushell failed"
  if command -v nu >/dev/null 2>&1; then
    info "nushell installed via apt.fury"
    return
  fi

  # Snap fallback
  if command -v snap >/dev/null 2>&1; then
    sudo snap install nushell --classic ||
      warn "snap install nushell failed"
    if command -v nu >/dev/null 2>&1; then
      info "nushell installed via snap"
      return
    fi
  fi

  # Tarball fallback from GitHub releases
  info "Falling back to Nushell GitHub tarball install..."
  install_nushell_from_tar || warn "nushell tarball install failed"
}

install_nushell_from_tar() {
  local ARCH_PAIR GH_NU url tmpdir nu_path
  ARCH_PAIR=$(arch_maps) || ARCH_PAIR=""
  # extract mapped nushell arch
  GH_NU=$(echo "$ARCH_PAIR" | awk -F' ' '{for(i=1;i<=NF;i++){if($i ~ /^NU=/){split($i,a,"=");print a[2]}}}')
  GH_NU=${GH_NU:-x86_64}

  # prefer GNU builds, then musl, then any tar.gz with arch
  url=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest |
    grep "browser_download_url" |
    grep "${GH_NU}-unknown-linux-gnu\.tar\.gz" |
    cut -d '"' -f 4 | head -n1)

  if [[ -z "$url" ]]; then
    url=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest |
      grep "browser_download_url" |
      grep "${GH_NU}-unknown-linux-musl\.tar\.gz" |
      cut -d '"' -f 4 | head -n1)
  fi

  if [[ -z "$url" ]]; then
    url=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest |
      grep "browser_download_url" |
      grep "${GH_NU}" | grep '\.tar\.gz' |
      cut -d '"' -f 4 | head -n1)
  fi

  info "[DEBUG] Nushell URL: $url"
  if [[ -z "$url" ]]; then
    warn "No Nushell release tarball found for arch $GH_NU"
    return 1
  fi

  tmpdir=$(mktemp -d)
  curl -L "$url" -o "$tmpdir/nu.tar.gz" ||
    {
      warn "Failed to download $url"
      rm -rf "$tmpdir"
      return 1
    }

  tar -xzf "$tmpdir/nu.tar.gz" -C "$tmpdir" ||
    {
      warn "Failed to extract Nushell tarball"
      rm -rf "$tmpdir"
      return 1
    }

  # find an executable named 'nu'
  nu_path=$(find "$tmpdir" -type f -name nu -perm /111 | head -n1 || true)
  if [[ -z "$nu_path" ]]; then
    # sometimes binary may not be executable in archive; look anyway
    nu_path=$(find "$tmpdir" -type f -name nu | head -n1 || true)
  fi
  if [[ -z "$nu_path" ]]; then
    warn "No 'nu' binary found inside Nushell archive"
    rm -rf "$tmpdir"
    return 1
  fi

  sudo install -m 755 "$nu_path" /usr/local/bin/nu ||
    warn "Failed to install nushell binary to /usr/local/bin"
  rm -rf "$tmpdir"
  return 0
}

# Install Fastfetch: prefer package, then .deb, then tarball
install_fastfetch() {
  info "Installing fastfetch (best-effort)..."
  if command -v fastfetch >/dev/null 2>&1; then
    info "fastfetch already installed"
    return
  fi

  if [[ "$PKG_MGR" == "pacman" ]]; then
    sudo pacman -S --needed fastfetch || warn "pacman install fastfetch failed"
    return
  fi

  # apt path: try apt first
  if apt-cache show fastfetch >/dev/null 2>&1; then
    safe_apt_update
    sudo apt install -y fastfetch || warn "apt install fastfetch failed"
    if command -v fastfetch >/dev/null 2>&1; then
      info "fastfetch installed via apt"
      return
    fi
  fi

  # GitHub asset download
  local ARCH_PAIR GH_FF url tmp
  ARCH_PAIR=$(arch_maps) || ARCH_PAIR=""
  GH_FF=$(echo "$ARCH_PAIR" | awk -F' ' '{for(i=1;i<=NF;i++){if($i ~ /^FF=/){split($i,a,"=");print a[2]}}}')
  GH_FF=${GH_FF:-amd64}

  # Try .deb first (common for amd64)
  url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest |
    grep "browser_download_url" | grep "linux-${GH_FF}\.deb" |
    cut -d '"' -f 4 | head -n1)

  info "[DEBUG] Fastfetch URL (.deb preferred): $url"
  if [[ -n "$url" ]]; then
    tmp=$(mktemp)
    curl -L "$url" -o "$tmp" || {
      warn "Failed to download fastfetch .deb"
      rm -f "$tmp"
      return 1
    }
    sudo dpkg -i "$tmp" || (wait_for_apt_lock && sudo apt -f install -y || warn "dpkg install fastfetch failed")
    rm -f "$tmp"
    return
  fi

  # else try tar.gz
  url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest |
    grep "browser_download_url" | grep "linux-${GH_FF}\.tar\.gz" |
    cut -d '"' -f 4 | head -n1)
  info "[DEBUG] Fastfetch URL (tar.gz fallback): $url"
  if [[ -z "$url" ]]; then
    warn "No fastfetch asset found for arch $GH_FF"
    return 1
  fi

  tmpdir=$(mktemp -d)
  curl -L "$url" -o "$tmpdir/ff.tar.gz" || {
    warn "Failed to download fastfetch tar"
    rm -rf "$tmpdir"
    return 1
  }
  tar -xzf "$tmpdir/ff.tar.gz" -C "$tmpdir" || {
    warn "Failed to extract fastfetch tar"
    rm -rf "$tmpdir"
    return 1
  }

  ff_bin=$(find "$tmpdir" -type f -name fastfetch -perm /111 | head -n1 || true)
  if [[ -z "$ff_bin" ]]; then
    ff_bin=$(find "$tmpdir" -type f -name fastfetch | head -n1 || true)
  fi
  if [[ -z "$ff_bin" ]]; then
    warn "fastfetch binary not found in archive"
    rm -rf "$tmpdir"
    return 1
  fi
  sudo install -m 755 "$ff_bin" /usr/local/bin/fastfetch ||
    warn "Failed to install fastfetch binary"
  rm -rf "$tmpdir"
  return 0
}

# ====== main flow ======

# detect package manager
if command -v pacman >/dev/null 2>&1; then
  PKG_MGR="pacman"
elif command -v apt >/dev/null 2>&1; then
  PKG_MGR="apt"
else
  error "No supported package manager found (pacman or apt)."
fi
info "Detected package manager: $PKG_MGR"

# interactive: server or desktop
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

# determine missing by checking binaries
missing_pkgs=()
for pkg in "${pkgs[@]}"; do
  binname=$(pkg_bin "$pkg")
  if ! command -v "$binname" >/dev/null 2>&1; then
    missing_pkgs+=("$pkg")
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
    printf "%s\n" "${missing_pkgs[@]}" >"$tmpfile"
    env ${EDITOR:-nano} "$tmpfile"
    mapfile -t missing_pkgs <"$tmpfile"
    rm -f "$tmpfile"
  elif [[ "$choice" == "n" ]]; then
    info "Skipping package installation."
    missing_pkgs=()
  fi
fi

if [ ${#missing_pkgs[@]} -gt 0 ]; then
  if [[ "$PKG_MGR" == "pacman" ]]; then
    wait_for_pacman_lock
    sudo pacman -S --needed "${missing_pkgs[@]}" || warn "pacman install failed"
  else
    safe_apt_update
    for pkg in "${missing_pkgs[@]}"; do
      case "$pkg" in
      neovim)
        if command -v nvim >/dev/null 2>&1; then
          nver=$(nvim --version | head -n1 | awk '{print $2}')
          if ! ver_ge "$nver" "0.8.0"; then
            warn "Upgrading Neovim via PPA..."
            sudo apt install -y software-properties-common || warn "apt: software-properties-common failed"
            sudo add-apt-repository -y ppa:neovim-ppa/unstable || warn "add-apt-repository failed"
            safe_apt_update
            sudo apt install -y neovim || warn "apt install neovim failed"
          fi
        else
          sudo apt install -y software-properties-common || warn "apt: software-properties-common failed"
          sudo add-apt-repository -y ppa:neovim-ppa/unstable || warn "add-apt-repository failed"
          safe_apt_update
          sudo apt install -y neovim || warn "apt install neovim failed"
        fi
        ;;
      nushell)
        install_nushell
        ;;
      starship)
        curl -sS https://starship.rs/install.sh | sh ||
          warn "starship install script failed"
        ;;
      fastfetch)
        install_fastfetch
        ;;
      *)
        sudo apt install -y "$pkg" || warn "Failed to apt install $pkg"
        ;;
      esac
    done
  fi
fi

# Symlink function (same filtering rules)
link_dir_to_config() {
  local source_dir="$1"
  info "Linking from $source_dir → $config_dir"
  shopt -s nullglob dotglob
  for entry in "$source_dir"/*; do
    name=$(basename "$entry")
    case "$name" in
    LICENSE | .git | .gitignore | setup.sh) continue ;;
    esac
    if [[ "$name" == *".nosym."* ]]; then continue; fi
    if [[ "$name" == *.sh || "$name" == *.nu || "$name" == *.py ||
      "$name" == *.bash || "$name" == *.zsh ]]; then
      continue
    fi
    if [[ ! -d "$entry" ]]; then continue; fi
    target="$config_dir/$name"
    backup_and_remove "$target"
    ln -s "$entry" "$target" || warn "Failed to create symlink $target"
    info "Linked $target → $entry"
  done
}

mkdir -p "$config_dir" || warn "Failed to create $config_dir"
link_dir_to_config "$dots_dir"

if [[ -d "$dots_dir/.sys" ]]; then
  read -rp "Link .dots/.sys into ~/.config? (y/N): " sys_choice
  if [[ "${sys_choice,,}" == "y" ]]; then
    link_dir_to_config "$dots_dir/.sys"
  fi
fi

if [[ -f "$dots_dir/bash/config.bash" ]]; then
  backup_and_remove "$HOME/.bashrc"
  ln -s "$config_dir/bash/config.bash" "$HOME/.bashrc" ||
    warn "Failed to link ~/.bashrc"
fi

if [[ -f "$dots_dir/zsh/zsh.config" ]]; then
  backup_and_remove "$HOME/.zshrc"
  ln -s "$config_dir/zsh/zsh.config" "$HOME/.zshrc" ||
    warn "Failed to link ~/.zshrc"
fi

# /etc linking (only if root)
if [[ -d "$dots_dir/etc" ]]; then
  if [[ $EUID -eq 0 ]]; then
    info "Linking from $dots_dir/etc → /etc"
    chown -R root:root "$dots_dir/etc" || warn "chown failed"
    shopt -s nullglob dotglob
    for etc_entry in "$dots_dir/etc"/*; do
      etc_name=$(basename "$etc_entry")
      target="/etc/$etc_name"
      if [[ -d "$etc_entry" ]]; then
        if [[ -f "$etc_entry/.lnkfile" ]]; then
          info "Per-file linking for /etc/$etc_name (marker .lnkfile)"
          mkdir -p "$target" || warn "mkdir $target failed"
          for file in "$etc_entry"/*; do
            [[ "$(basename "$file")" == ".lnkfile" ]] && continue
            backup_and_remove "$target/$(basename "$file")"
            ln -s "$file" "$target/$(basename "$file")" ||
              warn "Failed to link $file -> $target"
          done
        else
          backup_and_remove "$target"
          ln -s "$etc_entry" "$target" ||
            warn "Failed to link $etc_entry -> $target"
        fi
      else
        backup_and_remove "$target"
        ln -s "$etc_entry" "$target" ||
          warn "Failed to link $etc_entry -> $target"
      fi
    done
  else
    info "Skipping /etc linking (not running as root)."
  fi
fi

info "✅ Setup complete."
