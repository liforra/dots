#!/usr/bin/env bash
# SSH/Mosh enhanced wrapper
# Version 0.9.4

set -euo pipefail

REAL_SSH=$(which ssh)
ENHANCED_CONFIG="$HOME/.ssh/enhanced_config"
SSH_CONFIG="$HOME/.ssh/config"
VERSION="0.9.4"

# Defaults
DEFAULT_MOSH_START=60001
DEFAULT_MOSH_END=60010
USE_GUI=0
USE_TUI=0
NO_TERM=0
FORCE_SSH=0
FORCE_MOSH=0
VERBOSITY=1
SCRIPT_FILE=""
SCRIPT_SHELL="bash"
MOSH_UDP_START=$DEFAULT_MOSH_START
MOSH_UDP_END=$DEFAULT_MOSH_END

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BOLD="\e[1m"
RESET="\e[0m"

log() {
  local lvl=$1
  shift
  if [ "$VERBOSITY" -ge "$lvl" ] || [ "$lvl" -eq 0 ]; then
    echo -e "$*"
  fi
}

usage() {
  cat <<EOF
\e[1mUsage:\e[0m ssh [options] <host> [command...]

Options:
  --gui, --tui              Show host selection GUI or TUI
  --no-term                 Do not handle TERMINFO for Kitty
  --ssh                     Force SSH instead of Mosh
  --mosh                    Force Mosh instead of SSH
  --port-range START-END    UDP port range for Mosh (default 60001-60010)
  --script FILE             Copy and execute a local script remotely
  --shell SHELL             Shell to use for --script (default: bash)
  -v, --verbose             Increase verbosity (can use twice for more)
  -h, --help                Show this help message
  --version                 Show version info

Common Mosh Options:
  --port=PORT[:PORT2]       Server-side UDP port or range
  --ssh=COMMAND             Custom SSH command for Mosh
  -4 / -6                   Force IPv4 or IPv6
  --predict=adaptive|always|never
  --no-ssh-pty              Do not allocate pseudo tty on SSH
  --local                   Run server locally without SSH

Common SSH Options:
  -p PORT                   SSH port
  -i IDENTITY_FILE          Private key file
  -o OPTION                 Config option
  -J HOST:PORT              Jump host
  -v                        Verbose
  -vv                       More verbose
  -C                        Enable compression
  -L LOCAL:REMOTE:PORT      Local port forwarding
  -R REMOTE:LOCAL:PORT      Remote port forwarding

Options usable with either Mosh or SSH:
  -h, --help
  --version
  --gui, --tui
  --no-term
  --script FILE
  --shell SHELL
  -v, --verbose
EOF
  exit 0
}

# Parse special flags
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
  --gui) USE_GUI=1 ;;
  --tui) USE_TUI=1 ;;
  --no-term) NO_TERM=1 ;;
  --ssh) FORCE_SSH=1 ;;
  --mosh) FORCE_MOSH=1 ;;
  --port-range)
    IFS=- read -r MOSH_UDP_START MOSH_UDP_END <<<"$2"
    shift
    ;;
  --script)
    SCRIPT_FILE="$2"
    shift
    ;;
  --shell)
    SCRIPT_SHELL="$2"
    shift
    ;;
  -v | --verbose)
    VERBOSITY=$((VERBOSITY + 1))
    ;;
  -h | --help) usage ;;
  --version)
    echo "$VERSION"
    exit 0
    ;;
  --)
    shift
    break
    ;;
  *) ARGS+=("$1") ;;
  esac
  shift
done
set -- "${ARGS[@]}"

# Host and command parsing
if [ $# -lt 1 ] && [ "$USE_GUI" -eq 0 ] && [ "$USE_TUI" -eq 0 ]; then
  usage
fi

INPUT="$1"
shift
REMOTE_CMD=("$@")

# Detect Kitty terminal
KITTY_TERM=0
KITTY_TERMINFO_DIR=""
if [ "$NO_TERM" -eq 0 ]; then
  if [ "${TERM_PROGRAM:-}" = "kitty" ] || [[ "${TERM:-}" == *kitty* ]]; then
    KITTY_TERM=1
    KITTY_TERMINFO_DIR="${TERMINFO:-$HOME/.terminfo}"
  fi
fi

# ===== Helper functions =====
parse_hosts() {
  local file="$1"
  awk '/^Host[[:space:]]+/ {for(i=2;i<=NF;i++) print $i}' "$file"
}

find_host_config() {
  local host="$1"
  local file="$2"
  awk "/^Host[[:space:]]+.*\b$host\b/,/^Host[[:space:]]+/" "$file" | sed '$d'
}

# Select host via GUI/TUI
if [ "$USE_GUI" -eq 1 ]; then
  [ ! -x "$(command -v zenity)" ] && echo "zenity required" && exit 1
  HOST_LIST=$(parse_hosts "$ENHANCED_CONFIG"; parse_hosts "$SSH_CONFIG")
  INPUT=$(echo "$HOST_LIST" | zenity --list --title="Select Host" --column="Host" --height=400 --width=500)
  [ -z "$INPUT" ] && exit 1
fi

if [ "$USE_TUI" -eq 1 ]; then
  [ ! -x "$(command -v fzf)" ] && echo "fzf required" && exit 1
  HOST_LIST=$(parse_hosts "$ENHANCED_CONFIG"; parse_hosts "$SSH_CONFIG")
  INPUT=$(echo "$HOST_LIST" | fzf --prompt="Select host: ")
  [ -z "$INPUT" ] && exit 1
fi

# ===== Initialize variables =====
TARGET=""
USER=""
PORT=""
IDENTITY=""
OPTIONS=()
MOSH_UDP_START=$DEFAULT_MOSH_START
MOSH_UDP_END=$DEFAULT_MOSH_END

# Try enhanced config first
if [ -f "$ENHANCED_CONFIG" ] && grep -q -E "^Host[[:space:]]+.*\b$INPUT\b" "$ENHANCED_CONFIG"; then
  CONF_BLOCK=$(find_host_config "$INPUT" "$ENHANCED_CONFIG" || true)
  HOSTS=($(echo "$CONF_BLOCK" | grep -i "^HostName" | awk '{print $2}' || true))
  TARGET="${HOSTS[0]:-$INPUT}"
  USER=$(echo "$CONF_BLOCK" | grep -i "^User" | awk '{print $2}' || true)
  PORT=$(echo "$CONF_BLOCK" | grep -i "^Port" | awk '{print $2}' || true)
  IDENTITY=$(echo "$CONF_BLOCK" | grep -i "^IdentityFile" | awk '{print $2}' || true)
  OPTIONS=($(echo "$CONF_BLOCK" | grep -i "^Option" | awk '{$1=""; print $0}' || true))
  MOSH_UDP_START=$(echo "$CONF_BLOCK" | grep -i "^MoshPortStart" | awk '{print $2}' || echo "$DEFAULT_MOSH_START")
  MOSH_UDP_END=$(echo "$CONF_BLOCK" | grep -i "^MoshPortEnd" | awk '{print $2}' || echo "$DEFAULT_MOSH_END")
  SCRIPT_SHELL=$(echo "$CONF_BLOCK" | grep -i "^ScriptShell" | awk '{print $2}' || echo "$SCRIPT_SHELL")
fi

# Fallback to SSH config
if [ -z "$TARGET" ]; then
  CONF_BLOCK=$(find_host_config "$INPUT" "$SSH_CONFIG" || true)
  HOSTS=($(echo "$CONF_BLOCK" | grep -i "^HostName" | awk '{print $2}' || true))
  TARGET="${HOSTS[0]:-$INPUT}"
  USER=$(echo "$CONF_BLOCK" | grep -i "^User" | awk '{print $2}' || true)
  PORT=$(echo "$CONF_BLOCK" | grep -i "^Port" | awk '{print $2}' || true)
  IDENTITY=$(echo "$CONF_BLOCK" | grep -i "^IdentityFile" | awk '{print $2}' || true)
  OPTIONS=($(echo "$CONF_BLOCK" | grep -i "^Option" | awk '{$1=""; print $0}' || true))
fi

[ -z "${OPTIONS[*]+x}" ] && OPTIONS=()

# ===== Connection function =====
try_host() {
  local TARGET="$1"
  shift
  local SSH_FLAGS=("$@")

  log 0 "Trying $TARGET..."

  # Copy terminfo if needed
  if [ "$KITTY_TERM" -eq 1 ]; then
    SSH_FLAGS+=("-o" "SendEnv=TERMINFO_DIRS")
    export TERMINFO_DIRS="$KITTY_TERMINFO_DIR"
    ssh "$TARGET" "infocmp xterm-kitty >/dev/null 2>&1 || mkdir -p ~/.terminfo && scp $TERMINFO_DIRS/* $TARGET:~/.terminfo/" || true
  fi

  # Script execution
  if [ -n "$SCRIPT_FILE" ]; then
    BASENAME=$(basename "$SCRIPT_FILE")
    log 0 "Copying script $SCRIPT_FILE to remote..."
    scp "$SCRIPT_FILE" "$TARGET:~/$BASENAME"
    log 0 "Executing script on remote..."
    ssh "$TARGET" "${SSH_FLAGS[@]}" "$SCRIPT_SHELL ~/$BASENAME"
    return $?
  fi

  # Mosh attempt
  if command -v mosh >/dev/null 2>&1 && [ "$FORCE_SSH" -eq 0 ]; then
    if ssh "$TARGET" "command -v mosh-server >/dev/null 2>&1"; then
      log 0 "mosh-server found on $TARGET. Attempting Mosh..."
      for port in $(seq "$MOSH_UDP_START" "$MOSH_UDP_END"); do
        if mosh --ssh="$REAL_SSH ${SSH_FLAGS[*]}" --port=$port "$TARGET" "${REMOTE_CMD[@]}" 2>/dev/null; then
          return 0
        else
          log 0 "${YELLOW}mosh port $port not available, trying next...${RESET}"
        fi
      done
      log 0 "${YELLOW}All Mosh ports failed, falling back to SSH...${RESET}"
    else
      log 0 "${YELLOW}mosh not installed on server, using SSH...${RESET}"
    fi
  fi

  log 0 "Using SSH on $TARGET..."
  "$REAL_SSH" "${SSH_FLAGS[@]}" "$TARGET" "${REMOTE_CMD[@]}"
}

# ===== Execute hosts =====
for H in "${HOSTS[@]:-$TARGET}"; do
  FINAL_TARGET="$H"
  [ -n "$USER" ] && FINAL_TARGET="$USER@$H"
  SSH_FLAGS=()
  [ -n "$PORT" ] && SSH_FLAGS+=("-p" "$PORT")
  [ -n "$IDENTITY" ] && SSH_FLAGS+=("-i" "$IDENTITY")
  [ -n "${OPTIONS[*]}" ] && SSH_FLAGS+=("${OPTIONS[@]}")

  if try_host "$FINAL_TARGET" "${SSH_FLAGS[@]}"; then
    exit 0
  fi
done

log 0 "All hosts failed."
exit 1

