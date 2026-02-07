#!/usr/bin/env bash

#######################################
# Network Toolkit - Core Script
# - Main menu
# - Terminal tools (custom-command friendly)
# - GUI tools placeholders
# - Settings
#######################################

############################
# Color configuration
############################
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

############################
# Paths and globals
############################
CONFIG_DIR="${HOME}/.network-toolkit"
LOG_DIR="${CONFIG_DIR}/logs"
CUSTOM_CMD_FILE="${CONFIG_DIR}/custom_commands.txt"
DEFAULT_NET_IFACE=""
DEFAULT_WLAN_IFACE=""
COLOR_THEME="light"  # placeholder toggle
DATA_DIR="${CONFIG_DIR}/data"
AUDIT_REPORT="${DATA_DIR}/security_audit.txt"
AUDIT_XML="${DATA_DIR}/audit_nmap.xml"
HTTP_AUDIT_REPORT="${DATA_DIR}/http_security_audit.txt"
HOST_DEEP_XML="${DATA_DIR}/host_deep_scan.xml"
HOST_DEEP_REPORT="${DATA_DIR}/host_deep_scan.txt"
DNS_HEALTH_REPORT="${DATA_DIR}/dns_health_check.txt"


mkdir -p "${LOG_DIR}"

############################
# Helper functions
############################
print_banner() {
    clear
    echo -e "${CYAN}==============================${RESET}"
    echo -e "${BOLD}      Network Toolkit${RESET}"
    echo -e "${CYAN}==============================${RESET}"
}

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

log_file() {
    local prefix="$1"
    local ts
    ts="$(date +"%Y%m%d-%H%M%S")"
    echo "${LOG_DIR}/${prefix}-${ts}.log"
}

detect_default_interface() {
    # Try to detect primary interface via default route
    local iface
    iface="$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')"
    if [[ -n "$iface" ]]; then
        DEFAULT_NET_IFACE="$iface"
    fi
}

detect_default_wlan_interface() {
    # Try to detect wireless interface via iw
    local iface
    iface="$(iw dev 2>/dev/null | awk '/Interface/ {print $2; exit}')"
    if [[ -n "$iface" ]]; then
        DEFAULT_WLAN_IFACE="$iface"
    fi
}

ensure_config() {
    [[ -d "${CONFIG_DIR}" ]] || mkdir -p "${CONFIG_DIR}"
    [[ -f "${CUSTOM_CMD_FILE}" ]] || touch "${CUSTOM_CMD_FILE}"
    [[ -d "${DATA_DIR}" ]] || mkdir -p "${DATA_DIR}"
} 

print_status() {
    echo -e "${YELLOW}[*]${RESET} $*"
}

print_ok() {
    echo -e "${GREEN}[+]${RESET} $*"
}

print_error() {
    echo -e "${RED}[-]${RESET} $*"
}

############################
# Terminal tools (12 core)
############################
terminal_dns_lookup() {
    print_banner
    echo -e "${BOLD}DNS Lookup${RESET}"
    echo
    read -rp "Enter domain or host: " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file "dns_lookup")"
    print_status "Running: dig ${target}"
    echo "Command: dig ${target}" | tee -a "${log}"
    echo | tee -a "${log}"
    dig "${target}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_reverse_dns() {
    print_banner
    echo -e "${BOLD}Reverse DNS Lookup${RESET}"
    echo
    read -rp "Enter IP address: " ip
    [[ -z "$ip" ]] && { print_error "IP cannot be empty."; pause; return; }

    local log
    log="$(log_file "reverse_dns")"
    print_status "Running: dig -x ${ip}"
    echo "Command: dig -x ${ip}" | tee -a "${log}"
    echo | tee -a "${log}"
    dig -x "${ip}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_ping_sweep() {
    print_banner
    echo -e "${BOLD}Ping Sweep${RESET}"
    echo
    read -rp "Enter subnet (e.g. 192.168.0.0/24): " subnet
    [[ -z "$subnet" ]] && { print_error "Subnet cannot be empty."; pause; return; }

    local log
    log="$(log_file "ping_sweep")"
    print_status "Running ping sweep on ${subnet}"
    echo "Ping sweep on ${subnet}" | tee -a "${log}"
    echo | tee -a "${log}"

    # Simple fping-based sweep if available, else fallback
    if command -v fping >/dev/null 2>&1; then
        fping -a -g "${subnet}" 2>&1 | tee -a "${log}"
    else
        # crude fallback: use nmap -sn
        if command -v nmap >/dev/null 2>&1; then
            nmap -sn "${subnet}" 2>&1 | tee -a "${log}"
        else
            print_error "Neither fping nor nmap found; cannot perform ping sweep."
        fi
    fi

    print_ok "Results saved to ${log}"
    pause
}

terminal_traceroute() {
    print_banner
    echo -e "${BOLD}Traceroute${RESET}"
    echo
    read -rp "Enter target host/IP: " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file "traceroute")"
    print_status "Running traceroute to ${target}"
    echo "Command: traceroute ${target}" | tee -a "${log}"
    echo | tee -a "${log}"
    traceroute "${target}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_arp_scan() {
    print_banner
    echo -e "${BOLD}ARP Scan${RESET}"
    echo
    read -rp "Enter subnet (e.g. 192.168.0.0/24): " subnet
    [[ -z "$subnet" ]] && { print_error "Subnet cannot be empty."; pause; return; }

    local log
    log="$(log_file "arp_scan")"
    print_status "Running arp-scan on ${subnet}"
    echo "Command: arp-scan ${subnet}" | tee -a "${log}"
    echo | tee -a "${log}"
    if command -v arp-scan >/dev/null 2>&1; then
        sudo arp-scan "${subnet}" 2>&1 | tee -a "${log}"
    else
        print_error "arp-scan not installed."
    fi
    print_ok "Results saved to ${log}"
    pause
}

terminal_nmap_scan() {
    print_banner
    echo -e "${BOLD}Nmap Scan${RESET}"
    echo
    read -rp "Enter target (host or subnet): " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file 'nmap_scan')"
    print_status "Running: nmap -sV ${target}"
    echo "Command: nmap -sV ${target}" | tee -a "${log}"
    echo | tee -a "${log}"
    nmap -sV "${target}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_port_scan_light() {
    print_banner
    echo -e "${BOLD}Lightweight Port Scan${RESET}"
    echo
    read -rp "Enter target host/IP: " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file 'port_scan')"
    print_status "Running: nmap -p 1-1000 ${target}"
    echo "Command: nmap -p 1-1000 ${target}" | tee -a "${log}"
    echo | tee -a "${log}"
    nmap -p 1-1000 "${target}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_http_headers() {
    print_banner
    echo -e "${BOLD}HTTP Header Fetcher${RESET}"
    echo
    read -rp "Enter URL (e.g. http://example.com): " url
    [[ -z "$url" ]] && { print_error "URL cannot be empty."; pause; return; }

    local log
    log="$(log_file 'http_headers')"
    print_status "Running: curl -I ${url}"
    echo "Command: curl -I ${url}" | tee -a "${log}"
    echo | tee -a "${log}"
    curl -I "${url}" 2>&1 | tee -a "${log}"
    print_ok "Results saved to ${log}"
    pause
}

terminal_whois_lookup() {
    print_banner
    echo -e "${BOLD}WHOIS Lookup${RESET}"
    echo
    read -rp "Enter domain or IP: " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file 'whois')"
    print_status "Running: whois ${target}"
    echo "Command: whois ${target}" | tee -a "${log}"
    echo | tee -a "${log}"
    if command -v whois >/dev/null 2>&1; then
        whois "${target}" 2>&1 | tee -a "${log}"
    else
        print_error "whois not installed."
    fi
    print_ok "Results saved to ${log}"
    pause
}

terminal_nc_banner_grab() {
    print_banner
    echo -e "${BOLD}Netcat Banner Grab${RESET}"
    echo
    read -rp "Enter target host/IP: " target
    read -rp "Enter port: " port
    [[ -z "$target" || -z "$port" ]] && { print_error "Target and port required."; pause; return; }

    local log
    log="$(log_file 'nc_banner')"
    print_status "Running: nc -v ${target} ${port}"
    echo "Command: nc -v ${target} ${port}" | tee -a "${log}"
    echo | tee -a "${log}"
    if command -v nc >/dev/null 2>&1; then
        echo | nc -v "${target}" "${port}" 2>&1 | tee -a "${log}"
    else
        print_error "nc (netcat) not installed."
    fi
    print_ok "Results saved to ${log}"
    pause
}

terminal_smb_enum() {
    print_banner
    echo -e "${BOLD}SMB Enumeration${RESET}"
    echo
    read -rp "Enter target host/IP: " target
    [[ -z "$target" ]] && { print_error "Target cannot be empty."; pause; return; }

    local log
    log="$(log_file 'smb_enum')"
    print_status "Running: smbclient -L //${target} -N"
    echo "Command: smbclient -L //${target} -N" | tee -a "${log}"
    echo | tee -a "${log}"
    if command -v smbclient >/dev/null 2>&1; then
        smbclient -L "//${target}" -N 2>&1 | tee -a "${log}"
    else
        print_error "smbclient not installed."
    fi
    print_ok "Results saved to ${log}"
    pause
}

terminal_mac_vendor_lookup() {
    print_banner
    echo -e "${BOLD}MAC Vendor Lookup${RESET}"
    echo
    read -rp "Enter MAC address (e.g. 00:11:22:33:44:55): " mac
    [[ -z "$mac" ]] && { print_error "MAC cannot be empty."; pause; return; }

    local log
    log="$(log_file 'mac_vendor')"
    print_status "Attempting MAC vendor lookup"
    echo "MAC: ${mac}" | tee -a "${log}"
    echo | tee -a "${log}"

    # If macchanger is installed, use its vendor DB
    if command -v macchanger >/dev/null 2>&1; then
        macchanger -l 2>/dev/null | grep -i "^${mac:0:8}" 2>&1 | tee -a "${log}"
    else
        print_error "macchanger not installed; vendor lookup may not be available."
    fi

    print_ok "Results saved to ${log}"
    pause
}

wireless_dashboard() {
    print_banner
    echo -e "${BOLD}Wireless Dashboard${RESET}"
    echo

    local iface="${DEFAULT_WLAN_IFACE}"

    if [[ -z "$iface" ]]; then
        print_error "No wireless interface detected."
        pause
        return
    fi

    echo -e "${CYAN}Interface:${RESET}        $iface"

    # Mode (managed/monitor)
    local mode
    mode="$(iw dev "$iface" info 2>/dev/null | awk '/type/ {print $2}')"
    echo -e "${CYAN}Mode:${RESET}            ${mode:-unknown}"

    # MAC Address
    local mac
    mac="$(cat /sys/class/net/"$iface"/address 2>/dev/null)"
    echo -e "${CYAN}MAC Address:${RESET}     ${mac:-unknown}"

    # Channel
    local channel
    channel="$(iw dev "$iface" info 2>/dev/null | awk '/channel/ {print $2}')"
    echo -e "${CYAN}Channel:${RESET}         ${channel:-unknown}"

    # SSID (if connected)
    local ssid
    ssid="$(iw dev "$iface" link 2>/dev/null | awk -F': ' '/SSID/ {print $2}')"
    echo -e "${CYAN}SSID:${RESET}            ${ssid:-not connected}"

    # Signal strength
    local signal
    signal="$(iw dev "$iface" link 2>/dev/null | awk '/signal/ {print $2}')"
    echo -e "${CYAN}Signal:${RESET}          ${signal:-N/A}"

    echo
    pause
}

terminal_ping_sweep_auto() {
    local subnet="$1"
    local out="${DATA_DIR}/ping_last.txt"

    print_status "Running automated ping sweep on ${subnet}"
    if command -v fping >/dev/null 2>&1; then
        fping -a -g "${subnet}" 2>/dev/null | tee "${out}"
    else
        nmap -sn "${subnet}" 2>/dev/null | tee "${out}"
    fi
    print_ok "Ping sweep results saved to ${out}"
}

terminal_arp_scan_auto() {
    local subnet="$1"
    local out="${DATA_DIR}/arp_last.txt"

    print_status "Running automated ARP scan on ${subnet}"
    if command -v arp-scan >/dev/null 2>&1; then
        sudo arp-scan "${subnet}" 2>/dev/null | tee "${out}"
    else
        print_error "arp-scan not installed."
    fi
    print_ok "ARP scan results saved to ${out}"
}

terminal_nmap_scan_auto() {
    local target="$1"
    local out="${DATA_DIR}/nmap_last.xml"

    print_status "Running automated Nmap scan on ${target}"
    nmap -sV "${target}" -oX "${out}" 2>/dev/null
    print_ok "Nmap XML results saved to ${out}"
}

full_recon() {
    print_banner
    echo -e "${BOLD}Full Recon Automation${RESET}"
    echo

    read -rp "Enter subnet for recon (e.g. 192.168.1.0/24): " subnet
    [[ -z "$subnet" ]] && { print_error "Subnet required."; pause; return; }

    # 1. Ping Sweep
    terminal_ping_sweep_auto "$subnet"

    # 2. ARP Scan
    terminal_arp_scan_auto "$subnet"

    # 3. Nmap Scan (use subnet or a single host)
    terminal_nmap_scan_auto "$subnet"

    # 4. Auto-launch Zenmap if available
    if command -v zenmap >/dev/null 2>&1; then
        print_status "Launching Zenmap with scan results..."
        xdg-open "$HOST_DEEP_XML" &
    else
        print_error "Zenmap not installed."
    fi
        
    pause
}

protocol_security_audit() {
	print_banner
	echo -e "${BOLD}Protocol Security Audit${RESET}"
	echo
	echo "Scan a single host or an entire subnet?"
	echo "1) Single host"
	echo "2) Subnet"
	echo
	read -rp "Select an option (1-2): " mode

	local target
	case "$mode" in
		1)
			read -rp "Enter host (e.g. 192.168.1.10): " target
			;;
		2)
			read -rp "Enter subnet (e.g. 192.168.1.0/24): " target
			;;
		*)
			print_error "Invalid option."
			pause
			return
			;;
	esac

	 -z "$target"  && { print_error "Target required."; pause; return; }

	print_status "Running Nmap vulnerability and version scan..."
	nmap -sV --script vuln "$target" -oX "$AUDIT_XML" > /dev/null 2>&1

	print_ok "Scan complete. Parsing results..."
	sleep 1

	# Start building the report
	{
		echo "======================================"
		echo "      Protocol Security Audit"
		echo "======================================"
		echo "Target: $target"
		echo "Date: $(date)"
		echo
		echo "========== SUMMARY =========="
	} > "$AUDIT_REPORT"

	# Summary section
	if grep -qi "vuln" "$AUDIT_XML"; then
		echo "- Potential vulnerabilities detected" >> "$AUDIT_REPORT"
	else
		echo "- No major vulnerabilities detected" >> "$AUDIT_REPORT"
	fi

	# Weak protocol checks
	echo >> "$AUDIT_REPORT"
	echo "Weak or Insecure Protocols:" >> "$AUDIT_REPORT"

	declare -A weak_protocols=(
		["Telnet"]="23"
		["FTP"]="21"
		["HTTP (no TLS)"]="80"
		["SMBv1"]="445"
		["RSH"]="514"
		["SNMP v1/v2"]="161"
		["VNC (unencrypted)"]="5900"
		["RDP"]="3389"
	)

	for proto in "${!weak_protocols[@]}"; do
		port="${weak_protocols[$proto]}"
		if grep -q "portid=\"$port\"" "$AUDIT_XML"; then
			echo "- $proto detected on port $port" >> "$AUDIT_REPORT"
		fi
	done

	# Detailed section
	{
		echo
		echo "========== DETAILED FINDINGS =========="
		echo
		echo "Service and Version Information:"
		echo "--------------------------------"
	} >> "$AUDIT_REPORT"

	# Extract service/version info
	xmllint --xpath "port/service/@name | port/service/@version" "$AUDIT_XML" 2>/dev/null \
		| sed 's/name=/\nService: /g; s/version=/ Version: /g' >> "$AUDIT_REPORT"

	{
		echo
		echo "Vulnerability Script Output:"
		echo "--------------------------------"
	} >> "$AUDIT_REPORT"

	# Extract vuln script output
	xmllint --xpath "//script[@id='vuln']" "$AUDIT_XML" 2>/dev/null \
		| sed 's/<[^>]*>//g' >> "$AUDIT_REPORT"

	print_ok "Audit report saved to: $AUDIT_REPORT"

	# Auto-launch Zenmap
	if command -v zenmap >/dev/null 2>&1; then
	    print_status "Launching Zenmap with audit results..."
	    zenmap "$AUDIT_XML" &
	else
		print_error "Zenmap not installed."
	fi

	pause
}

http_security_audit() {
    print_banner
    echo -e "${BOLD}HTTP Security Audit${RESET}"
    echo
    read -rp "Enter target (domain or URL, e.g. https://example.com): " target

    [[ -z "$target" ]] && { print_error "Target required."; pause; return; }

    print_status "Fetching HTTP response headers..."
    # -I = headers only, -L = follow redirects, -k = allow self-signed, -sS = silent but show errors
    headers=$(curl -I -L -k -sS "$target")
    if [[ -z "$headers" ]]; then
        print_error "No headers received. Check connectivity or URL."
        pause
        return
    fi

    mkdir -p "${DATA_DIR}"
    {
        echo "======================================"
        echo "        HTTP Security Audit"
        echo "======================================"
        echo "Target: $target"
        echo "Date:   $(date)"
        echo
        echo "========== RAW HEADERS =========="
        echo "$headers"
        echo
        echo "========== SUMMARY =========="
    } > "$HTTP_AUDIT_REPORT"

    # Helper to check presence of a header
    check_header() {
        local name="$1"
        local pattern="$2"
        if echo "$headers" | grep -qi "^$pattern:"; then
            echo "- $name: PRESENT" >> "$HTTP_AUDIT_REPORT"
        else
            echo "- $name: MISSING" >> "$HTTP_AUDIT_REPORT"
        fi
    }

    check_header "Strict-Transport-Security (HSTS)" "Strict-Transport-Security"
    check_header "Content-Security-Policy (CSP)" "Content-Security-Policy"
    check_header "X-Frame-Options" "X-Frame-Options"
    check_header "X-Content-Type-Options" "X-Content-Type-Options"
    check_header "Referrer-Policy" "Referrer-Policy"
    check_header "Permissions-Policy" "Permissions-Policy"
    check_header "X-XSS-Protection (legacy)" "X-XSS-Protection"

    {
        echo
        echo "========== DETAILS & NOTES =========="
        echo "- HSTS helps enforce HTTPS and prevent downgrade attacks."
        echo "- CSP can mitigate XSS by controlling allowed sources."
        echo "- X-Frame-Options / frame-ancestors help prevent clickjacking."
        echo "- X-Content-Type-Options=nosniff prevents MIME sniffing."
        echo "- Referrer-Policy controls how much referrer info is leaked."
        echo "- Permissions-Policy limits powerful browser features (camera, mic, etc.)."
        echo
        echo "Review the missing headers above and consider adding them on the server."
    } >> "$HTTP_AUDIT_REPORT"

    print_ok "HTTP security audit saved to: $HTTP_AUDIT_REPORT"
    pause
}

host_deep_scan() {
    print_banner
    echo -e "${BOLD}Host Deep Scan${RESET}"
    echo
    read -rp "Enter target host (IP or hostname): " target
    [[ -z "$target" ]] && { print_error "Target required."; pause; return; }

    print_status "Running deep Nmap scan (version, OS, scripts, traceroute)..."
    nmap -A -T4 "$target" -oX "$HOST_DEEP_XML" > /dev/null 2>&1

    if [[ ! -s "$HOST_DEEP_XML" ]]; then
        print_error "Scan failed or produced no output."
        pause
        return
    fi

    {
        echo "======================================"
        echo "            Host Deep Scan"
        echo "======================================"
        echo "Target: $target"
        echo "Date:   $(date)"
        echo
        echo "========== SUMMARY =========="
    } > "$HOST_DEEP_REPORT"

    # Basic summary: up/down and open ports count
    up=$(xmllint --xpath "string(//host/status/@state)" "$HOST_DEEP_XML" 2>/dev/null)
    echo "- Host state: ${up:-unknown}" >> "$HOST_DEEP_REPORT"

    open_ports=$(xmllint --xpath "count(//port[state/@state='open'])" "$HOST_DEEP_XML" 2>/dev/null)
    echo "- Open ports: ${open_ports:-0}" >> "$HOST_DEEP_REPORT"

    {
        echo
        echo "========== SERVICES =========="
        echo
    } >> "$HOST_DEEP_REPORT"

    xmllint --xpath "//port[state/@state='open']" "$HOST_DEEP_XML" 2>/dev/null \
        | sed 's/<port /\n<port /g' \
        | sed -n 's/.*portid=\"\([0-9]*\)\" protocol=\"\([a-z]*\)\".*/Port \1 (\2):/p' >> "$HOST_DEEP_REPORT"

    {
        echo
        echo "========== OS & EXTRA INFO =========="
        echo
    } >> "$HOST_DEEP_REPORT"

    xmllint --xpath "string(//os/osmatch[1]/@name)" "$HOST_DEEP_XML" 2>/dev/null \
        | sed 's/^/Detected OS: /' >> "$HOST_DEEP_REPORT"

    {
        echo
        echo
        echo "========== RAW NMAP DETAILS =========="
        echo "For full details, open this XML in Zenmap or a viewer:"
        echo "$HOST_DEEP_XML"
    } >> "$HOST_DEEP_REPORT"

    print_ok "Host deep scan report saved to: $HOST_DEEP_REPORT"

    if command -v zenmap >/dev/null 2>&1; then
        print_status "Launching Zenmap with host deep scan results..."
        xdg-open "$HOST_DEEP_XML" &
    else
        print_error "Zenmap not installed."
    fi

    pause
}

dns_health_check() {
    print_banner
    echo -e "${BOLD}DNS Health Check${RESET}"
    echo
    read -rp "Enter domain (e.g. example.com): " domain
    [[ -z "$domain" ]] && { print_error "Domain required."; pause; return; }

    print_status "Running DNS queries..."

    {
        echo "======================================"
        echo "           DNS Health Check"
        echo "======================================"
        echo "Domain: $domain"
        echo "Date:   $(date)"
        echo
        echo "========== SUMMARY =========="
    } > "$DNS_HEALTH_REPORT"

    {
        echo
        echo "A / AAAA Records:"
        echo "-----------------"
        dig +short A "$domain"
        dig +short AAAA "$domain"

        echo
        echo "MX Records:"
        echo "-----------"
        dig +short MX "$domain"

        echo
        echo "NS Records:"
        echo "-----------"
        dig +short NS "$domain"

        echo
        echo "SOA Record:"
        echo "-----------"
        dig +short SOA "$domain"

        echo
        echo "Reverse Lookup (if applicable):"
        echo "-------------------------------"
        ip=$(dig +short A "$domain" | head -n1)
        if [[ -n "$ip" ]]; then
            dig +short -x "$ip"
        else
            echo "No A record found; reverse lookup skipped."
        fi

        echo
        echo "DNSSEC Status:"
        echo "--------------"
        dig +dnssec +short "$domain" | grep -qi "RRSIG" && echo "DNSSEC: PRESENT" || echo "DNSSEC: NOT DETECTED"

        echo
        echo "Notes:"
        echo "------"
        echo "- Ensure MX and NS records point to valid, reachable servers."
        echo "- Consider enabling DNSSEC if not present."
        echo "- Verify SOA values (serial, refresh, retry, expire) match your DNS policy."
    } >> "$DNS_HEALTH_REPORT"

    print_ok "DNS health report saved to: $DNS_HEALTH_REPORT"
    pause
}

############################
# Wireless Tools Menu
############################
wireless_tools_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Wireless Tools${RESET}"
        echo
        echo "1) Airmon-ng"
        echo "2) Airodump-ng"
        echo "3) Aircrack-ng"
        echo "4) Wifite"
        echo "5) Horst"
        echo "6) WiFi Analyzer"
        echo "7) Wireless Dashboard"
        echo "8) Back to Main Menu"
        echo
        read -rp "Select an option (1-8): " choice

        case "$choice" in
            1) bash "$(dirname "$0")/modules/airmon.sh" ;;
            2) bash "$(dirname "$0")/modules/airodump.sh" ;;
            3) bash "$(dirname "$0")/modules/aircrack.sh" ;;
            4) bash "$(dirname "$0")/modules/wifite.sh" ;;
            5) bash "$(dirname "$0")/modules/horst.sh" ;;
            6) bash "$(dirname "$0")/modules/wifi_analyzer.sh" ;;
            7) wireless_dashboard ;;
	    8) break ;;
            *) print_error "Invalid option."; sleep 1 ;;
        esac
    done
}

############################
# Terminal tools menu
############################
terminal_tools_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Terminal Tools (Custom-command friendly)${RESET}"
        echo
        echo " 1) DNS Lookup"
        echo " 2) Reverse DNS Lookup"
        echo " 3) Ping Sweep"
        echo " 4) Traceroute"
        echo " 5) ARP Scan"
        echo " 6) Nmap Scan"
        echo " 7) Lightweight Port Scan"
        echo " 8) HTTP Header Fetcher"
        echo " 9) WHOIS Lookup"
        echo "10) Netcat Banner Grab"
        echo "11) SMB Enumeration"
        echo "12) MAC Vendor Lookup"
        echo "13) Back to Main Menu"
        echo
        read -rp "Select an option (1-13): " choice

        case "$choice" in
            1) terminal_dns_lookup ;;
            2) terminal_reverse_dns ;;
            3) terminal_ping_sweep ;;
            4) terminal_traceroute ;;
            5) terminal_arp_scan ;;
            6) terminal_nmap_scan ;;
            7) terminal_port_scan_light ;;
            8) terminal_http_headers ;;
            9) terminal_whois_lookup ;;
            10) terminal_nc_banner_grab ;;
            11) terminal_smb_enum ;;
            12) terminal_mac_vendor_lookup ;;
            13) break ;;
            *) print_error "Invalid option."; sleep 1 ;;
        esac
    done
}

############################
# GUI tools menu (placeholders)
############################
gui_tools_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}GUI Tools${RESET}"
        echo
        echo "1) Launch Wireshark"
        echo "2) Launch Zenmap"
        echo "3) Launch Kismet"
        echo "4) Open Logs Directory in File Manager"
        echo "5) Back to Main Menu"
        echo
        read -rp "Select an option (1-5): " choice

        case "$choice" in
            1)
                if command -v wireshark >/dev/null 2>&1; then
                    print_status "Launching Wireshark..."
                    wireshark &
                else
                    print_error "Wireshark not installed."
                    pause
                fi
                ;;
            2)
                if command -v zenmap >/dev/null 2>&1; then
                    print_status "Launching Zenmap..."
                    zenmap &
                else
                    print_error "Zenmap not installed."
                    pause
                fi
                ;;
            3)
                if command -v kismet >/dev/null 2>&1; then
                    print_status "Launching Kismet..."
                    kismet &
                else
                    print_error "Kismet not installed."
                    pause
                fi
                ;;
            4)
                if command -v xdg-open >/dev/null 2>&1; then
                    print_status "Opening logs directory..."
                    xdg-open "${LOG_DIR}" &
                else
                    print_error "xdg-open not available."
                    pause
                fi
                ;;
            5) break ;;
            *) print_error "Invalid option."; sleep 1 ;;
        esac
    done
}

############################
# Settings menu
############################
settings_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Settings${RESET}"
        echo
        echo "1) Show Detected Interfaces"
        echo "2) Set Default Network Interface"
        echo "3) Set Default Wireless Interface"
        echo "4) Toggle Color Theme (placeholder)"
        echo "5) Show Logs Directory"
        echo "6) Back to Main Menu"
        echo
        read -rp "Select an option (1-6): " choice

        case "$choice" in
            1)
                print_status "Network interfaces:"
                ip addr show
                echo
                print_status "Wireless interfaces:"
                iw dev 2>/dev/null || echo "No wireless interfaces detected or iw not installed."
                pause
                ;;
            2)
                read -rp "Enter default network interface: " iface
                [[ -n "$iface" ]] && DEFAULT_NET_IFACE="$iface" && print_ok "Default network interface set to ${iface}"
                pause
                ;;
            3)
                read -rp "Enter default wireless interface: " iface
                [[ -n "$iface" ]] && DEFAULT_WLAN_IFACE="$iface" && print_ok "Default wireless interface set to ${iface}"
                pause
                ;;
            4)
                if [[ "$COLOR_THEME" == "light" ]]; then
                    COLOR_THEME="dark"
                else
                    COLOR_THEME="light"
                fi
                print_ok "Color theme toggled (current: ${COLOR_THEME})."
                pause
                ;;
            5)
                echo "Logs directory: ${LOG_DIR}"
                ls -1 "${LOG_DIR}"
                pause
                ;;
            6) break ;;
            *) print_error "Invalid option."; sleep 1 ;;
        esac
    done
}

############################
# Main menu
############################
main_menu() {
    detect_default_interface;
    detect_default_wlan_interface;
    ensure_config;

    while true; do
        print_banner
        echo "Default network interface : ${DEFAULT_NET_IFACE:-unset}"
        echo "Default wireless interface: ${DEFAULT_WLAN_IFACE:-unset}"
        echo
	echo "1) Terminal Tools"
	echo "2) Wireless Tools"
	echo "3) GUI Tools"
	echo "4) Settings"
	echo "5) Exit"
	echo "6) Advanced Options"
        echo
        read -rp "Whats your desired option? (1-6): " choice

        case "$choice" in
    	    1) terminal_tools_menu ;;
    	    2) wireless_tools_menu ;;
    	    3) gui_tools_menu ;;
    	    4) settings_menu ;;
    	    5) echo "Goodbye."; exit 0 ;;
	    6) advanced_options_menu ;;
   	    *) print_error "Invalid option."; sleep 1 ;;
	esac

    done
}

advanced_options_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}Advanced Options${RESET}"
        echo
        echo "1) Full Recon (Ping → ARP → Nmap → Zenmap)"
        echo "2) Protocol Security Audit"
	echo "3) HTTP Security Audit"
	echo "4) Host Deep Scan"
	echo "5) DNS Health Check"
	echo "6) Back to Main Menu"
        echo
	read -rp "Select an option (1-6): " choice

        case "$choice" in
            1) full_recon ;;
            2) protocol_security_audit ;;
	    3) http_security_audit ;;
	    4) host_deep_scan ;;
	    5) dns_health_check ;;
	    6) return ;;
            *) print_error "Invalid option."; sleep 1 ;;
        esac
    done
}


############################
# Guard: only run menu when executed directly
############################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi

