#!/bin/bash

# Locating where the Sentinel lives
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PYTHON_BIN="/usr/bin/python3"
ALERT_SCRIPT="$SCRIPT_DIR/guard_alert.py"

# --- USER SETTINGS ---
# Change this to the time you want your station to wake up
WAKE_TIME="8:00"

echo "[->] Sentinel Power Manager: Talking to the hardware clock..."

# Get the current time and our target time in seconds (Epoch)
CURRENT_EPOCH=$(date +%s)
TARGET_EPOCH=$(date -d "$WAKE_TIME" +%s)

# If the time has already passed today, we schedule it for tomorrow
if [ $TARGET_EPOCH -le $CURRENT_EPOCH ]; then
    TARGET_EPOCH=$(date -d "tomorrow $WAKE_TIME" +%s)
fi

# Preparing a nice date format for our Telegram message
WAKE_DATE_FRIENDLY=$(date -d "@$TARGET_EPOCH" "+%Y-%m-%d %H:%M:%S")

# Programming the BIOS. 
# '-m no' means: Set the alarm, but don't shut down the PC yet.
if sudo rtcwake -m no -t $TARGET_EPOCH; then
    MESSAGE="All set! Your PC will wake up at: $WAKE_DATE_FRIENDLY"
    echo "[->] $MESSAGE"
    $PYTHON_BIN "$ALERT_SCRIPT" "Sentinel: $MESSAGE"
else
    MESSAGE="Oops! Hardware refused to set the alarm. Check your BIOS settings."
    echo "[!] $MESSAGE"
    $PYTHON_BIN "$ALERT_SCRIPT" "[!] Error: $MESSAGE"
    exit 1
fi

exit 0
