#!/bin/bash

# Auto-detect interface
iface=$(ip route | awk '/default/ {print $5}')
subnet=$(ip -o -f inet addr show "$iface" | awk '{print $4}')

echo "Detected interface: $iface"
echo "Detected subnet: $subnet"
echo "Scanning network..."
sleep 1

sudo nmap -sn "$subnet"


