#!/bin/bash
read -p "Enter interface (ex: wlan0): " iface
sudo tshark -i "$iface"

