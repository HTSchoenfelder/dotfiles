#! /usr/bin/env bash

title=$(playerctl -p spotify metadata title)
artist=$(playerctl  -p spotify metadata artist)
iconUrl=$(playerctl  -p spotify metadata mpris:artUrl)
curl -o /tmp/currenttrack $iconUrl

notify-send -t 2000 -i /tmp/currenttrack "${title}" "${artist}"
