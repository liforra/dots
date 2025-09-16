#!/usr/bin/env bash
set -euo pipefail

# Detect current user's home in a portable way
# Avoid relying on $HOME in subsequent commands.
USER_NAME="$(id -un)"
TARGET="$(getent passwd "$USER_NAME" | cut -d: -f6)"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Could not determine home directory for user $USER_NAME" >&2
  exit 1
fi

# Path to the stowable repo (adjust if needed)
# Expect packages like shell, scripts, hypr, kitty, niri, nushell, nvim, rofi, waybar, starship.
REPO="${REPO:-$TARGET/dots/home}"

# Check repo exists
if [ ! -d "$REPO" ]; then
  echo "Repository not found at: $REPO" >&2
  echo 'Set REPO="/absolute/path/to/your/repo" and retry.' >&2
  exit 1
fi

# Ensure stow exists
if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found. Install it first." >&2
  echo "Arch/CachyOS: sudo pacman --needed -S extra/stow" >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
BACK="$TARGET/.stow-backup-$timestamp"

CDIR="$TARGET/.config"
LDIR="$TARGET/.local"

# Packages to stow (edit to match your repo packages)
PKGS_HOME=(
  shell
  scripts
  hypr
  kitty
  niri
  nushell
  nvim
  rofi
  waybar
  starship
)

echo "[info] User: $USER_NAME"
echo "[info] Home: $TARGET"
echo "[info] Repo: $REPO"
echo "[info] Backup dir: $BACK"
echo

# Create backup dir
mkdir -p "$BACK"

backup_path() {
  # Moves an existing file/dir/symlink to the backup, preserving relative path
  local abs="$1"
  if [ -e "$abs" ] || [ -L "$abs" ]; then
    local rel="${abs#$TARGET/}"
    local dest="$BACK/$rel"
    mkdir -p "$(dirname "$dest")"
    echo "[backup] $abs -> $dest"
    mv -f "$abs" "$dest"
  fi
}

# 1) Backup likely conflicts
echo "[step] Backing up potential conflicts under $TARGET"
mkdir -p "$CDIR" "$LDIR"

# shell
backup_path "$TARGET/.bashrc"
backup_path "$TARGET/.zshrc"
backup_path "$TARGET/bash"
backup_path "$TARGET/zsh"

# scripts
backup_path "$LDIR/bin"

# configs
for d in hypr kitty niri nushell nvim rofi waybar; do
  backup_path "$CDIR/$d"
done
backup_path "$CDIR/starship.toml"

# 2) Remove known bad symlink patterns that may exist inside the repo (optional safety)
# Example: historical absolute symlinks inside repo for kitty.
if [ -L "$REPO/.config/kitty/kitty" ]; then
  echo "[fix] Removing bad repo symlink: $REPO/.config/kitty/kitty"
  rm -f "$REPO/.config/kitty/kitty"
fi

# 3) Dry-run stow to preview actions
echo
echo "[step] Dry-run stow from $REPO"
cd "$REPO"
stow -nvvt "$TARGET" "${PKGS_HOME[@]}" || true

# 4) Apply stow
echo
echo "[step] Applying stow"
stow -Rvt "$TARGET" "${PKGS_HOME[@]}"

# 5) Basic verification
echo
echo "[verify] Verifying key links:"
check_link() {
  local p="$1"
  if [ -L "$p" ]; then
    echo "  ok: $p -> $(readlink "$p")"
  elif [ -e "$p" ]; then
    echo "  warn: $p exists but is not a symlink"
  else
    echo "  warn: $p missing"
  fi
}
check_link "$CDIR/nvim"
check_link "$CDIR/kitty"
check_link "$CDIR/hypr"
check_link "$CDIR/rofi"
check_link "$CDIR/waybar"
check_link "$CDIR/nushell"
check_link "$LDIR/bin"

# 6) Finish
echo
echo "[done] Migration complete."
echo "Backup kept at: $BACK"
echo "If everything looks good, you can remove it later:"
echo "  rm -rf $BACK"
