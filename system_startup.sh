#!/bin/bash

# --- AUTOMATIC PATH DETECTION ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- CONFIGURATION ---
PYTHON_BIN="/usr/bin/python3"
ALERT_SCRIPT="$SCRIPT_DIR/guard_alert.py"
VM_STORAGE="/mnt/vm_ssd"
WIN_VM="$VM_STORAGE/vmware/Windows 10 x64/Windows 10 x64.vmx"
REQUIRED_PKG="libaio1t64"

# --- FUNCTION: CHECK AND INSTALL DEPENDENCIES ---
check_dependencies() {
    echo "[->] Checking for required system libraries..."
    if dpkg -l | grep -q "$REQUIRED_PKG"; then
        echo "[->] Dependency $REQUIRED_PKG is already installed."
    else
        echo "[!] $REQUIRED_PKG is missing. Installing now..."
        sudo apt update && sudo apt install -y "$REQUIRED_PKG"
        if [ $? -eq 0 ]; then
            echo "[->] Successfully installed $REQUIRED_PKG"
        else
            echo "[!] FAILED to install $REQUIRED_PKG."
            $PYTHON_BIN "$ALERT_SCRIPT" "[!] Dependency error: Could not install $REQUIRED_PKG"
        fi
    fi
}

# --- STEP 1: SYSTEM MAINTENANCE ---
echo "[->] Checking for system updates..."
sudo apt update && sudo apt upgrade -y
check_dependencies

# --- STEP 2: STORAGE VALIDATION ---
echo "[->] Verifying if the SSD is mounted..."
if mountpoint -q "$VM_STORAGE"; then
    echo "[->] SSD is online. Ready to go."
else
    echo "[!] Disk error! $VM_STORAGE is missing."
    $PYTHON_BIN "$ALERT_SCRIPT" "[!] Warning: $VM_STORAGE not found!"
    exit 1
fi

# --- STEP 3: BOOT THE WINDOWS VM (With Process Guard) ---
echo "[->] Checking VMware status..."
export DISPLAY=:0

if pgrep -f "vmware" > /dev/null; then
    echo "[!] VMware is already running. Skipping launch."
    $PYTHON_BIN "$ALERT_SCRIPT" "[!] Sentinel: VMware was already active. No new instance started."
else
    echo "[->] Booting up the Windows environment in a new terminal..."
    gnome-terminal --title="Sentinel: VMware Engine" -- bash -c "
        echo '[->] Starting VMware...';
        if vmware -x '$WIN_VM'; then
            echo '[->] Windows VM interface is loading.';
            sleep 3;
        else
            echo '[!] VMware failed to start the machine.';
            $PYTHON_BIN '$ALERT_SCRIPT' '[!] Error: Windows VM failed to boot.';
            exec bash;
        fi
    " &
fi

# --- STEP 4: GOOGLE CHROME ---
echo "[->] Opening CHROME in a new terminal..."
gnome-terminal --title="Sentinel: Chrome" -- bash -c "
    if gio launch /usr/share/applications/google-chrome.desktop; then
        echo '[->] Chrome launched successfully.';
        sleep 2;
    else
        echo '[!] ERROR: Chrome failed to launch';
        exec bash;
    fi
" &

disown -a
echo "[->] All systems online. Closing terminal in 5s..."
sleep 5
exit
