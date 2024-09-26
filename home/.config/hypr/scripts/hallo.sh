#! /usr/bin/env bash
hyprctl notify -1 5000 "rgb(ff1ea3)" "hallo"
[[[ "$NOTIFY" == "true" ]]] && hyprctl notify -1 5000 "rgb(ff1ea3)" "hallo ${NOTIFY}"