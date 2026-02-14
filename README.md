# System Sentinel Automation 🛡️

A proactive system orchestration and hardware management suite. This project is a personal initiative designed to automate environment hardening, scheduled hardware power-on, and virtualized infrastructure deployment on **Ubuntu 24.04 (Noble Numbat)**.

## 🌟 Overview

`System Sentinel` acts as a programmable "Guardian" for your workstation. It bridges the gap between hardware and software by scheduling BIOS wake-up events and ensuring the host machine is fully prepared before launching mission-critical environments.



### Key Features
- **Hardware Power Orchestration:** Schedules automatic PC wake-up events using the `rtcwake` engine (S5/Power-off state).
- **Host Hardening:** Executes automated system updates and security upgrades.
- **Dependency Self-Healing:** Detects and installs missing system libraries (specifically `libaio1t64` for modern Linux kernels).
- **Hardware Validation:** Verifies dedicated SSD mount status before initializing virtual disks.
- **Virtualized Workspace:** Launches VMware Workstation with automated VM Power-On and persistent Google Chrome instances.
- **Instant Telemetry:** Real-time status alerts and boot notifications sent via **Telegram Bot API**.

## 📁 Repository Structure
```text
├── sentinel_power_manager.sh  # Hardware RTC wake-up manager
├── system_startup.sh          # Main workspace orchestrator
├── guard_alert.py             # Python notification engine
├── requirements.txt           # Python dependency list
├── .gitignore                 # Security rules (protects credentials)
└── LICENSE                    # MIT License
```

⚙️ Installation & Setup
```bash
1. Prerequisites

# Clone the repository
# ---------------------------------------------------

git clone [https://github.com/MariusVasileMaftei/system-sentinel-automation.git](https://github.com/MariusVasileMaftei/system-sentinel-automation.git)
cd system-sentinel-automation

# Set permissions
chmod +x *.sh

# ---------------------------------------------------

2. Sudoers Configuration (For Automation)
To allow the Power Manager to schedule hardware events without a password prompt, add this to

$ sudo visudo
# ---------------------------------------------------

your_username ALL=(ALL) NOPASSWD: /usr/sbin/rtcwake

# ---------------------------------------------------

3. Environment Variables
Create a .env file:
# ---------------------------------------------------

TELEGRAM_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# ---------------------------------------------------

4 OS Integration(Autostart)

cat <<EOF > ~/.config/autostart/system_startup.desktop
[Desktop Entry]
Type=Application
Exec=gnome-terminal --title="Sentinel Boot" -- bash -c "sudo $SCRIPT_DIR/system_startup.sh; exec bash"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Sentinel Orchestrator
Comment=Start VMware and Chrome Orchestration
Icon=utilities-terminal
EOF

```

🛠️ Technical Insights
 - RTC Wake-up Logic: Utilizes UTC time conversion to synchronize the OS clock with the motherboard RTC.
 - Process Persistence: Employs nohup and disown to ensure the workspace remains active after the orchestrator exits.
 - X11 Display: Configured DISPLAY=:0 to ensure GUI applications spawn correctly from automation scripts.



