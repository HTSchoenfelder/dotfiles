#!/bin/bash

nohup google-chrome --profile-directory="Default" &> /dev/null &
disown

nohup google-chrome --profile-directory="Profile 1" &> /dev/null &
disown

nohup google-chrome --profile-directory="Profile 2" &> /dev/null &
disown

nohup google-chrome --profile-directory="Profile 3" &> /dev/null &
disown

code /home/henrik
code /home/henrik/files
code /home/henrik/dotfiles

. /home/henrik/files/launch-projects.sh