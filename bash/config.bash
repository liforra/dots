#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
fastfetch
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
eval -- "$(/usr/local/bin/starship init bash --print-full-init)"

# Created by `pipx` on 2025-08-27 13:23:41
export PATH="$PATH:/home/liforra/.local/bin"
export PATH="$PATH:/home/liforra/flutter/flutter/bin"
export ANDROID_HOME="/home/liforra/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
