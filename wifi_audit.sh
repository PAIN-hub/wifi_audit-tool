#!/bin/bash
# ===============================================
# Wi-Fi Security & SSID Audit Script
# Author: Beelyn Smith (Enhanced & polished)
# ===============================================

# ---------- Colors ----------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ---------- Paths ----------
TIMESTAMP=$(date +%F_%H-%M-%S)
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"
REPORT="${REPORT_DIR}/wifi_audit_report_${TIMESTAMP}.txt"
REPORT_XML="${REPORT_DIR}/wifi_audit_report_${TIMESTAMP}.xml"

# ---------- Utility ----------
err_exit() {
    echo -e "${RED}[!] $1${RESET}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[!] $1${RESET}"
}

info() {
    echo -e "${CYAN}[*] $1${RESET}"
}

success() {
    echo -e "${GREEN}[+] $1${RESET}"
}

# ---------- Dependency Check ----------
need_root() {
    if [ "$EUID" -ne 0 ]; then
        warn "Not running as root → Some features (SSID scan, nmap service detection) may fail."
        echo -e "${YELLOW}Continue anyway? (y/n)${RESET}"
        read -r ans
        [[ "$ans" =~ ^[Yy]$ ]] || exit 1
    fi
}

for cmd in nmap awk ip grep; do
    command -v "$cmd" >/dev/null || err_exit "Missing dependency: $cmd"
done

# ---------- SSID Scan ----------
scan_ssids() {
    info "Scanning for Wi-Fi networks (SSIDs)..."
    echo -e "\n==== Detected Wi-Fi Networks (SSIDs) ====" >> "$REPORT"

    if command -v nmcli >/dev/null; then
        nmcli -t -f SSID,SECURITY,SIGNAL dev wifi \
        | awk -F: 'NF>=1 && $1!="" {printf "SSID: %-30s Security: %-10s Signal: %s\n", $1, $2, $3}' \
        | tee -a "$REPORT"
    elif command -v iwlist >/dev/null; then
        IFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)
        [[ -z "$IFACE" ]] && IFACE="wlan0"
        iwlist "$IFACE" scanning 2>/dev/null | grep -E "ESSID|Encryption|Quality" | sed 's/^\s*//g' | tee -a "$REPORT"
    else
        warn "No Wi-Fi scanning tool (nmcli or iwlist) found. Skipping SSID scan."
    fi
}

# ---------- Interactive Scan ----------
choose_scan_options() {
    local target=$1
    echo -e "\n${GREEN}[ Scan Options for $target ]${RESET}"
    echo "1) Quick Scan (common ports)"
    echo "2) Full Scan (all ports)"
    echo "3) Service Version Detection"
    echo "4) Weak Service Check (FTP, Telnet, SMB)"
    echo "5) Deep Scan (-A OS detection + vuln scripts)"
    echo
    read -p "Choose: " opt
    read -p "Use -Pn (bypass ping)? [y/n]: " pn
    [[ "$pn" =~ ^[Yy]$ ]] && PNPARAM="-Pn" || PNPARAM=""

    case $opt in
        1) nmap $PNPARAM -T4 "$target" | tee -a "$REPORT" ;;
        2) nmap $PNPARAM -p- -T4 "$target" | tee -a "$REPORT" ;;
        3) nmap $PNPARAM -sV "$target" | tee -a "$REPORT" ;;
        4) nmap $PNPARAM -p 21,23,445 "$target" | tee -a "$REPORT" ;;
        5) nmap $PNPARAM -A "$target" | tee -a "$REPORT" ;;
        *) warn "Invalid choice." ;;
    esac
}

# ---------- Network Scan ----------
scan_subnet() {
    local SUBNET=$1
    info "Scanning Subnet: $SUBNET"

    echo "==== Wi-Fi Security Audit Report ====" > "$REPORT"
    echo "Generated on: $(date)" >> "$REPORT"
    echo "Target Subnet: $SUBNET" >> "$REPORT"
    echo "=====================================" >> "$REPORT"

    # Step 1: Live hosts
    success "Finding live hosts..."
    nmap -sn $SUBNET -oG - | awk '/Up$/{print $2}' > live_hosts.txt
    if [ ! -s live_hosts.txt ]; then
        err_exit "No live hosts found."
    fi
    echo -e "\nLive Hosts:" | tee -a "$REPORT"
    cat live_hosts.txt | tee -a "$REPORT"

    # Step 2: Interactive scans
    for host in $(cat live_hosts.txt); do
        echo -e "\n--- $host ---" | tee -a "$REPORT"
        choose_scan_options "$host"
    done

    rm -f live_hosts.txt

    success "Audit Complete. Report saved as $REPORT"
    echo "XML output also available at $REPORT_XML"
}

# ---------- Menu ----------
menu() {
    echo -e "\n${GREEN}[ Wi-Fi Audit Menu ]${RESET}"
    echo "1) Scan Wi-Fi SSIDs"
    echo "2) Auto-detect subnet & scan"
    echo "3) Enter custom subnet"
    echo "4) Exit"
    echo
    read -p "Choose: " CHOICE
}

# ---------- Main ----------
need_root
while true; do
    menu
    case $CHOICE in
        1) scan_ssids ;;
        2)
            GATEWAY=$(ip route | grep default | awk '{print $3}')
            SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n1)
            info "Default Gateway: $GATEWAY"
            info "Detected Subnet: $SUBNET"
            scan_subnet "$SUBNET"
            ;;
        3)
            read -p "Enter subnet (e.g. 192.168.1.0/24): " CUSTOM_SUBNET
            if [[ "$CUSTOM_SUBNET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$ ]]; then
                scan_subnet "$CUSTOM_SUBNET"
            else
                err_exit "Invalid subnet format."
            fi
            ;;
        4)
            warn "Exiting..."
            exit 0
            ;;
        *)
            err_exit "Invalid choice."
            ;;
    esac
done