#!/bin/bash

echo "Starting airodump-ng..."
read -p "Enter monitor-mode interface (ex: wlan0mon): " iface

sudo airodump-ng "$iface"

