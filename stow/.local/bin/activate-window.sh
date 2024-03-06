#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <shortCode>"
    exit 1
fi

value=$(jq -r --arg key "$1" '.[$key]' "${HOME}/files/window-shortcuts.json")

if [ -z "$value" ]; then
    exit 1
fi

echo "Activating window with title: $value"

gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /de/lucaswerkmeister/ActivateWindowByTitle \
    --method de.lucaswerkmeister.ActivateWindowByTitle.activateBySubstring \
    "'$value'"