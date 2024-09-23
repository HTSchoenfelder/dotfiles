#!/bin/bash

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
                    return 0
                fi
            done
        fi
    done

    echo "Application \"$app_name\" not found."
    return 1
}

# Check if at least one application name was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 \"Application Name 1\" \"Application Name 2\" ..."
    exit 1
fi

# Launch each application provided as a parameter
for APP_NAME in "$@"; do
    launch_application "$APP_NAME"
    # Wait for 5 seconds before launching the next application
    sleep 5
done
