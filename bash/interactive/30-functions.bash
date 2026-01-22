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
# Translate common cp flags to rsync
# -------------------------
_cp_translate_args() {
  local rsync_flags="-ah --progress --partial --info=progress2"
  local src=()
  local dest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -r | -R | --recursive)
      rsync_flags="$rsync_flags -r"
      shift
      ;;
    -v | --verbose)
      rsync_flags="$rsync_flags -v"
      shift
      ;;
    -f | --force)
      rsync_flags="$rsync_flags --ignore-existing"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "cp: unsupported option $1"
      return 1
      ;;
    *)
      break ;; 
    esac
  done

  # Last argument is destination
  dest="${!#}"

  # Everything before last is source
  src=("${@:1:$#-1}")

  echo "$rsync_flags" "${src[@]}" "$dest"
}

cp() {
  if [ $# -lt 2 ]; then
    echo "Usage: cp [options] source... destination"
    return 1
  fi
  eval rsync $($_cp_translate_args "$@")
}

# -------------------------
# Translate common mv flags to rsync
# -------------------------
_mv_translate_args() {
  local rsync_flags="-ah --progress --partial --info=progress2 --remove-source-files"
  local src=()
  local dest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -v | --verbose)
      rsync_flags="$rsync_flags -v"
      shift
      ;;
    -f | --force)
      rsync_flags="$rsync_flags --ignore-existing"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "mv: unsupported option $1"
      return 1
      ;;
    *)
      break ;; 
    esac
  done

  dest="${!#}"
  src=("${@:1:$#-1}")

  echo "$rsync_flags" "${src[@]}" "$dest"
}

mv() {
  if [ $# -lt 2 ]; then
    echo "Usage: mv [options] source... destination"
    return 1
  fi
  eval rsync $($_mv_translate_args "$@")
  # Clean up empty directories
  for src in "${@:1:$#-1}"; do
    [ -d "$src" ] && find "$src" -type d -empty -delete
  done
}

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

# Optional: track default start dir for interactive sessions
[[ -z "$SHSTARTDIR" ]] && export SHSTARTDIR="$PWD"
treset() {
  command reset
}
