#!/bin/bash
# --- AUTOMATIC PATH DETECTION ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- CONFIGURATION ---
PYTHON_BIN="/usr/bin/python3"
ALERT_SCRIPT="$SCRIPT_DIR/guard_alert.py"
VM_STORAGE="/mnt/vm_ssd"
WIN_VM="$VM_STORAGE/vmware/Windows 10 x64/Windows 10 x64.vmx"
REQUIRED_PKG="libaio1t64"

# --- WELCOME ALERT ---
$PYTHON_BIN "$ALERT_SCRIPT" "[->] System Online: Sentinel is now orchestrating your workspace."

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

if ps aux | grep "vmware-vmx" | grep -v "grep" | grep -q "$WIN_VM"; then
    echo "[!] The Windows 10 VM is already running. Skipping launch."
    $PYTHON_BIN "$ALERT_SCRIPT" "Sentinel: Windows 10 VM is already active. No action taken."
else
	# Check if any other VMware instance is running
    if pgrep -x "vmware" > /dev/null; then
        echo "[->] VMware UI is open, but the specific VM is not running. Launching now..."
        $PYTHON_BIN "$ALERT_SCRIPT" "[->] VMware UI is open, but the specific VM is not running. Launching now..."        
    fi

    echo "[->] Booting up the Windows environment in a new terminal..."
    gnome-terminal --title="Sentinel: VMware Engine" -- bash -c "
        echo '[->] Starting VMware...';
        $PYTHON_BIN '$ALERT_SCRIPT' '[->] Starting VMware...';
        if vmware -x '$WIN_VM'; then
            echo '[->] Windows VM interface is loading.';
            $PYTHON_BIN '$ALERT_SCRIPT' '[->] Windows VM is loaded';
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
if nohup gio launch /usr/share/applications/google-chrome.desktop > /dev/null 2>&1 & then
	echo '[->] Chrome launched successfully.'
	$PYTHON_BIN "$ALERT_SCRIPT" "[->] Chrome launched."
else
	echo '[!] ERROR: Chrome failed to launch'
    $PYTHON_BIN "$ALERT_SCRIPT" "[!] Error: Chrome failed to launch."
fi

disown -a
echo "[->] All systems online. Closing terminal in 5s..."
sleep 5
exit
