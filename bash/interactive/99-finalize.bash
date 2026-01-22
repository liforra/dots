# Only run fastfetch if we are in the main session (not a subshell)
# using the variable set at the top of the file.
if [ -n "$_DOTS_SESSION_INITIALIZED" ]; then
  # We are in the process that set the variable (or inherited it, but we want to run it only once)
  # Actually, if it's inherited, it's already 1.
  # The logic at the top sets it IF it was empty.
  # So we need to check if we just set it? No, that variable is lost if not exported.
  # I exported it.
  # Wait, if I exported it, then subshells HAVE it set.
  # So I should only run fastfetch if I just set it?
  # But I can't check "just set" easily down here without another var.
  # Alternative: The guard at the top ran.
  # Let's rely on a strictly local variable for this run.
  :
fi

if [ -n "$_DOTS_SESSION_INITIALIZED" ]; then
  should_run_fastfetch=false
  if [ -n "$TMUX" ]; then
    # In Tmux: run if new pane
    if [ "$_FASTFETCH_TMUX_PANE" != "$TMUX_PANE" ]; then
      should_run_fastfetch=true
      export _FASTFETCH_TMUX_PANE="$TMUX_PANE"
    fi
  elif [ -z "$_FASTFETCH_RAN" ]; then
    # Not in Tmux: run if not ran before
    should_run_fastfetch=true
  fi

  if [ "$should_run_fastfetch" = true ]; then
    if command -v fastfetch &>/dev/null; then
      fastfetch
    fi
    export _FASTFETCH_RAN=1
  fi
  unset should_run_fastfetch
fi

# List of hostnames where this block should run
#
# if [ -f /etc/hostname ]; then
#     HOSTNAME_VAL=$(</etc/hostname)
# else
#     HOSTNAME_VAL=$(hostname 2>/dev/null || echo "unknown")
# fi
#
# case "$HOSTNAME_VAL" in
# alhena | antares | sirius | chaosserver | argon)
#   show_short_motd
#   ;;
# *)
#   # Optional: settings for all other hosts
#   ;;
# esac
# #
# #
#
#
#
#
#
#
#

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
# Disabled due to shell startup times
#[ -f /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash ] && . /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash
