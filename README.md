## 🔐 Wi-Fi Security Audit Tool

A bash-based Wi-Fi security auditing script that scans your own network for weak spots.  
It automates SSID discovery, subnet detection, host discovery, and weak service checks — all in a colorful, user-friendly CLI.

> ⚠️ Disclaimer  
> This tool is strictly for educational and legal use only.  
> Run it only on networks you own or have explicit permission to test.  
> Unauthorized scanning of other networks may violate the law.

---

## 🖥️ Environment / Requirements

**This script is designed to run on Linux (desktop/server).**  
It *can* run on Android via **Termux**, but **only on rooted devices** with the required packages installed. Termux environments are limited — some features (low-level Wi-interface scans, `iwlist`, `nmcli`, and certain `nmap` options) may not work or behave differently.

Minimum requirements:
- A Linux system or Termux on a **rooted** Android device.
- `sudo` / root privileges for full functionality (SSID scans, ARP scans, some nmap flags).
- Installed packages: `nmap`, `awk`, `ip` (iproute2), `grep`, and either `nmcli` or `iwlist` for SSID scanning.
- Optional: `xsltproc` for HTML report generation from Nmap XML.

### Quick Termux notes (rooted device)
If you plan to run in Termux (you must be rooted for full features):

``` pkg update && pkg upgrade ```

``` pkg install nmap tsu grep procps-ng busybox ```

 tsu or su required to escalate privileges to root if available
 iwlist/nmcli may not be available or functional on many Android devices

Then run the script with root:

``` tsu -c "./wifi_audit.sh" ```   # or use sudo/su if configured

> ⚠️ Termux + non-root = limited or non-functional SSID/subnet discovery and ARP-level scans.


## ✨ Features

✅ Root privilege check

✅ Dependency verification (nmap, awk, ip, grep, nmcli/iwlist)

✅ SSID scanning (via nmcli, fallback to iwlist)

✅ Subnet auto-detection or manual input

✅ Interactive scan options:

Quick Scan (common ports)

Full Scan (all ports)

Service Version Detection

Weak Service Check (FTP, Telnet, HTTP, etc.)

Deep Scan (-A OS detection + vuln scripts)


✅ Nmap -Pn support (bypass hosts blocking ping)

✅ Saves timestamped reports under reports/


## 🚀 Installation

Clone the repo and make the script executable:

``` git clone https://github.com/PAIN-hub/wifi_audit-tool.git```

```cd wifi_audit-tool```

```chmod +x wifi_audit.sh```

## 🛠️ Usage

Run with root privileges:

```sudo ./wifi_audit.sh```

# Example Flow:

1. Pick a network (SSID).


2. Let the script auto-detect your subnet or enter manually.


3. Choose scan type (Quick, Full, Service, Weak, Deep).


4. Results are saved in reports/scan_report_<timestamp>.txt.



If using Termux on Android, run from a rooted shell (see Termux notes above). Non-root Termux will likely produce incomplete results.



📂 Project Structure

wifi-audit-tool/
├── wifi_audit.sh
├── reports/
└── README.md


---

📜 License

MIT License — Use freely but don’t be a skid. Credit if you fork or reuse.
