#!/usr/bin/env bash

file="$HOME/.config/hypr/launcher-data/snippets.txt"

if [[ ! -f "$file" ]]; then
  echo "The file $file does not exist."
  exit 1
fi

chosen=$(awk -F'|' '{print $0}' "$file" | tofi --prompt-text "Snippet:")

if [[ -z "$chosen" ]]; then
  exit 0
fi

snippet=$(awk -F'|' -v output="$chosen" '$0 ~ output {print $1}' "$file")

wtype -d 50 "$snippet"
