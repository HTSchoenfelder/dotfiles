#!/usr/bin/env bash

file="$HOME/.config/hypr/launcher-data/snippets.txt"

if [[ ! -f "$file" ]]; then
  echo "The file $file does not exist."
  exit 1
fi

chosen=$(awk -F'|' '{print $0}' "$file" | wofi --show dmenu --insensitive --prompt "paste")

if [[ -z "$chosen" ]]; then
  exit 0
fi

snippet=$(awk -F'|' -v output="$chosen" '$0 ~ output {print $1}' "$file")
snippet=$(echo "$snippet" | sed 's/\\n/\n/g')
wtype "$snippet"
