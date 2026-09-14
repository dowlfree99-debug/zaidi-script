#!/bin/bash

# Definition of Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- LICENSE PROTECTION SYSTEM ---
VALID_KEY="ZAIDI-VIP-2026"

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${PURPLE}           ZAIDI SCRIPT PROTECTION SYSTEM          ${NC}"
echo -e "${CYAN}====================================================${NC}"
read -p " Enter your License Key to continue: " USER_KEY

if [[ "$USER_KEY" != "$VALID_KEY" ]]; then
    echo -e "${RED}[!] Access Denied! Invalid License Key.${NC}"
    echo -e "${YELLOW}Contact Support: https://t.me/ZAIDIOFFCIEL_FREE${NC}"
    exit 1
fi

echo -e "${GREEN}[✔] Access Granted! Loading Panel...${NC}"
sleep 2

# Get Public IPv4 Address
get_ipv4() {
    IP=$(curl -4 -s --connect-timeout 5 ifconfig.me || curl -4 -s --connect-timeout 5 api.ipify.org || wget -qO- -t 1 -T 5 icanhazip.com || echo "N/A")
    echo "$IP"
}

# Count Online Users
get_online_users() {
    SSH_USERS=$(netstat -tnpa 2>/dev/null | grep -E 'sshd|dropbear' | grep ESTABLISHED | wc -l)
    XRAY_USERS=$(netstat -tnpa 2>/dev/null | grep -E 'xray|v2ray' | grep ESTABLISHED | wc -l)
    TOTAL_USERS=$((SSH_USERS + XRAY_USERS))
    echo "$TOTAL_USERS"
}

# Display Panel Header
show_header() {
    clear
    IP=$(get_ipv4)
    DOMAIN=$(cat /etc/v2ray/domain 2>/dev/null || echo "$IP")
    ONLINE=$(get_online_users)
    
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${PURPLE}               ZAIDI SCRIPT VIP PANEL               ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " ${YELLOW}IP Server  :${NC} ${WHITE}$IP${NC}"
    echo -e " ${YELLOW}Domain     :${NC} ${WHITE}$DOMAIN${NC}"
    echo -e " ${YELLOW}Online     :${NC} ${GREEN}$ONLINE Users Connected${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    
    if systemctl is-active --quiet ssh; then SSH_STATUS="${GREEN}ON${NC}"; else SSH_STATUS="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet stunnel4; then TLS_STATUS="${GREEN}ON${NC}"; else TLS_STATUS="${RED}OFF${NC}"; fi
    if systemctl is-active --quiet xray; then V2RAY_STATUS="${GREEN}ON${NC}"; else V2RAY_STATUS="${RED}OFF${NC}"; fi

    echo -e " ${WHITE}SSH:${NC} $SSH_STATUS | ${WHITE}STUNNEL/TLS:${NC} $TLS_STATUS | ${WHITE}V2RAY/XRAY:${NC} $V2RAY_STATUS"
    echo -e "${CYAN}====================================================${NC}"
}

# Add/Change Domain Name
set_domain() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}               SET / CHANGE DOMAIN                  ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p " Enter your domain name (e.g. sub.domain.com): " user_domain
    if [[ -n "$user_domain" ]]; then
        mkdir -p /etc/v2ray
        echo "$user_domain" > /etc/v2ray/domain
        echo -e "${GREEN}[✔] Domain updated successfully to: $user_domain${NC}"
    else
        echo -e "${RED}[!] Domain cannot be empty.${NC}"
    fi
    sleep 2
}

# Setup SSH & Dropbear Banner
setup_banner() {
    GREEN_TEXT=$(echo -e "\033[1;32mWelcome ZAIDI VPN\033[0m")
    cat <<EOF > /etc/banner
====================================================
               $GREEN_TEXT
====================================================
 Join Our Telegram Channel: https://t.me/ZAIDIOFFCIEL_FREE
====================================================
EOF

    sed -i '/^Banner/d' /etc/ssh/sshd_config
    echo "Banner /etc/banner" >> /etc/ssh/sshd_config

    if [ -f /etc/default/dropbear ]; then
        sed -i 's|DROPBEAR_BANNER=".*"|DROPBEAR_BANNER="/etc/banner"|g' /etc/default/dropbear
    fi

    systemctl restart ssh dropbear 2>/dev/null
}

# Install Core Dependencies & Official Xray
install_services() {
    echo -e "${YELLOW}[+] Updating system packages and installing services...${NC}"
    apt update && apt upgrade -y
    apt install -y curl wget unzip dropbear stunnel4 net-tools uuid-runtime jq

    setup_banner

    # Install Official Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    # Create Initial Xray Configuration
    mkdir -p /usr/local/etc/xray
    cat << 'EOF' > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/v2ray"
        }
      }
    },
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/v2ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-ssl]
accept = 8443
connect = 127.0.0.1:22
EOF

    openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=MA/ST=ZAIDI/L=ZAIDI/O=ZAIDI/OU=ZAIDI/CN=zaidi"
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    
    ufw allow 80/tcp 2>/dev/null
    ufw allow 443/tcp 2>/dev/null
    ufw allow 8443/tcp 2>/dev/null

    systemctl restart stunnel4
    systemctl enable xray
    systemctl restart xray

    echo -e "${GREEN}[✔] Installation completed successfully!${NC}"
    read -p "Press Enter to continue..."
}

# Create SSH + TLS User
create_ssh_user() {
    clear
    IP=$(get_ipv4)
    DOMAIN=$(cat /etc/v2ray/domain 2>/dev/null || echo "$IP")

    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}               CREATE SSH + TLS USER                ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p " Enter Username                : " username
    read -p " Enter Password                : " password
    read -p " Enter Active Days (e.g. 30)   : " days
    read -p " Enter Max Connection Limit    : " max_limit

    if [[ -z "$username" || -z "$password" || -z "$days" ]]; then
        echo -e "${RED}[!] Username, Password and Days are required!${NC}"
        sleep 2
        return
    fi

    exp_date=$(date -d "+$days days" +"%Y-%m-%d")

    useradd -M -s /bin/false -e "$exp_date" "$username"
    echo "$username:$password" | chpasswd

    if [[ -n "$max_limit" ]]; then
        echo "$username hard maxsyslogins $max_limit" >> /etc/security/limits.conf
        echo "$username hard maxlogins $max_limit" >> /etc/security/limits.conf
    else
        max_limit="Unlimited"
    fi

    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}        SSH ACCOUNT CREATED SUCCESSFULLY            ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " ${YELLOW}Host / IP     :${NC} ${WHITE}$DOMAIN${NC} (${WHITE}$IP${NC})"
    echo -e " ${YELLOW}Username      :${NC} ${WHITE}$username${NC}"
    echo -e " ${YELLOW}Password      :${NC} ${WHITE}$password${NC}"
    echo -e " ${YELLOW}Port SSH Direct:${NC} ${WHITE}22, 109${NC}"
    echo -e " ${YELLOW}Port Dropbear :${NC} ${WHITE}80, 143${NC}"
    echo -e " ${YELLOW}Port SSL / TLS:${NC} ${WHITE}443, 8443${NC}"
    echo -e " ${YELLOW}Active Days   :${NC} ${WHITE}$days Days${NC}"
    echo -e " ${YELLOW}Expired Date  :${NC} ${RED}$exp_date${NC}"
    echo -e " ${YELLOW}Max Devices   :${NC} ${GREEN}$max_limit Devices${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e " ${PURPLE}Telegram Channel:${NC} ${WHITE}https://t.me/ZAIDIOFFCIEL_FREE${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p "Press Enter to return to main menu..."
}

# Create V2Ray & Trojan Config
create_v2ray_user() {
    clear
    IP=$(get_ipv4)
    DOMAIN=$(cat /etc/v2ray/domain 2>/dev/null || echo "$IP")
    UUID=$(uuidgen)
    read -p "Enter Client Name / Remark : " client_name
    read -p "Enter Active Days (e.g. 30): " days

    if [[ -z "$client_name" ]]; then client_name="ZaidiUser"; fi
    if [[ -z "$days" ]]; then days="30"; fi

    exp_date=$(date -d "+$days days" +"%Y-%m-%d")

    # Add UUID to Xray config if file exists
    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    if [ -f "$XRAY_CONFIG" ]; then
        tmp=$(mktemp)
        jq --arg uuid "$UUID" '.inbounds[0].settings.clients += [{"id": $uuid, "alterId": 0}] | .inbounds[1].settings.clients += [{"id": $uuid}]' "$XRAY_CONFIG" > "$tmp" && mv "$tmp" "$XRAY_CONFIG"
        systemctl restart xray 2>/dev/null
    fi

    VMESS_80_JSON=$(cat <<EOF
{
  "v": "2",
  "ps": "ZAIDI-WS80-${client_name}",
  "add": "${DOMAIN}",
  "port": "80",
  "id": "${UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${DOMAIN}",
  "path": "/v2ray",
  "tls": ""
}
EOF
)
    VMESS_80_LINK="vmess://$(echo -n "$VMESS_80_JSON" | base64 -w 0)"

    VMESS_443_JSON=$(cat <<EOF
{
  "v": "2",
  "ps": "ZAIDI-WS443-${client_name}",
  "add": "${DOMAIN}",
  "port": "443",
  "id": "${UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${DOMAIN}",
  "path": "/v2ray",
  "tls": "tls"
}
EOF
)
    VMESS_443_LINK="vmess://$(echo -n "$VMESS_443_JSON" | base64 -w 0)"

    VLESS_80_LINK="vless://${UUID}@${DOMAIN}:80?path=%2Fv2ray&security=none&encryption=none&type=ws#ZAIDI-VLESS80-${client_name}"
    VLESS_443_LINK="vless://${UUID}@${DOMAIN}:443?path=%2Fv2ray&security=tls&encryption=none&type=ws&sni=${DOMAIN}#ZAIDI-VLESS443-${client_name}"

    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}      V2RAY / TROJAN CONFIG CREATED SUCCESSFULLY   ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " ${YELLOW}User Remark   :${NC} ${WHITE}${client_name}${NC}"
    echo -e " ${YELLOW}User ID (UUID):${NC} ${WHITE}${UUID}${NC}"
    echo -e " ${YELLOW}Active Days   :${NC} ${WHITE}${days} Days${NC}"
    echo -e " ${YELLOW}Expired Date  :${NC} ${RED}${exp_date}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VMess (Port 80 WS):${NC}"
    echo -e "${WHITE}${VMESS_80_LINK}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VMess (Port 443 WS TLS):${NC}"
    echo -e "${WHITE}${VMESS_443_LINK}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VLESS (Port 80 WS):${NC}"
    echo -e "${WHITE}${VLESS_80_LINK}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VLESS (Port 443 WS TLS):${NC}"
    echo -e "${WHITE}${VLESS_443_LINK}${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p "Press Enter to return to main menu..."
}

# Renew & Restart Services
renew_services() {
    echo -e "${YELLOW}[+] Renewing and restarting all SSH & V2Ray services...${NC}"
    setup_banner
    systemctl restart ssh dropbear stunnel4 xray 2>/dev/null
    sleep 1
    echo -e "${GREEN}[✔] SSH & V2Ray services renewed successfully!${NC}"
    sleep 2
}

# Interactive Main Menu
main_menu() {
    show_header
    echo -e " ${CYAN}[01]${NC} ${WHITE}Install & Setup All Services${NC}"
    echo -e " ${CYAN}[02]${NC} ${WHITE}Add / Change Domain Name${NC}"
    echo -e " ${CYAN}[03]${NC} ${WHITE}Create SSH + TLS User (Limit & Expiry)${NC}"
    echo -e " ${CYAN}[04]${NC} ${WHITE}Create V2Ray / Trojan Config (Expiry)${NC}"
    echo -e " ${CYAN}[05]${NC} ${WHITE}Renew & Restart All Services (SSH/V2Ray)${NC}"
    echo -e " ${RED}[00]${NC} ${WHITE}Exit Panel${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p " Select an option [0-5]: " option

    case $option in
        1) install_services; main_menu ;;
        2) set_domain; main_menu ;;
        3) create_ssh_user; main_menu ;;
        4) create_v2ray_user; main_menu ;;
        5) renew_services; main_menu ;;
        0) echo -e "${GREEN}Exiting... Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}[!] Invalid option, try again.${NC}"; sleep 1; main_menu ;;
    esac
}

main_menu
