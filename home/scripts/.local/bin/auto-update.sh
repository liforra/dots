#!/usr/bin/env bash
set -euo pipefail

dots_dir="$HOME/.dots"

cd "$dots_dir"

# Fetch latest changes quietly
git fetch --quiet

# Check if local is behind remote
if ! git diff --quiet HEAD origin/$(git rev-parse --abbrev-ref HEAD); then
  echo "[DOTS] Updates found, pulling..."
  git pull --quiet
  "$dots_dir/setup.sh"
  echo "[DOTS] Updated at $(date)"
else
  echo "[DOTS] No updates at $(date)"
fi
