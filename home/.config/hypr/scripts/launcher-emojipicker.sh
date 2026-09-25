#! /usr/bin/env bash

# Select an emoji with Rofi.
chosen=$(cat $HOME/.config/hypr/launcher-data/emoji.txt | rofi -dmenu -i -no-custom -p "" | awk '{print $1}')

# Exit if none chosen.
[ -z "$chosen" ] && exit

echo $chosen
# Type the chosen emoji.
wtype $chosen
