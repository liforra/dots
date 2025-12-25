# This file assumes you have oh-my-zsh installed.
# You can install it with:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load.
ZSH_THEME="robbyrussell"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# see https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
plugins=(
  git
  z
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Starship prompt
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

fastfetch

# Aliases
alias gp="git push"
alias gc="git commit -a"
alias gpc="gc && gp"

alias clear="clear && fastfetch"
# alias reload="source ~/.zshrc && sleep .3 && clear"
alias reload='exec zsh'

alias cd="z"
alias la="eza --header --icons -la"
alias ls="eza --header --icons"
alias tree="eza --tree --icons"
