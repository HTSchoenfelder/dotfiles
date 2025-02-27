#! /usr/bin/env bash

title=$(playerctl -p spotify_player metadata title)
artist=$(playerctl  -p spotify_player metadata artist)
iconUrl=$(playerctl  -p spotify_player metadata mpris:artUrl)
curl -o /tmp/currenttrack $iconUrl

notify-send -t 2000 -i /tmp/currenttrack "${title}" "${artist}"
