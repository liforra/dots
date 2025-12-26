# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

# Path to your oh-my-bash installation.
export OSH='/home/liforra/.oh-my-bash'

## --- Custom Shell Sources ---
source "$OSH"/oh-my-bash.sh
source -- ~/.local/share/blesh/ble.sh
eval -- "$(/usr/local/bin/starship init bash --print-full-init)"
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
# --- Aliases ---

# This is a fix for when fastfetch hangs. I have had that problem more then once.
alias fastfetch="timeout 10s fastfetch"

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

#
#
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
