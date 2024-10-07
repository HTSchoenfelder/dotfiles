#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
    key=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

chosen=$(hyprctl clients -j | jq -r '.[].title' | tofi)

[ -z "$chosen" ] && exit

window="title:${chosen}"
echo "$window" > "/tmp/window-for-key-${key}"