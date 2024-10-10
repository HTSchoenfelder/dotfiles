#! /usr/bin/env bash

# Get user selection via tofi from emoji file.
chosen=$(cat $HOME/.config/hypr/launcher-data/emoji.txt | tofi --prompt-text "select: " | awk '{print $1}')

# Exit if none chosen.
[ -z "$chosen" ] && exit

echo $chosen
# Type the chosen emoji.
wtype $chosen

