#!/bin/bash

# ========================================
#      TEAM DARK - MAC CHANGER TOOL 
# ========================================

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

print_banner() {
    echo -e "${RED}   ╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}   ║       ______                        ____             __            ║${NC}"
    echo -e "${RED}   ║      /_  __/__  ____ _____ ___     / __ \____ ______/ /__          ║${NC}"
    echo -e "${RED}   ║       / / / _ \/ __ \/ __ \`__ \\   / / / / __ \`/ ___/ //_/          ║${NC}"
    echo -e "${RED}   ║      / / /  __/ /_/ / / / / / /  / /_/ / /_/ / /  / ,<             ║${NC}"
    echo -e "${RED}   ║     /_/  \\___/\\__,_/_/ /_/ /_/  /_____/\\__,_/_/  /_/|_|            ║${NC}"
    echo -e "${RED}   ║                                                                    ║${NC}"
    echo -e "${BLUE}   ║  __  __    _    ____    ____ _   _    _    _   _  ____ _____ ____  ║${NC}"
    echo -e "${BLUE}   ║ |  \\/  |  / \\  / ___|  / ___| | | |  / \\  | \\ | |/ ___| ____|  _ \\ ║${NC}"
    echo -e "${BLUE}   ║ | |\\/| | / _ \\| |     | |   | |_| | / _ \\ |  \\| | |  _|  _| | |_) |║${NC}"
    echo -e "${BLUE}   ║ | |  | |/ ___ \\ |___  | |___|  _  |/ ___ \\| |\\  | |_| | |___|  _ < ║${NC}"
    echo -e "${BLUE}   ║ |_|  |_/_/   \\_\\____|  \\____|_| |_/_/   \\_\\_| \\_|\\____|_____|_| \\_\\║${NC}"
    echo -e "${BLUE}   ║                                                                    ║${NC}"
    echo -e "   ╚════════════════════════════════════════════════════════════════════╝"
    echo ""
}

change_mac() {
    local interface=$1
    echo -e "${YELLOW}[*] Changing MAC for $interface...${NC}"
    
    sudo ip link set $interface down 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR] Could not bring $interface down. Check interface name or permissions.${NC}"
        return 1
    fi
    
    sudo macchanger -l > /tmp/vendor.txt 2>/dev/null
    vendor=$(shuf -n 1 /tmp/vendor.txt | awk '{print $3}')
    prefix=$(printf '%02x:%02x:%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))

    sudo macchanger -m "$vendor:$prefix" $interface
    if [ $? -eq 0 ]; then
        sudo ip link set $interface up 2>/dev/null
        echo -e "${GREEN}[+] MAC changed successfully!${NC}"
        echo -e "${CYAN}[+] New MAC:${NC}"
        ip link show $interface | grep ether
        return 0
    else
        sudo ip link set $interface up 2>/dev/null
        echo -e "${RED}[ERROR] Failed to change MAC.${NC}"
        return 1
    fi
}

get_interface() {
    echo -e "${CYAN}[?] Enter network interface (default: wlan0): ${NC}" >&2
    read -r iface
    if [ -z "$iface" ]; then
        iface="wlan0"
    fi
    echo "$iface"
}

trap 'echo -e "\n${YELLOW}[!] Exiting...${NC}"; exit 0' INT

print_banner

INTERFACE=$(get_interface)

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}                  SELECT OPTION${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}1)${NC} Change MAC ${RED}ONCE${NC}"
echo -e "${CYAN}2)${NC} Change MAC ${RED}CONTINUOUSLY${NC} (every X seconds)"
echo -e "${CYAN}3)${NC} ${RED}Exit${NC}"
echo ""
echo -ne "${YELLOW}Enter choice [1-3]: ${NC}"
read -r choice

case $choice in
    1)
        echo ""
        change_mac "$INTERFACE"
        ;;
    2)
        echo ""
        echo -e "${CYAN}[?] Enter time interval (in seconds): ${NC}"
        read -r interval
        if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 1 ]; then
            echo -e "${RED}[ERROR] Invalid interval. Using default 60 seconds.${NC}"
            interval=60
        fi
        echo -e "${GREEN}[+] Will change MAC every $interval seconds. Press Ctrl+C to stop.${NC}"
        echo ""
        while true; do
            change_mac "$INTERFACE"
            echo -e "${YELLOW}[*] Next change in $interval seconds...${NC}"
            sleep "$interval"
        done
        ;;
    3)
        echo -e "${RED}[!] Exiting.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}[ERROR] Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac
