#! /usr/bin/env bash

on_workspace_changed() {
    VISIBLE_SPECIAL_WORKSPACE=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name' | grep special 2>/dev/null)
    echo "VISIBLE_SPECIAL_WORKSPACE: $VISIBLE_SPECIAL_WORKSPACE"
    if [[ -n "$VISIBLE_SPECIAL_WORKSPACE" ]]; then
        hyprctl dispatch togglespecialworkspace code-terminal
        echo "Toggle special workspace"
    fi
}

on_monitor_added() {
    hyprctl notify 0 1000 0 "Monitor added"
}

handle() {
    case $1 in
    monitoraddedv2*) on_monitor_added ;;
    workspacev2*) on_workspace_changed ;;
    esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
