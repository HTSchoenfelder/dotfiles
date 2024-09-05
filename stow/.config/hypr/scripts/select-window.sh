#!/bin/bash
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 5000 "rgb(ff1ea3)" "select-window"
if [ "$#" -eq 4 ]; then
    window=$1
    class=$2
    workspaceId=$3
    specialWorkspaceName=$4    
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window> <class> <workSpaceId> <specialWorkspaceName>"
    hyprctl notify -1 5000 "rgb(ff1ea3)" "$window $class $workspaceId $specialWorkspaceName"
    exit 1
fi

addresses=$(hyprctl clients -j | jq -r ".[] | select(.class | test(\"$class\")) | .address")
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 3000 "rgb(ff1ea3)" "Found Windows: $addresses"
if [ -z "$addresses" ]
then
    hyprctl notify -1 3000 "rgb(ff1ea3)" "No Windows found!"
    exit
fi

for address in $addresses
do
    hyprctl dispatch movetoworkspacesilent "special:${specialWorkspaceName},address:${address}"
done
[[ "$NOTIFY" == "true" ]] && hyprctl notify -1 3000 "rgb(ff1ea3)" "Moved windows to workspace $workspaceId $window"
hyprctl dispatch movetoworkspace "$workspaceId,$window"
