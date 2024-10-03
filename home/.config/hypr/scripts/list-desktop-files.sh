#! /usr/bin/env bash

DESKTOP_DIRS=("$HOME/.local/share/applications" "/usr/share/applications" "/run/current-system/sw/share/applications/")

for dir in "${DESKTOP_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    for desktop_file in "$dir"/*.desktop; do
      echo "$desktop_file"
    done
  fi
done
