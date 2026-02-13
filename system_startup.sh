#!/bin/bash

# --- AUTOMATIC PATH DETECTION ---
# Detects the absolute path of the directory where this script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- CONFIGURATION ---
PYTHON_BIN="/usr/bin/python3"
# Dynamically locate the python alert script in the same directory
ALERT_SCRIPT="$SCRIPT_DIR/guard_alert.py"

# Storage and VM Path
VM_STORAGE="/mnt/vm_ssd"
# Where virtual machine it is
WIN_VM="$VM_STORAGE/vmware/Windows 10 x64/Windows 10 x64.vmx"
REQUIRED_PKG="libaio1t64"

# --- FUNCTION: CHECK AND INSTALL DEPENDENCIES ---
check_dependencies() {
	echo "Checking for required system libraries..."
	if dpkg -l | grep -q "$REQUIRED_PKG"; then
		echo "Dependency $REQUIRED_PKG is already installed."
	else
		echo "$REQUIRED_PKG is missing. Installing now..."
		sudo apt update && sudo apt install -y "$REQUIRED_PKG"
		if [ $? -eq 0 ]; then
			echo "Successfully installed $REQUIRED_PKG"
		else
			echo "FAILED to install $REQUIRED_PKG. VMware might not start"
			$PYTHON_BIN $ALERT_SCRIPT "Dependency error: Could not install $REQUIRED_PKG"
		fi
	fi

}



# --- STEP 1: SYSTEM MAINTENANCE ---
echo "Checking for system updates..."
sudo apt update && sudo apt upgrade -y
check_dependencies


# --- STEP 2: STORAGE VALIDATION ---
echo "Verifying if the SSD is mounted..."
if mountpoint -q "$VM_STORAGE"; then
    echo "SSD is online. Ready to go."
else
    echo "Disk error! $VM_STORAGE is missing."
    # Alerting via Telegram
    $PYTHON_BIN $ALERT_SCRIPT "Warning: $VM_STORAGE not found! Can't start the lab."
    exit 1
fi

# --- STEP 3: BOOT THE WINDOWS VM (WITH GUI) ---
echo "Booting up the Windows environment..."
# Using 'gui' and ensuring DISPLAY is set for the new window appear
export DISPLAY=:0
vmware -x "$WIN_VM" &

# Wait a few seconds to see if the process stays alive
sleep 5

if pgrep -f "vmware" > /dev/null; then
    echo "Windows VM interface is loading."
else
    echo "VMware failed to start the machine."
    $PYTHON_BIN $ALERT_SCRIPT "Error: Windows VM failed to boot. Check if VMware is installed correctly."
fi

# --- STEP 4: GOOGLE CHROME ---
echo "Opening browser..."
gio launch /usr/share/applications/google-chrome.desktop &
disown -a

echo "All systems online. Closing terminal..."
sleep 5
exit
