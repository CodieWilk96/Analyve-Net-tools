#!/bin/bash

source "$(dirname "$0")/../toolkit.sh"

# Use the helper functions from the main script
# (Your main script must source this file or vice versa)

echo "Starting horst..."

# Step 1 — Choose interface
iface=$(choose_interface)
if [ -z "$iface" ]; then
    echo "No interface selected."
    sleep 1
    exit 1
fi

# Step 2 — Enable monitor mode
mon_iface=$(enable_monitor_mode "$iface")
if [ -z "$mon_iface" ]; then
    echo "Failed to enable monitor mode."
    sleep 2
    exit 1
fi

echo "Using monitor interface: $mon_iface"
sleep 1

# Step 3 — Run horst
sudo horst -i "$mon_iface"

# Step 4 — Cleanup
disable_monitor_mode "$mon_iface"

