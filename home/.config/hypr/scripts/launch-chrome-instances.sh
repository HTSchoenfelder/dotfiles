#! /usr/bin/env bash

nohup google-chrome-stable --force-dark-mode --profile-directory="Default" &> /dev/null &
disown
sleep 1

nohup google-chrome-stable --force-dark-mode --profile-directory="Profile 1" &> /dev/null &
disown
sleep 1

nohup google-chrome-stable --force-dark-mode --profile-directory="Profile 2" &> /dev/null &
disown
sleep 1

nohup google-chrome-stable --force-dark-mode --profile-directory="Profile 3" &> /dev/null &
disown