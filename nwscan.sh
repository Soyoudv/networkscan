#!/usr/bin/env bash
set -e

base="192.168."

myIp=$(ip route get 192.168.0.1 | grep -oP '(?<=src )[\d.]+')
usedInterface=$(ip route get 192.168.0.1 | grep -oP '(?<=dev )[\w]+')


STATE_FILE="$HOME/.cache/nwscan_state"
mkdir -p "$(dirname "$STATE_FILE")" #ensure state file directory exists
: > "$STATE_FILE" # reset state file // : because > alone can fail if noclobber is set

declare -A ip_mac_map # tableau associatif pour stocker IP, MAC et Constructeurs
declare -A ip_vendor_map # tableau associatif pour stocker IP, et Constructeurs de la MAC associée

ping_ip(){
    macOfThisIp=$(arp -n $ip -i $usedInterface 2>/dev/null | awk '/..:..:..:..:..:../ {print $3}')
    if [ "$ip" == "$myIp" ]; then
        macOfThisIp="1" # ma propre MAC
    else    
        if [ -z "$macOfThisIp" ]; then
        macOfThisIp="0" # pas de MAC trouvée
        fi
    fi

    if ping -c 2 -W 0.6 $ip >/dev/null 2>&1; then
        echo "write to state: $ip $macOfThisIp"
        (echo "$ip $macOfThisIp") >> "$STATE_FILE"
    fi
}

scan_network(){

    for i in $(seq 0 1); do
        for j in $(seq 0 255); do
            ip="$base"$i"."$j
            ping_ip & # TRUC DE GENIE OMGGGGG
       done
    done

    wait
    cat "$STATE_FILE"
}

scan_network