#!/bin/bash
read -p "Enter network (ex: 192.168.1.0/24): " net
nmap -sn "$net"

