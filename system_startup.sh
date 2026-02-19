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

export DISPLAY=:0
export XDG_RUNTIME_DIR="/run/user/$USER_ID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"



# --- FUNCTIONS ---

# Standard logging to terminal
log(){
	echo "[->] $1"
}

# Error reporting
error(){
	echo "[!] ERROR: $1"
}

# Verifies it it is ROOT
require_root(){
	if [ "$EUID" -ne 0 ]; then
		error "Script must be run as root(use sudo)"
		exit 1
	fi
}

# Waits for internet connectivity
wait_for_network(){
	log "Waiting for network connection..."
	
	local count=0
	until ping -c 1 "$NETWORK_TEST_IP" &>/dev/null; do
		sleep 1
		((count++))
		if [ "$count" -ge "$NETWORK_TIMEOUT" ]; then
			error "Network timeout after $NETWORK_TIMEOUT seconds"
			exit 1
		fi
	done
	
	log "Network is online"
	"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Network is online" || true
}

# Checks for VMware-specific dependencies
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

# Performs system maintenance (update & upgrade)
system_update(){
	log "Running system update..."
	"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Running system update..." || true
	apt update -y && apt upgrade -y
}
system_autoremove(){
	log "Environment cleaning..."
	"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Environment cleaning..."
	sudo apt autoremove
}

# Verifies if VM SSD is correctly mounted
validate_storage(){
	log "Verifying SSD mount..."
	"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] Verifying SSD mount..."
	
	if mountpoint -q "$VM_STORAGE"; then
		log "SSD is mounted."
		"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] SSD is mounted."
	else
		error "Storage mount $VM_STORAGE not found"
		"$PYTHON_BIN" "$ALERT_SCRIPT" "[!] Storage mount $VM_STORAGE not found"
		exit 1
	fi
}


# Launches VMware and starts the VM in a separate terminal
launch_vm(){
	# 1. Check if the specific VM process is already running
	if ps aux | grep "vmware-vmx" | grep -v "grep" | grep -q "$WIN_VM"; then
		log "The Windows 10 VM is already running. Skipping launch."
		$PYTHON_BIN "$ALERT_SCRIPT" "[->] Windows 10 VM is already active. No action taken." || true
		return
	fi
	
	# 2. Check if any other VMware instance is running
	if pgrep -x "vmware" > /dev/null; then
		log "VMware UI is open, but the specific VM is not running. Launching now..."
	    $PYTHON_BIN "$ALERT_SCRIPT" "[->] VMware UI is open, but the specific VM is not running. Launching now..."        
	fi

	log "Booting up the Windows environment in a new terminal..."
	
	sudo -u "$REAL_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" XDG_RUNTIME_DIR="/run/user/$USER_ID" gnome-terminal --title="Sentinel: VMware Engine" -- bash -c "
		echo 'Starting VMware...';
		$PYTHON_BIN '$ALERT_SCRIPT' '[->] Starting VMware...';
	
		if vmware -x '$WIN_VM'; then
			echo '[->] Windows VM interface is loading.';
	    	$PYTHON_BIN '$ALERT_SCRIPT' '[->] Windows VM is loaded';
	    	sleep 2;
		else
			echo '[!] ERROR: VMware failed to start the machine.';
			$PYTHON_BIN '$ALERT_SCRIPT' '[!] Error: VMware failed to start the machine.';
			exec bash;
		fi
	" &
}

# Launches Google Chrome if not already running
launch_chrome() {
    log "Checking if Chrome is already active..."
    if pgrep -x "chrome" > /dev/null; then
        log "Chrome is already running. No new instance needed."
        return
    fi

    xhost +local:$(whoami) > /dev/null
    rm -f "/home/$REAL_USER/.config/google-chrome/Crash Reports/pending/*.lock"

    log "Opening Chrome in a detached terminal..."
    
    sudo -u "$REAL_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" XDG_RUNTIME_DIR="/run/user/$USER_ID"nohup gnome-terminal --title="Sentinel: Chrome Browser" -- bash -c "
        echo 'Initializing Chrome engine...';
        # Hide the 'Deprecated Endpoint' noise you saw earlier
        google-chrome --profile-directory='Default' --no-first-run 2>/dev/null;

        if [ $? -ne 0 ]; then
            echo '[!] Chrome shut down unexpectedly.';
            exec bash;
        fi
    " >/dev/null 2>&1 &

    disown # Detaches the job from the current terminal
}

# --- MAIN EXECUTION ---
# 1. Check network if it is online
wait_for_network

# 2. Chech for root privileges
require_root

# 3. Send thw official system online alert
"$PYTHON_BIN" "$ALERT_SCRIPT" "[->] System Online: Sentinel orchestrating workspace." || true

# 4. Update the system
system_update

# 5. Check dependencies for VMware
check_dependencies

# 6. Check if SSD is mounted
validate_storage

# 7. Launch VM
launch_vm

# 8. Launch Chrome
launch_chrome

log "All systems online."
sleep 3
exit 0
