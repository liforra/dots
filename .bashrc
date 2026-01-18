# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

# Update Dotfiles
# Run update.sh automatically in interactive shells, but not too frequently.
DOTS_DIR="$HOME/.dots"
LAST_UPDATE_FILE="$DOTS_DIR/.last_update_check"
UPDATE_FREQUENCY_DAYS=7 # Check for updates every 7 days

# Guard to prevent update check and greeting from running twice (e.g. in subshells)
if [ -z "$_DOTS_SESSION_INITIALIZED" ]; then
  export _DOTS_SESSION_INITIALIZED=1
  _SHOULD_RUN_GREETING=true

  if [ -f "$LAST_UPDATE_FILE" ]; then
    LAST_UPDATE_TIMESTAMP=$(cat "$LAST_UPDATE_FILE")
    CURRENT_TIMESTAMP=$(date +%s)
    SECONDS_SINCE_LAST_UPDATE=$((CURRENT_TIMESTAMP - LAST_UPDATE_TIMESTAMP))
    SECONDS_IN_DAY=$((60 * 60 * 24))

    if [ "$SECONDS_SINCE_LAST_UPDATE" -ge "$((UPDATE_FREQUENCY_DAYS * SECONDS_IN_DAY))" ]; then
      echo -e "\e[1;32mUpdating dotfiles...\e[0m"
      ("$DOTS_DIR/update.sh" auto >/tmp/dotfiles-update.log 2>&1) &
      date +%s >"$LAST_UPDATE_FILE" # Update timestamp after checking
    fi
  else
    # If no last update file, run update.sh once and create the file
    echo -e "\e[1;32mRunning initial dotfiles update...\e[0m"
    ("$DOTS_DIR/update.sh" auto >/tmp/dotfiles-update.log 2>&1) &
    date +%s >"$LAST_UPDATE_FILE"
  fi
fi

# Path to your oh-my-bash installation.
export OSH="${HOME}/.oh-my-bash"

# Fix for Termux/Android where USER might be empty
if [ -z "$USER" ]; then
  export USER=$(whoami)
fi

## --- Custom Shell Sources ---
if [ -f "$OSH/oh-my-bash.sh" ]; then
  source "$OSH"/oh-my-bash.sh
fi

if [ -f "${HOME}/.local/share/blesh/ble.sh" ]; then
  source -- "${HOME}/.local/share/blesh/ble.sh"
fi

if command -v starship &>/dev/null; then
  eval -- "$(starship init bash --print-full-init)"
fi

eval "$(zoxide init bash)"

# --- Oh My Bash Settings ---

OSH_THEME=""
OMB_CASE_SENSITIVE="true"
OMB_HYPHEN_SENSITIVE="false"
export UPDATE_OSH_DAYS=13
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
export HISTTIMEFORMAT=$'\e[38;5;245m[\e[38;5;39m%d.%m.%y\e[38;5;245m - \e[38;5;42m%H:%M\e[38;5;245m  \e[38;5;208m%S\e[38;5;245m]\e[0m '
OMB_DEFAULT_ALIASES="check"
OSH_CUSTOM=/home/liforra/.config/omb/custom
OMB_USE_SUDO=true
OMB_TERM_USE_TPUT=no

completions=(
  git
  composer
  ssh
)

aliases=(
  general
)

plugins=(
  git
  bashmarks
)

if [ "$DISPLAY" ] || [ "$SSH" ]; then
  plugins+=(tmux-autoattach)
fi

# --- General Enviorment Variables ---
export LANG=en_US.UTF-8
if [ -n "$TERMUX_VERSION" ] || [ "$PREFIX" = "/data/data/com.termux/files/usr" ]; then
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

## -- EDITOR --
if command -v nvim &>/dev/null && [[ -f "${HOME}/.config/nvim/lua/lazyvim/init.lua" ]]; then
  export EDITOR="nvim"
elif command -v lvim &>/dev/null; then
  export EDITOR="lvim"
elif command -v nvim &>/dev/null; then
  export EDITOR="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
elif command -v micro &>/dev/null; then
  export EDITOR="micro"
elif command -v nano &>/dev/null; then
  export EDITOR="nano"
else
  unset EDITOR
fi

PS1='[\u@\h \W]\$ '

# --- Custom Commands ---
arg0() {
  local argv0=$1
  local program=$2
  shift 2
  (
    exec -a "$argv0" "$program" "$@"
  )
}

show_short_motd() {

  # Detect package manager and count upgradable packages
  if command -v ~/.dots/.bin/updates >/dev/null 2>&1; then
    ~/.dots/.bin/updates
  fi
  # Count logged-in users
  #local user_count
  #user_count=$(who | wc -l)

  # Colors
  #local green='\e[38;5;42m'
  #local yellow='\e[38;5;226m'
  #local red='\e[38;5;208m'
  #local reset='\e[0m'

  #echo -e "${red}>>>${reset} ${green}${user_count}${reset} Users logged in"
}
# -------------------------
# Translate common cp flags to rsync
# -------------------------
_cp_translate_args() {
  local rsync_flags="-ah --progress --partial --info=progress2"
  local src=()
  local dest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -r | -R | --recursive)
      rsync_flags="$rsync_flags -r"
      shift
      ;;
    -v | --verbose)
      rsync_flags="$rsync_flags -v"
      shift
      ;;
    -f | --force)
      rsync_flags="$rsync_flags --ignore-existing"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "cp: unsupported option $1"
      return 1
      ;;
    *) break ;;
    esac
  done

  # Last argument is destination
  dest="${!#}"

  # Everything before last is source
  src=("${@:1:$#-1}")

  echo "$rsync_flags" "${src[@]}" "$dest"
}

cp() {
  if [ $# -lt 2 ]; then
    echo "Usage: cp [options] source... destination"
    return 1
  fi
  eval rsync $(_cp_translate_args "$@")
}

# -------------------------
# Translate common mv flags to rsync
# -------------------------
_mv_translate_args() {
  local rsync_flags="-ah --progress --partial --info=progress2 --remove-source-files"
  local src=()
  local dest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -v | --verbose)
      rsync_flags="$rsync_flags -v"
      shift
      ;;
    -f | --force)
      rsync_flags="$rsync_flags --ignore-existing"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "mv: unsupported option $1"
      return 1
      ;;
    *) break ;;
    esac
  done

  dest="${!#}"
  src=("${@:1:$#-1}")

  echo "$rsync_flags" "${src[@]}" "$dest"
}

mv() {
  if [ $# -lt 2 ]; then
    echo "Usage: mv [options] source... destination"
    return 1
  fi
  eval rsync $(_mv_translate_args "$@")
  # Clean up empty directories
  for src in "${@:1:$#-1}"; do
    [ -d "$src" ] && find "$src" -type d -empty -delete
  done
}

# --- Aliases ---

# Nicer Programs
alias python="ipython"

# default config for programs
alias ip="ip -c"

# This is a fix for when fastfetch hangs. I have had that problem more then once.
alias fastfetch="timeout 10s fastfetch"
alias fastfetch="fastfetch && show_short_motd"

### - Git -
alias gp="git push"
alias gc="git commit -a"
alias gpc="gc && gp"

### - Basic (cd,ls,tree, etc) -
alias cd="z"
alias la="eza --header --icons -la"
alias ls="eza --header --icons"
alias tree="eza --tree --icons"
# Only override 'history' after all startup scripts have run

alias clear="clear && fastfetch"

### - All forms of reloading and resetting -
alias reload='exec bash'
shreset() {
  local start_dir="${HOME}"
  if [[ -n "$SHSTARTDIR" ]]; then
    start_dir="$SHSTARTDIR"
  fi
  local term_type="$TERM"
  clear
  #echo "Resetting shell..."
  exec bash --login -i -c "cd \"$start_dir\"; exec bash -i"
}

# Optional: track default start dir for interactive sessions
[[ -z "$SHSTARTDIR" ]] && export SHSTARTDIR="$PWD"
treset() {
  command reset
}
alias reset="treset && shreset"
## scripts

alias ssh="~/.scripts/ssh.sh"

# Only run fastfetch if we are in the main session (not a subshell)
# using the variable set at the top of the file.
if [ -n "$_DOTS_SESSION_INITIALIZED" ]; then
  # We are in the process that set the variable (or inherited it, but we want to run it only once)
  # Actually, if it's inherited, it's already 1.
  # The logic at the top sets it IF it was empty.
  # So we need to check if we just set it? No, that variable is lost if not exported.
  # I exported it.
  # Wait, if I exported it, then subshells HAVE it set.
  # So I should only run fastfetch if I just set it?
  # But I can't check "just set" easily down here without another var.
  # Alternative: The guard at the top ran.
  # Let's rely on a strictly local variable for this run.
  :
fi

if [ -n "$_DOTS_SESSION_INITIALIZED" ] && [ -z "$_FASTFETCH_RAN" ]; then
  if command -v fastfetch &>/dev/null; then
    fastfetch
  fi
  export _FASTFETCH_RAN=1
fi

# List of hostnames where this block should run
#
# if [ -f /etc/hostname ]; then
#     HOSTNAME_VAL=$(</etc/hostname)
# else
#     HOSTNAME_VAL=$(hostname 2>/dev/null || echo "unknown")
# fi
#
# case "$HOSTNAME_VAL" in
# alhena | antares | sirius | chaosserver | argon)
#   show_short_motd
#   ;;
# *)
#   # Optional: settings for all other hosts
#   ;;
# esac
# #
# #
#
#
#
#
#
#
#
complin() {
  # Linux, GCC/Clang friendly
  export CC=gcc
  export CXX=g++
  export CFLAGS="-O2 -DNDEBUG -Wall -Wextra -Wpedantic \
-fno-omit-frame-pointer \
-fstack-protector-strong \
-D_FORTIFY_SOURCE=2 \
-fPIE \
-march=x86-64 -mtune=generic"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS="-pie -Wl,-z,relro,-z,now"

  echo "Linux compilation environment loaded (gcc/g++, x86_64)"
}
compwin() {
  # Windows target via MinGW-w64
  export CC=x86_64-w64-mingw32-gcc
  export CXX=x86_64-w64-mingw32-g++
  export CFLAGS="-O2 -DNDEBUG -Wall -Wextra -Wpedantic \
-march=x86-64 -mtune=generic"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS=""

  echo "Windows compilation environment loaded (MinGW-w64, x86_64)"
}

# pnpm
export PNPM_HOME="/home/liforra/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[ -f /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash ] && . /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash