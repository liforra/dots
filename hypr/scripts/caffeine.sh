#!/bin/bash

if pgrep -x "hypridle" >/dev/null; then
  pkill hypridle
  notify-send -u low -t 2000 "Caffeine Mode" "Idle Inhibitor: ENABLED (Hypridle OFF)"
else
  hypridle &
  notify-send -u low -t 2000 "Caffeine Mode" "Idle Inhibitor: DISABLED (Hypridle ON)"
fi
