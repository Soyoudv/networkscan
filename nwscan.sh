#!/usr/bin/env bash
set -e

base="192.168."

ping_ip(){
    # echo "pinging $ip"
    if ping -c 2 -W 0.6 $ip >/dev/null 2>&1; then
        echo "$ip reached"
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