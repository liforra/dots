# This file assumes you have oh-my-fish installed.
# You can install it with:
# curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# oh-my-fish configuration
set -g OMF_PATH "$HOME/.local/share/omf"
set -g OMF_CONFIG "$HOME/.config/omf"
source "$OMF_PATH/init.fish"

# Starship prompt
starship init fish | source

# zoxide
zoxide init fish | source

# Run fastfetch on startup
fastfetch

# Aliases
alias gp "git push"
alias gc "git commit -a"
alias gpc "gc && gp"

alias clear "clear && fastfetch"
# alias reload "source ~/.config/fish/config.fish && sleep .3 && clear"
alias reload 'exec fish'

alias la "eza --header --icons -la"
alias ls "eza --header --icons"
alias tree "eza --tree --icons"

# The 'z' command is handled by the zoxide plugin for fish
# To use it, you need to install the z plugin for oh-my-fish
# omf install z
