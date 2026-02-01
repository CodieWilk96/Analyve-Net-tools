#!/bin/bash
read -p "Enter wireless interface (ex: wlan0): " iface
sudo airmon-ng start "$iface"
echo
echo "Monitor mode enabled. Use airodump-ng or wifite next."

