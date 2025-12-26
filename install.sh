#!/bin/bash
# HAMID Tunnel Installer & Manager
# Ubuntu 22+ | TCP Reverse Tunnel

clear
cat << "EOF"
│      ██╗  ██╗ █████╗ ███╗   ███╗██╗   ██╗       │
│      ██║  ██║██╔══██╗████╗ ████║██║   ██║       │
│      ███████║███████║██╔████╔██║██║   ██║       │
│      ██╔══██║██╔══██║██║╚██╔╝██║██║   ██║       │
│      ██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝       │
│      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝        │
│           HAMID Tunnel                         │
EOF

echo "Version: 1.0"
echo "-----------------------------------------"

TUNNELS_DIR="/etc/hamid-tunnels"
mkdir -p "$TUNNELS_DIR"

# Function to create tunnel
setup_tunnel() {
    read -p "[*] Enter tunnel name (e.g., HAMID-tunnel): " TUNNEL_NAME
    read -p "Select server location: 1) Iran 2) Outside: " SERVER_LOC
    read -p "Select tunnel type: 1) TCP Direct 2) TCP Reverse: " TUNNEL_TYPE
    read -p "[*] Enter tunnel port (e.g., 443): " TUNNEL_PORT
    echo "[*] Using TCP_NODELAY: true"
    read -p "[*] Enter server IPv4 address: " SERVER_IP

    SERVICE_FILE="/etc/systemd/system/HAMID-${TUNNEL_NAME}.service"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=HAMID Tunnel $TUNNEL_NAME
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ssh -N -R ${TUNNEL_PORT}:localhost:${TUNNEL_PORT} ${SERVER_IP}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "HAMID-${TUNNEL_NAME}.service"
    systemctl start "HAMID-${TUNNEL_NAME}.service"

    echo "Tunnel $TUNNEL_NAME created and started successfully!"
}

# Function to manage tunnels
manage_tunnels() {
    echo "Available tunnels:"
    systemctl list-units --type=service | grep HAMID | awk '{print $1}' | nl
    read -p "Enter number to manage tunnel (0 to return): " CHOICE
    if [[ "$CHOICE" -eq 0 ]]; then return; fi
    TUNNEL=$(systemctl list-units --type=service | grep HAMID | awk '{print $1}' | sed -n "${CHOICE}p")
    clear
    echo "Manage Tunnel: $TUNNEL"
    echo "1) Start tunnel"
    echo "2) Stop tunnel"
    echo "3) Restart tunnel"
    echo "4) Check tunnel status"
    echo "5) Set cron job for tunnel restart"
    echo "0) Return"
    read -p "Enter choice: " ACTION
    case $ACTION in
        1) systemctl start "$TUNNEL"; echo "Tunnel started." ;;
        2) systemctl stop "$TUNNEL"; echo "Tunnel stopped." ;;
        3) systemctl restart "$TUNNEL"; echo "Tunnel restarted." ;;
        4) systemctl status "$TUNNEL" ;;
        5)
            (crontab -l 2>/dev/null; echo "@reboot systemctl restart $TUNNEL") | crontab -
            echo "Cron job set for tunnel restart at boot."
            ;;
        0) return ;;
        *) echo "Invalid option." ;;
    esac
}

while true; do
    echo "-----------------------------------------"
    echo "1) Setup new tunnel"
    echo "2) Manage tunnels"
    echo "3) Exit"
    read -p "Enter choice: " MAIN_CHOICE

    case $MAIN_CHOICE in
        1) setup_tunnel ;;
        2) manage_tunnels ;;
        3) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice." ;;
    esac
done
