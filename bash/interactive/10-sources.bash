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
  PS1='[\u@\h \W]\$ '
  eval "$(
    starship init bash --print-full-init |
      sed 's|/usr/local/bin/starship|starship|g'
  )"
fi
eval "$(zoxide init bash)"
