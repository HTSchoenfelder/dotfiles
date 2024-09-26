#! /usr/bin/env bash

pkill -x firefox
firefox --createprofile "defaultprofile $HOME/.mozilla/firefox/defaultprofile"
firefox --no-remote -P "defaultprofile" --new-instance "about:profiles"