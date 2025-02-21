#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 '<command>'"
    exit 1
fi

hyprctl dispatch submap reset
hyprctl keyword general:border_size 2

COMMAND=$1
eval "$COMMAND"
