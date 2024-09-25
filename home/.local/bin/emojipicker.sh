#!/bin/bash

# Get user selection via tofi from emoji file.
chosen=$(cat $HOME/dotfiles/misc/emoji.txt | tofi --prompt-text select | awk '{print $1}')

# Exit if none chosen.
[ -z "$chosen" ] && exit

# Type the chosen emoji.
wtype -d 50 $chosen