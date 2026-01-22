# --- General Environment Variables ---
export LANG=en_US.UTF-8
if [ -n "$TERMUX_VERSION" ] || [ "$PREFIX" = "/data/data/com.termux/files/usr" ]; then
  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
fi

## -- EDITOR --
if command -v nvim &>/dev/null; then
  export EDITOR="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
elif command -v micro &>/dev/null; then
  export EDITOR="micro"
elif command -v nano &>/dev/null; then
  export EDITOR="nano"
elif command -v vi &>/dev/null; then
  export EDITOR="vi"
else
  unset EDITOR
fi
