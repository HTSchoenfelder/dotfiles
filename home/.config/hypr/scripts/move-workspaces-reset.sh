#!/usr/bin/env bash

if [ "$#" -eq 1 ]; then
    monitor=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <monitor>"
    exit 1
fi

for i in {1..20}; do
    if [ "$i" -eq 10 ]; then
        continue
    fi
    hyprctl dispatch moveworkspacetomonitor "$i" "$monitor"
done
