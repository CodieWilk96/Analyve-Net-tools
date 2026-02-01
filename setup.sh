#!/usr/bin/env bash

echo "======================================"
echo "     Network Toolkit Installer"
echo "======================================"
echo

REQUIRED_TOOLS=(
    dig
    traceroute
    fping
    arp-scan
    nmap
    curl
    whois
    nc
    smbclient
    macchanger
)

echo "[*] Updating package lists..."
sudo apt update -y

echo
echo "[*] Installing required tools..."
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Installing $tool..."
        sudo apt install -y "$tool"
    else
        echo "$tool already installed."
    fi
done

echo
echo "[*] Creating config directory..."
mkdir -p "$HOME/.network-toolkit"
touch "$HOME/.network-toolkit/custom_commands.txt"

echo
echo "[*] Installing system-wide launcher..."
sudo bash -c "cat > /usr/local/bin/toolkit" <<EOF
#!/bin/bash

CUSTOM_CMD_FILE="\$HOME/.network-toolkit/custom_commands.txt"

shortcut="\$1"

if [[ -z "\$shortcut" ]]; then
    echo "Usage: toolkit <shortcut>"
    exit 1
fi

cmd=\$(grep "^\\\$shortcut|" "\$CUSTOM_CMD_FILE" | cut -d'|' -f2-)

if [[ -z "\$cmd" ]]; then
    echo "Custom command '\$shortcut' not found."
    exit 1
fi

eval "\$cmd"
EOF

sudo chmod +x /usr/local/bin/toolkit

echo
echo "[+] Installation complete!"
echo "Run the toolkit with: ./toolkit.sh"
echo "Run custom commands anywhere with: toolkit <shortcut>"
echo

