#!/bin/bash
# --- AUTOMATIC PATH DETECTION ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- CONFIGURATION ---
PYTHON_BIN="/usr/bin/python3"
ALERT_SCRIPT="$SCRIPT_DIR/guard_alert.py"
VM_STORAGE="/mnt/vm_ssd"
WIN_VM="$VM_STORAGE/vmware/Windows 10 x64/Windows 10 x64.vmx"
REQUIRED_PKG="libaio1t64"
NETWORK_TEST_IP="8.8.8.8"
NETWORK_TIMEOUT=30

# Get the actual user
REAL_USER=${SUDO_USER:-$USER}
USER_ID=$(id -u "$REAL_USER")

# Global variables for Sound and Display
ENV_VARS="DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/$USER_ID DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus HOME=/home/$REAL_USER"

# --- FUNCTIONS ---

log(){ echo "[->] $1"; }
error(){ echo "[!] ERROR: $1"; }

require_root(){
    if [ "$EUID" -ne 0 ]; then
        error "Script must be run as root (use sudo)"
        exit 1
    fi
}

wait_for_network(){
    log "Waiting for network connection..."
    local count=0
    until ping -c 1 "$NETWORK_TEST_IP" &>/dev/null; do
        sleep 1
        ((count++))
        if [ "$count" -ge "$NETWORK_TIMEOUT" ]; then
            error "Network timeout"; exit 1
        fi
    done
    log "Network is online"
    "$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Network is online" || true
}

check_dependencies() {
    log "Checking for required system libraries..."
    if ! dpkg -l | grep -q "$REQUIRED_PKG"; then
        log "Installing $REQUIRED_PKG..."
        apt update && apt install -y "$REQUIRED_PKG"
    fi
}

system_update(){
    log "Running system update..."
    "$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Running system update..." || true
    apt update -y && apt upgrade -y
}

system_autoremove(){
    log "Environment cleaning..."
    apt autoremove -y
}

validate_storage(){
    log "Verifying SSD mount..."
    if mountpoint -q "$VM_STORAGE"; then
        log "SSD is mounted."
    else
        error "Storage mount $VM_STORAGE not found"
        "$PYTHON_BIN" "$ALERT_SCRIPT" "[!] Storage mount not found" || true
        exit 1
    fi
}

launch_vm(){
    if ps aux | grep "vmware-vmx" | grep -v "grep" | grep -q "$WIN_VM"; then
        log "Windows 10 VM is already active."
        return
    fi

    log "Booting up the Windows environment..."
    sudo -u "$REAL_USER" env $ENV_VARS gnome-terminal --title="Sentinel: VMware Engine" -- bash -c "
        echo 'Starting VMware...';
        $PYTHON_BIN '$ALERT_SCRIPT' '[->] Starting VMware...';
        if vmware -x '$WIN_VM'; then
            echo '[->] Windows VM loaded.';
            $PYTHON_BIN '$ALERT_SCRIPT' '[->] Windows VM is loaded';
            sleep 2;
        else
            echo '[!] ERROR: VMware failed to start.';
            exec bash;
        fi
    " &
}

launch_chrome() {
    log "Checking if Chrome is already active..."
    if pgrep -x "chrome" > /dev/null; then
        log "Chrome is already running."
        return
    fi

    log "Launching Chrome with sound support..."
    # Xhost allow for the user
    xhost +local:"$REAL_USER" > /dev/null
    
    # Launch Chrome directly to ensure Audio-Sync with the user session
    sudo -u "$REAL_USER" env $ENV_VARS google-chrome "https://gemini.google.com" --no-first-run >/dev/null 2>&1 &

    if [ $? -eq 0 ]; then
        log 'Chrome launched on Gemini.'
        "$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Chrome launched on Gemini." || true
    else
        error 'Failed to launch Chrome.'
    fi
}

# --- MAIN EXECUTION ---
require_root
wait_for_network
"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] System Online: Sentinel orchestrating workspace." || true

system_update
system_autoremove
check_dependencies
validate_storage
launch_vm
launch_chrome

log "All systems online."
sleep 3
exit 0
