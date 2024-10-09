#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
    window=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

class="code-url-handler"
addresses=$(hyprctl clients -j | jq -r ".[] | select(.class | test(\"$class\")) | .address")
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 3000 "rgb(ff1ea3)" "Found Windows: $addresses"
if [ -z "$addresses" ]
then
    hyprctl notify -1 3000 "rgb(ff1ea3)" "No Windows found!"
    exit
fi

for address in $addresses
do
    hyprctl dispatch movetoworkspacesilent "11,address:${address}"
done

hyprctl dispatch movetoworkspace "2,$window"
