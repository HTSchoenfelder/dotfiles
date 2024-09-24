#!/bin/bash

if [ "$#" -eq 1 ]; then
    key=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

window=$(cat "/tmp/window-for-key-${key}")
path=$(echo "$window" | grep -oP '(?<=title:)[^|]*' | xargs)

path="${path/#\~/$HOME}"

if [ ! -d "$path" ] && [ ! -f "$path" ]; then
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Error: Path '$path' does not exist."
    exit 1
fi

code "$path"
