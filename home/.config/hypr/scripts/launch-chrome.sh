#! /usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 \"Profile Name\""
    exit 1
fi

nohup google-chrome-stable --profile-directory="$1" &> /dev/null &
disown

# Wait a moment to ensure the window appears
sleep 2

ADDRESSES=($(hyprctl clients -j | jq -r '.[] | select(.class == "google-chrome" and (.tags | length) == 0) | .address'))

if [ ${#ADDRESSES[@]} -eq 1 ]; then
    ADDRESS=${ADDRESSES[0]}
    TAG=$(echo "$1" | tr -d '[:space:]')
    echo "Tagging Chrome window with address: $ADDRESS and tag: $TAG" 
    hyprctl dispatch tagwindow "+chrome-$TAG" address:"$ADDRESS"
elif [ ${#ADDRESSES[@]} -gt 1 ]; then
    echo "Warning: Multiple untagged Chrome windows detected: ${ADDRESSES[@]}"
    echo "Skipping tagging to avoid incorrect assignments."
else
    echo "No untagged Chrome window found."
fi