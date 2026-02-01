#!/bin/bash
read -p "Enter interface (ex: wlan0): " iface
sudo tcpdump -i "$iface"

