if [[ -z $TMUX ]]; then
  # We are not in Tmux,
  if command -v tmux; then
    tmux
  fi
fi
