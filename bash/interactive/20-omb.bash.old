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


