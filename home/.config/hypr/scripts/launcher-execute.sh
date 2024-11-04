#!/usr/bin/env bash

file="$HOME/.config/hypr/launcher-data/execute.txt"

if [[ ! -f "$file" ]]; then
  echo "The file $file does not exist."
  exit 1
fi

chosen=$(awk -F'|' '{print $2}' "$file" | wofi --show dmenu --insensitive --prompt "execute")

if [[ -z "$chosen" ]]; then
  exit 0
fi

command=$(awk -F'|' -v output="$chosen" '$2 ~ output {print $1}' "$file")

# Execute the command
if [[ -n "$command" ]]; then
  eval "$command"
else
  echo "No corresponding command found."
fi
