#!/usr/bin/env bash
set -e

base="192.168."

myIp=$(hostname -I | awk '{print $1}')

ping_ip(){
    # echo "pinging $ip"
    macOfThisIp=$(arp -n $ip | awk '/..:..:..:..:..:../ {print $3}')
    if [ "$ip" == "$myIp" ]; then
        macOfThisIp="you"
    fi
    if ping -c 2 -W 0.6 $ip >/dev/null 2>&1; then
        echo "$ip : $macOfThisIp"
    fi
}

scan(){
    for i in $(seq 0 1); do
        for j in $(seq 0 255); do
            ip="$base"$i"."$j
            ping_ip & # TRUC DE GENIE OMGGGGG
       done
    done
}

scan
sleep 2