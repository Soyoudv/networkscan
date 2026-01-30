#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
# echo "Running nwscan from dir ${DIR}"

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
        (echo "$ip $macOfThisIp") >> "$STATE_FILE"
    fi
}

main(){ # fonction principale scan le network

    for i in $(seq 0 1); do
        for j in $(seq 0 255); do
            ip="$base"$i"."$j
            ping_ip & # TRUC DE GENIE OMGGGGG
       done
    done

    wait

    # convert CACHE file to associative arrays
    while read -r line; do
        ip=$(echo $line | cut -d' ' -f1)
        mac=$(echo $line | cut -d' ' -f2)
        if [ "$mac" != "0" ] && [ "$mac" != "1" ]; then # appel de l'api uniquement quand on a une mac valide
            mac_part=${mac//:/}}
            mac_part=${mac_part:0:6}
            mac_part=${mac_part^^} # uppercase
            # echo "searching vendor for $mac_part in $DIR/ieee-oui.txt"

            vendor=$(cat "$DIR/ieee-oui.txt" | grep "$mac_part" | head -n 1 | awk -F'\t' '{ print $2 }') # lookup in local OUI file, take the full vendor $2 and more
            # echo "vendor for $mac is $vendor"

            if [ "$vendor" != "{\"errors\":{\"detail\":\"Not Found\"}}" ]; then
                ip_vendor_map[$ip]=$vendor # assignation au tableau associatif
            else
                ip_vendor_map[$ip]="Unknown Vendor"
            fi
        fi
        ip_mac_map[$ip]=$mac
        sleep 0.6 # to avoid being rate limited by macvendors API
    done < "$STATE_FILE"

    # affichage:
    for ip in "${!ip_mac_map[@]}"; do
        mac=${ip_mac_map[$ip]}
        if [ "$mac" = 1 ]; then
            echo -e "$ip\tyour device"
        else if [ "$mac" = 0 ]; then
            echo -e "$ip\tno MAC found"
        else
            if [ "${ip_vendor_map[$ip]}" ]; then
                echo -e "$ip\t$mac\t${ip_vendor_map[$ip]}"
            else
                echo -e "$ip\t$mac\tUnknown Vendor"
            fi
        fi fi
    done
    echo "nombre d'éléments trouvés: ${#ip_mac_map[@]}"
}
main "$@"