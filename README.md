# System Sentinel Automation 🛡️

A proactive system orchestration and infrastructure deployment suite. This project was developed as a personal initiative to automate environment hardening, hardware validation, and virtualized infrastructure management on **Ubuntu 24.04 (Noble Numbat)**.

## 🌟 Overview

`System Sentinel` acts as a programmable "Guardian" for your workstation. It ensures that the host machine is updated, critical hardware is mounted, and system dependencies are resolved before launching mission-critical virtual environments.

[Image of a professional DevOps automation workflow showing system updates, hardware checks, and service deployment]

### Key Features
- **Host Hardening:** Automatically executes `sudo apt update` and `upgrade` to ensure the host OS is secure.
- **Dependency Self-Healing:** Detects and installs missing system libraries (specifically `libaio1t64` for modern Linux kernels).
- **Hardware Validation:** Verifies the availability of dedicated SSD storage before initializing virtual disks.
- **Virtualized Environment Orchestration:** Launches VMware Workstation in GUI mode with automated Power-On.
- **Instant Telemetry:** Real-time status alerts sent via **Telegram Bot API** using a custom Python notification engine.

## 📁 Repository Structure
```text
├── guard_alert.py      # Python notification engine
├── system_startup.sh   # Main Bash orchestrator
├── requirements.txt    # Python dependency list
├── LICENSE             # MIT License
└── .gitignore          # Security rules (protects credentials)

## ⚙️ Installation & Setup

### 1. Clone & Dependencies
```bash
# Clone the repository
git clone [https://github.com/MariusVasileMaftei/system-sentinel-automation.git](https://github.com/MariusVasileMaftei/system-sentinel-automation.git)
cd system-sentinel-automation

# Install system dependencies
sudo apt update && sudo apt install python3-requests python3-dotenv libaio1t64
chmod +x system_startup.sh

2. Configuration (Local Only)
Create a .env file (this is ignored by Git):
TELEGRAM_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

🛠️ Technical Insights
- Library Conflict: Resolved libaio hang by targeting libaio1t64.
- X11 Forwarding: Fixed GUI spawning by exporting DISPLAY=:0.
- Stability: Utilized vmware -x for resilient automated boots.



