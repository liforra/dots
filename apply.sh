#!/usr/bin/env bash
set -euo pipefail

# Config
: "${HOME:?HOME not set}"
REPO="${REPO:-$PWD}"

HOME_STOW_DIR="$REPO/home"
ROOT_STOW_DIR="$REPO/root"

# Home packages to stow (directories inside $HOME_STOW_DIR)
HOME_PKGS=(hypr kitty nvim rofi waybar nushell starship shell scripts)

# CLI requirements that should exist on the machine (binaries to check)
REQUIREMENTS=(hyprlock kitty neovim waybar nushell starship stow)

# System packages will be stowed from $ROOT_STOW_DIR with target "/"
# If left empty, we will auto-detect by listing top-level dirs in $ROOT_STOW_DIR
SYS_PKGS=()

# ----------------- helpers -----------------

have() { command -v "$1" >/dev/null 2>&1; }

pm_detect() {
  if have pacman; then
    printf '%s\n' pacman
  elif have apt-get || have apt; then
    printf '%s\n' apt
  elif have pkg && [ -n "${PREFIX:-}" ] && [ -n "${TERMUX_VERSION:-}" ]; then
    printf '%s\n' termux
  elif have nixos-rebuild; then
    printf '%s\n' nixos
  elif have nix-env || have nix; then
    printf '%s\n' nix
  else
    printf '%s\n' unknown
  fi
}

join_by() {
  local sep="$1"; shift
  local out="" x
  for x in "$@"; do
    if [ -z "$out" ]; then out="$x"; else out="$out$sep$x"; fi
  done
  printf '%s' "$out"
}

prompt_yes_no() {
  local msg="${1:-Proceed?} [y/N]: "
  printf '%s' "$msg"
  read -r ans || true
  case "${ans:-}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

map_pkg_name() {
  # args: PM NAME -> echoes package name for that PM
  local pm="$1" name="$2" pkg="$2"
  case "$pm" in
    pacman)
      case "$name" in
        neovim)   pkg="extra/neovim" ;;
        kitty)    pkg="extra/kitty" ;;
        waybar)   pkg="extra/waybar" ;;
        hyprlock) pkg="extra/hyprlock" ;;
        nushell)  pkg="extra/nushell" ;;
        starship) pkg="extra/starship" ;;
        stow)     pkg="extra/stow" ;;
      esac
      ;;
    apt)
      case "$name" in
        neovim)   pkg="neovim" ;;
        kitty)    pkg="kitty" ;;
        waybar)   pkg="waybar" ;;
        hyprlock) pkg="hyprlock" ;; # may be unavailable on some releases
        nushell)  pkg="nushell" ;;  # may require backports/third-party
        starship) pkg="starship" ;;
        stow)     pkg="stow" ;;
      esac
      ;;
    termux)
      case "$name" in
        neovim)   pkg="neovim" ;;
        nushell)  pkg="nushell" ;;
        starship) pkg="starship" ;;
        stow)     pkg="stow" ;;
        # GUI apps not applicable on Termux
        kitty|waybar|hyprlock) pkg="" ;;
      esac
      ;;
    nix|nixos)
      pkg="$name"
      ;;
  esac
  printf '%s\n' "$pkg"
}

install_missing() {
  local pm="$1"; shift
  local to_install=() name mapped
  for name in "$@"; do
    mapped="$(map_pkg_name "$pm" "$name")"
    [ -n "$mapped" ] && to_install+=("$mapped")
  done
  if [ "${#to_install[@]}" -eq 0 ]; then
    printf '%s\n' "Nothing to install for $pm."
    return 0
  fi

  case "$pm" in
    pacman)
      sudo pacman --needed -S "${to_install[@]}"
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "${to_install[@]}"
      ;;
    termux)
      pkg update -y
      pkg install -y "${to_install[@]}"
      ;;
    nix)
      # user-level install
      # shellcheck disable=SC2086
      nix-env -iA $(printf 'nixpkgs.%s ' "${to_install[@]}")
      ;;
    nixos)
      printf '%s\n' "Detected NixOS. Declare these in your system config:"
      printf '  environment.systemPackages = with pkgs; [ %s ];\n' "$(join_by ' ' "${to_install[@]}")"
      ;;
    *)
      printf '%s\n' "Unsupported package manager. Install manually: $(join_by ' ' "$@")" >&2
      return 1
      ;;
  esac
}

list_dir_packages() {
  # echoes top-level directories inside the given path (used for root stow)
  local dir="$1"
  [ -d "$dir" ] || return 0
  local p
  for p in "$dir"/*; do
    [ -d "$p" ] || continue
    printf '%s\n' "$(basename "$p")"
  done
}

# ----------------- requirement checks -----------------

missing=()
for r in "${REQUIREMENTS[@]}"; do
  if ! have "$r"; then
    missing+=("$r")
  fi
done

pm="$(pm_detect)"

if [ "${#missing[@]}" -gt 0 ]; then
  printf '%s\n' "Detected package manager: $pm"
  printf '%s\n' "Missing requirements: $(join_by ', ' "${missing[@]}")"
  if prompt_yes_no "Install missing requirements now?"; then
    if ! install_missing "$pm" "${missing[@]}"; then
      printf '%s\n' "Some installations failed or are unsupported."
      if ! prompt_yes_no "Continue to stow anyway?"; then
        exit 1
      fi
    fi
  else
    printf '%s\n' "Skipping installation; continuing to stow." >&2
  fi
else
  printf '%s\n' "All requirements are present."
fi

# ----------------- stow: home -----------------

if [ -d "$HOME_STOW_DIR" ]; then
  printf '%s\n' "Home stow dir: $HOME_STOW_DIR"
  if prompt_yes_no "Proceed to stow home packages into $HOME?"; then
    cd "$HOME_STOW_DIR"
    stow -nvvt "$HOME" "${HOME_PKGS[@]}" || true
    stow -Rvt "$HOME" "${HOME_PKGS[@]}"
  else
    printf '%s\n' "Skipped stowing home packages."
  fi
else
  printf '%s\n' "Home stow dir not found: $HOME_STOW_DIR (skipping)" >&2
fi

# ----------------- stow: root -----------------

if [ -d "$ROOT_STOW_DIR" ]; then
  printf '%s\n' "Root stow dir: $ROOT_STOW_DIR"
  if [ "${#SYS_PKGS[@]}" -eq 0 ]; then
    mapfile -t SYS_PKGS < <(list_dir_packages "$ROOT_STOW_DIR")
  fi
  if [ "${#SYS_PKGS[@]}" -gt 0 ]; then
    printf '%s\n' "System packages to stow: $(join_by ' ' "${SYS_PKGS[@]}")"
    if have sudo; then
      if prompt_yes_no "Proceed to stow system packages into / (requires sudo)?"; then
        cd "$ROOT_STOW_DIR"
        sudo stow -nvvt / "${SYS_PKGS[@]}" || true
        sudo stow -Rvt / "${SYS_PKGS[@]}"
      else
        printf '%s\n' "Skipped stowing system packages."
      fi
    else
      printf '%s\n' "sudo not found; skipping system packages." >&2
    fi
  else
    printf '%s\n' "No system packages detected in $ROOT_STOW_DIR."
  fi
else
  printf '%s\n' "Root stow dir not found: $ROOT_STOW_DIR (skipping)" >&2
fi

printf '%s\n' "Done."
