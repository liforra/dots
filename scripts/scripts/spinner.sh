#!/usr/bin/env bash
# spinner.sh - color spinner with right-aligned status and clean passthrough I/O

_sp_pid=""
_sp_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
_sp_msg=""
_sp_interval=0.1
_sp_cols=0
_sp_ok_label="[ DONE ]"
_sp_fail_label="[ FAIL ]"
_sp_reset=""
_sp_active=0

_sp_detect_term() {
  if [[ -t 1 ]]; then
    _sp_cols=$(tput cols 2>/dev/null || echo 0)
    if tput setaf 2>/dev/null 1>&2; then
      local green="$(tput setaf 2)"
      local red="$(tput setaf 1)"
      local bold="$(tput bold)"
      _sp_reset="$(tput sgr0)"
      _sp_ok_label="${bold}${green}[ DONE ]${_sp_reset}"
      _sp_fail_label="${bold}${red}[ FAIL ]${_sp_reset}"
    fi
  fi
}

_sp_strip_len() {
  local s="$1"
  s="${s//[$'\x1b''\e']\[[0-9;]*[a-zA-Z]/}"
  printf '%s' "$s" | wc -c | tr -d ' '
}

_sp_print_line() {
  local left="$1" right="$2" keep="${3:-0}"
  if [[ ! -t 1 || -z "$_sp_cols" || "$_sp_cols" -eq 0 ]]; then
    if [[ "$keep" -eq 1 ]]; then
      printf '\r%s' "$left"
    else
      [[ -n "$right" ]] && printf '%s %s\n' "$left" "$right" || printf '%s\n' "$left"
    fi
    return
  fi
  local ll=$(_sp_strip_len "$left")
  local rl=$(_sp_strip_len "$right")
  local pad=1
  if [[ $rl -gt 0 && $_sp_cols -gt $((ll + rl + 1)) ]]; then
    pad=$((_sp_cols - ll - rl))
  fi
  printf '\r%s%*s%s' "$left" "$pad" "" "$right"
  [[ "$keep" -eq 0 ]] && printf '\n'
}

_sp_hide_line() { [[ -t 1 ]] && printf '\r\033[K'; }
_sp_redraw_once() { [[ "$_sp_active" -eq 1 ]] && _sp_print_line "${_sp_frames[0]} $_sp_msg" "" 1; }

start_spinner() {
  _sp_msg="${1:-Working}"
  _sp_detect_term
  if [[ ! -t 1 ]]; then
    printf '%s...\n' "$_sp_msg"
    _sp_active=0
    return 0
  fi
  tput civis 2>/dev/null || true
  _sp_active=1
  (
    trap 'exit 0' TERM
    local i=0
    while :; do
      local frame="${_sp_frames[i % ${#_sp_frames[@]}]}"
      _sp_print_line "$frame $_sp_msg" "" 1
      sleep "$_sp_interval"
      i=$((i + 1))
    done
  ) &
  _sp_pid=$!
  disown 2>/dev/null || true
}

stop_spinner() {
  local code="${1:-0}"
  if [[ -n "$_sp_pid" ]] && kill -0 "$_sp_pid" 2>/dev/null; then
    kill "$_sp_pid" 2>/dev/null
    wait "$_sp_pid" 2>/dev/null
  fi
  if [[ -t 1 ]]; then
    tput cnorm 2>/dev/null || true
    local right=$([[ "$code" -eq 0 ]] && echo "$_sp_ok_label" || echo "$_sp_fail_label")
    _sp_print_line "  $_sp_msg" "$right" 0
  else
    [[ "$code" -eq 0 ]] && printf '%s [ OK ]\n' "$_sp_msg" || printf '%s [ FAIL ]\n' "$_sp_msg"
  fi
  _sp_pid=""
  _sp_msg=""
  _sp_active=0
  return "$code"
}

print_msg() {
  _sp_hide_line
  printf '%s\n' "$*"
  _sp_redraw_once
}
print_err() {
  _sp_hide_line
  printf '%s\n' "$*" >&2
  _sp_redraw_once
}

# Run a command with spinner; stream stdout & stderr cleanly and preserve exit code.
# Usage: run_with_spinner "Message" -- cmd args...
run_with_spinner() {
  local msg="$1"
  shift
  [[ "$1" == "--" ]] && shift

  start_spinner "$msg"

  # Create a temp file for the exit code and two FIFOs for stdout/stderr.
  local _sp_tmp_dir _sp_ec _sp_out _sp_err
  _sp_tmp_dir="$(mktemp -d -t spn.XXXXXXXX)" || {
    print_err "Failed to create temp dir"
    stop_spinner 1
    return 1
  }
  _sp_ec="$_sp_tmp_dir/exitcode"
  _sp_out="$_sp_tmp_dir/out"
  _sp_err="$_sp_tmp_dir/err"
  mkfifo "$_sp_out" "$_sp_err"

  # Reader for stdout
  (
    while IFS= read -r line; do
      _sp_hide_line
      printf '%s\n' "$line"
      _sp_redraw_once
    done <"$_sp_out"
  ) &
  local r1=$!
  # Reader for stderr
  (
    while IFS= read -r line; do
      _sp_hide_line
      printf '%s\n' "$line" >&2
      _sp_redraw_once
    done <"$_sp_err"
  ) &
  local r2=$!

  # Run the command, directing its streams to the FIFOs
  (
    "$@"
    echo $? >"$_sp_ec"
  ) >"$_sp_out" 2>"$_sp_err" &
  local cmd_pid=$!

  # Wait for command and readers
  wait "$cmd_pid"
  # Close FIFOs by removing them after the writer exits
  rm -f "$_sp_out" "$_sp_err" 2>/dev/null || true
  wait "$r1" 2>/dev/null || true
  wait "$r2" 2>/dev/null || true

  # Read exit code
  local code=0
  if [[ -f "$_sp_ec" ]]; then
    code=$(cat "$_sp_ec" 2>/dev/null || echo 1)
  else
    code=1
  fi

  # Cleanup
  rm -rf "$_sp_tmp_dir" 2>/dev/null || true

  stop_spinner "$code"
  return "$code"
}
