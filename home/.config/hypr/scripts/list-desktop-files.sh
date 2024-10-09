#! /usr/bin/env bash

DESKTOP_DIRS=("$HOME/.local/share/applications" "/usr/share/applications" "/run/current-system/sw/share/applications/")

for dir in "${DESKTOP_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    #  echo $dir
     ls $dir | grep .desktop
  fi
done
