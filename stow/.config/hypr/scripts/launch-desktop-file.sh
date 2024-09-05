#!/bin/bash

# Name of the application to launch
APP_NAME="$1"

# Directories to search for .desktop files
DESKTOP_DIRS=("$HOME/.local/share/applications" "/usr/share/applications")

# Function to search for the application and launch it using Hyprland exec-once
launch_application() {
    local app_name="$1"

    for dir in "${DESKTOP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            for desktop_file in "$dir"/*.desktop; do
                # Check if the desktop file contains the correct application name
                if grep -q "Name=$app_name" "$desktop_file"; then
                    # Extract the filename without path and extension
                    desktop_filename=$(basename "$desktop_file" .desktop)
                    # Use Hyprland exec-once with gtk-launch
                    echo "Starting $app_name using Hyprland exec-once with $desktop_filename..."
                    hyprctl dispatch exec "gtk-launch $desktop_filename" &
                    exit 0
                fi
            done
        fi
    done

    echo "Application \"$app_name\" not found."
    exit 1
}

# Check if an application name was provided
if [ -z "$APP_NAME" ]; then
    echo "Usage: $0 \"Application Name\""
    exit 1
fi

# Launch the application
launch_application "$APP_NAME"