create_v2ray_user() {
    clear
    IP=$(get_ipv4)
    DOMAIN=$(cat /etc/v2ray/domain 2>/dev/null || echo "$IP")
    UUID=$(uuidgen)
    
    read -p "Enter Client Name / Remark : " client_name
    read -p "Enter Active Days (e.g. 30): " days

    if [[ -z "$client_name" ]]; then client_name="ZaidiUser"; fi
    
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        days=30
    fi

    exp_date=$(date -d "+$days days" +"%Y-%m-%d")

    if ! command -v jq &> /dev/null; then
        apt update && apt install -y jq &>/dev/null
    fi

    XRAY_CONFIG="/usr/local/etc/xray/config.json"
    if [ -f "$XRAY_CONFIG" ]; then
        tmp=$(mktemp)
        jq --arg uuid "$UUID" '.inbounds[0].settings.clients += [{"id": $uuid}] | .inbounds[1].settings.clients += [{"id": $uuid, "alterId": 0}]' "$XRAY_CONFIG" > "$tmp" && mv "$tmp" "$XRAY_CONFIG"
        systemctl restart xray 2>/dev/null
    fi

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
  "tls": ""
}
EOF
)
    VMESS_443_LINK="vmess://$(echo -n "$VMESS_443_JSON" | base64 -w 0)"

    VLESS_443_LINK="vless://${UUID}@${DOMAIN}:443?path=%2Fv2ray&security=none&encryption=none&type=ws#ZAIDI-VLESS443-${client_name}"

    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}      V2RAY CONFIG CREATED SUCCESSFULLY (PORT 443)  ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " ${YELLOW}User Remark   :${NC} ${WHITE}${client_name}${NC}"
    echo -e " ${YELLOW}User ID (UUID):${NC} ${WHITE}${UUID}${NC}"
    echo -e " ${YELLOW}Port          :${NC} ${GREEN}443${NC}"
    echo -e " ${YELLOW}Active Days   :${NC} ${WHITE}${days} Days${NC}"
    echo -e " ${YELLOW}Expired Date  :${NC} ${RED}${exp_date}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VMess (Port 443 WS):${NC}"
    echo -e "${WHITE}${VMESS_443_LINK}${NC}"
    echo -e "${CYAN}----------------------------------------------------${NC}"
    echo -e "${PURPLE}VLESS (Port 443 WS):${NC}"
    echo -e "${WHITE}${VLESS_443_LINK}${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -p "Press Enter to return to main menu..."
}


