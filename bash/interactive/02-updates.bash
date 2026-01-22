# Update Dotfiles
# Run update.sh automatically in interactive shells, but not too frequently.
DOTS_DIR="$HOME/.dots"
LAST_UPDATE_FILE="$DOTS_DIR/.last_update_check"
UPDATE_FREQUENCY_DAYS=7 # Check for updates every 7 days

# Guard to prevent update check and greeting from running twice (e.g. in subshells)
if [ -z "$_DOTS_SESSION_INITIALIZED" ]; then
  export _DOTS_SESSION_INITIALIZED=1
  _SHOULD_RUN_GREETING=true

  if [ -f "$LAST_UPDATE_FILE" ]; then
    LAST_UPDATE_TIMESTAMP=$(cat "$LAST_UPDATE_FILE")
    CURRENT_TIMESTAMP=$(date +%s)
    SECONDS_SINCE_LAST_UPDATE=$((CURRENT_TIMESTAMP - LAST_UPDATE_TIMESTAMP))
    SECONDS_IN_DAY=$((60 * 60 * 24))

    if [ "$SECONDS_SINCE_LAST_UPDATE" -ge "$((UPDATE_FREQUENCY_DAYS * SECONDS_IN_DAY))" ]; then
      echo -e "\e[1;32mUpdating dotfiles...\e[0m"
      ("$DOTS_DIR/update.sh" auto >/tmp/dotfiles-update.log 2>&1) &
      date +%s >"$LAST_UPDATE_FILE" # Update timestamp after checking
    fi
  else
    # If no last update file, run update.sh once and create the file
    echo -e "\e[1;32mRunning initial dotfiles update...\e[0m"
    ("$DOTS_DIR/update.sh" auto >/tmp/dotfiles-update.log 2>&1) &
    date +%s >"$LAST_UPDATE_FILE"
  fi
fi
