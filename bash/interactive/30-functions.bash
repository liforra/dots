banner() {
  cat ~/.dots/ascii | awk '{n=length($0);for(i=1;i<=n;i++){r=int(80+(160*i/n));g=int(50+(20*i/n));b=int(200-(80*i/n));printf "\033[38;2;%d;%d;%dm%c",r,g,b,substr($0,i,1)}print "\033[0m"}'
}
show_short_motd() {

  # Detect package manager and count upgradable packages
  if command -v ~/.dots/.bin/updates >/dev/null 2>&1; then
    ~/.dots/.bin/updates
  fi
}
# -------------------------

# -------------------------
# Translate common mv flags to rsync
# -------------------------

shreset() {
  local start_dir="${HOME}"
  if [[ -n "$SHSTARTDIR" ]]; then
    start_dir="$SHSTARTDIR"
  fi
  local term_type="$TERM"
  clear
  #echo "Resetting shell..."
  exec bash --login -i -c "cd \"$start_dir\"; exec bash -i"
}
initpy() {
  uv init
  uv add liforra-utils["toml"]

}
# Optional: track default start dir for interactive sessions
[[ -z "$SHSTARTDIR" ]] && export SHSTARTDIR="$PWD"
treset() {
  command reset
}
