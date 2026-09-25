#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
    title=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <window>"
    exit 1
fi

chosen=$( \
    hyprctl clients -j \
    | jq -r '. | sort_by(.focusHistoryID) | .[].title' \
    | grep "${title}" \
    | rofi -dmenu -i -no-custom -p "" \
    | xargs \
    | sed 's/[.|\\-]/\\&/g' \
    )

[ -z "$chosen" ] && exit

window="title:${chosen}"
echo "window:${window}"

if [ -z "${title}" ]; then
  hyprctl dispatch focuswindow "$window"
else
  $HOME/.config/hypr/scripts/focus-code-window.sh "$window"
fi