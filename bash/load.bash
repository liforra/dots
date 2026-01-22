#!/usr/bin/env bash

# Define the base directory for bash configurations
BASH_CONFIG_DIR="${HOME}/.dots/bash"

# Helper function to source all .bash files in a directory
_source_dir() {
  local dir="$1"
  # Clear positional parameters so they don't leak into sourced scripts
  # This fixes issues with scripts like ble.sh that inspect arguments
  set --
  if [ -d "$dir" ]; then
    for file in "$dir"/*.bash; do
      if [ -f "$file" ]; then
        source "$file"
      fi
    done
  fi
}

# 1. Source Common Configurations (Always run)
_source_dir "${BASH_CONFIG_DIR}/common"

# 2. Source Interactive Configurations (Only for interactive shells)
# Check for interactive shell ($- contains 'i')
case "$-" in
*i*)
  _source_dir "${BASH_CONFIG_DIR}/interactive"
  ;;
*) ;;

esac

# Cleanup helper function
unset -f _source_dir
