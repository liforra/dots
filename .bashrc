# Enable the subsequent settings only in interactive sessions
case $- in
*i*) ;;
*) return ;;
esac

# Path to your oh-my-bash installation.
export OSH='/home/liforra/.oh-my-bash'

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
OSH_THEME=""

# If you set OSH_THEME to "random", you can ignore themes you don't like.
# OMB_THEME_RANDOM_IGNORED=("powerbash10k" "wanelo")
# You can also specify the list from which a theme is randomly selected:
# OMB_THEME_RANDOM_CANDIDATES=("font" "powerline-light" "minimal")

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you don't want the repository to be considered dirty
# if there are untracked files.
# SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

# Uncomment the following line if you want to completely ignore the presence
# of untracked files in the repository.
# SCM_GIT_IGNORE_UNTRACKED="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.  One of the following values can
# be used to specify the timestamp format.
# * 'mm/dd/yyyy'     # mm/dd/yyyy + time
# * 'dd.mm.yyyy'     # dd.mm.yyyy + time
# * 'yyyy-mm-dd'     # yyyy-mm-dd + time
# * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
# * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
# * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
# If not set, the default value is 'yyyy-mm-dd'.
# HIST_STAMPS='yyyy-mm-dd'
export HISTTIMEFORMAT=$'\e[38;5;245m[\e[38;5;39m%d.%m.%y\e[38;5;245m - \e[38;5;42m%H:%M\e[38;5;245m  \e[38;5;208m%S\e[38;5;245m]\e[0m '

# Uncomment the following line if you do not want OMB to overwrite the existing
# aliases by the default OMB aliases defined in lib/*.sh
# OMB_DEFAULT_ALIASES="check"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

OMB_USE_SUDO=true

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

# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(tmux-autoattach)
#  fi

source "$OSH"/oh-my-bash.sh

# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Faster Shell startup (Forces ANSI Escape Sequences)
OMB_TERM_USE_TPUT=no

[[ $- != *i* ]] && return
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
eval -- "$(/usr/local/bin/starship init bash --print-full-init)"
source -- ~/.local/share/blesh/ble.sh
eval "$(zoxide init bash)"

arg0() {
  local argv0=$1
  local program=$2
  shift 2
  (
    exec -a "$argv0" "$program" "$@"
  )
}
alias fastfetch="timeout 10s fastfetch"

fastfetch
alias gp="git push"
alias gc="git commit -a"
alias gpc="gc && gp"

alias history="~/.scripts/history"
alias clear="clear && fastfetch"
# alias reload="source ~/.bash_profile && sleep .3 && clear"
alias reload='exec bash'
alias ssh="~/.scripts/ssh.sh"
alias cd="z"
alias la="eza --header --icons -la"
alias ls="eza --header --icons"
alias tree="eza --tree --icons"

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
