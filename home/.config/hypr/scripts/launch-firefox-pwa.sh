#! /usr/bin/env bash

# Check if an app name is provided
if [ -z "$1" ]; then
  echo "Please provide the app name as an argument."
  exit 1
fi

APP_NAME="$1"

# Search for the App ID based on the app name and the URL in the profile list
APP_ID=$(firefoxpwa profile list | grep -A 1 "$APP_NAME" | grep "https" | awk -F'[()]' '{print $2}')

# Check if an App ID was found
if [ -z "$APP_ID" ]; then
  echo "App with name \"$APP_NAME\" was not found."
  exit 1
fi

# Launch the PWA
echo "Launching the app \"$APP_NAME\" with ID $APP_ID..."
firefoxpwa site launch "$APP_ID"
