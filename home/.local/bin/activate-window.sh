#!/bin/bash

shortcutsFile="${HOME}/files/window-shortcuts.json"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <shortCode>"
    exit 1
fi

shortcut=$(jq -c --arg key "$1" '.[] | select(.Key==$key)' "${HOME}/files/window-shortcuts.json")

if [ -z "$shortcut" ]; then
    echo "No matching shortcut found for key: $1"
    exit 1
fi

echo "Found shortcut: "
jq . <<<"$shortcut"

value=$(echo "$shortcut" | jq -r '.Value')
type=$(echo "$shortcut" | jq -r '.Type')

function activateBySubstring() {
    local substring=$1

    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /de/lucaswerkmeister/ActivateWindowByTitle \
        --method de.lucaswerkmeister.ActivateWindowByTitle.activateBySubstring \
        "'$substring'"
}

function activateByWmClass() {
    local wmClass=$1

    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /de/lucaswerkmeister/ActivateWindowByTitle \
        --method de.lucaswerkmeister.ActivateWindowByTitle.activateByWmClass \
        "'$wmClass'"
}

function getAllWindows() {
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.List |
        cut -c 3- | rev | cut -c4- | rev | jq .
}

function getTitle() {
    local id=$1
    gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/Windows \
        --method org.gnome.Shell.Extensions.Windows.GetTitle \
        "$id" | cut -c 3- | rev | cut -c4- | rev
}

function getFocusedWindowTitle() {
    gdbus call \
        --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/shell/extensions/FocusedWindow \
        --method org.gnome.shell.extensions.FocusedWindow.Get |
        cut -c 3- | rev | cut -c4- | rev | jq -r '.title'
}

if [ "$type" = "WindowTitle" ]; then
    activateBySubstring "$value"
elif [ "$type" = "WmClass" ]; then
    activateByWmClass "$value"
else
    echo "Unknown type: $type"
    exit 1
fi
