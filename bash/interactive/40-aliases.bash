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
alias gc="git commit"
alias gpc="gc && gp"
alias ga="git add"
alias gr="git remote"

alias gcl="git clone"

alias gce="git clone"
alias gpl="git pull"
alias gph="git push"
alias gad="git add"
alias gre="git remote"
### - Basic (cd,ls,tree, etc) -
alias cd="z"
alias la="eza --header --icons -la"
alias ls="eza --header --icons"
alias tree="eza --tree --icons"
# Only override 'history' after all startup scripts have run

alias clear="clear && fastfetch"

### - All forms of reloading and resetting -
alias reload='exec bash'
alias reset="treset && shreset"

## scripts
alias ssh="~/.scripts/ssh.sh"
