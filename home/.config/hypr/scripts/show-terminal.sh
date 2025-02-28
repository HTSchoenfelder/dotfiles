#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
    COMMAND=$1
else
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <monitor>"
    exit 1
fi

CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [[ $CLASS == "code" ]]; then
    PROJECT=$(hyprctl activewindow -j | jq -r '.title' | sed 's/ | Code//')
    TERMINAL_EXISTS=$(hyprctl clients -j | jq -r '.[].class' | grep "code-terminal-$PROJECT-$COMMAND")
    if [[ -z $TERMINAL_EXISTS ]]; then
        hyprctl dispatch exec "kitty --class code-terminal-$PROJECT-$COMMAND --title \"$PROJECT | Terminal\" --working-directory $PROJECT $COMMAND"
    else
        hyprctl dispatch focuswindow "class:code-terminal-$PROJECT-$COMMAND"
    fi
elif [[ $CLASS == "code-terminal-"* ]]; then
    hyprctl dispatch togglespecialworkspace code-terminal
else
    hyprctl notify 0 1000 0 "Active window is not a VS Code window"
fi
