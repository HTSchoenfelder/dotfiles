#! /usr/bin/env bash

if [ "$#" -ne 1 ]; then
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <command>"
    exit 1
fi

COMMAND=$1
ACTIVE_WINDOW_INFO=$(hyprctl activewindow -j)
CLASS=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.class')
TITLE=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.title')
PROJECT=$(echo "$TITLE" | sed 's/ | Code//')

if [[ $CLASS == "code" ]]; then
    TARGET_CLASS="code-terminal-$PROJECT-$COMMAND"
elif [[ $CLASS == code-terminal-* ]]; then
    PROJECT=$(echo "$CLASS" | sed 's/code-terminal-\(.*\)-.*/\1/')
    TARGET_CLASS="code-terminal-$PROJECT-$COMMAND"
else
    hyprctl notify 0 1000 0 "Active window is not a VS Code window or associated terminal"
    exit 1
fi

EXISTING_TERMINAL=$(hyprctl clients -j | jq -r '.[].class' | grep "$TARGET_CLASS")

if [[ -z $EXISTING_TERMINAL ]]; then
    hyprctl dispatch exec "kitty --class $TARGET_CLASS --title \"$PROJECT | Terminal\" --working-directory $PROJECT $COMMAND"
elif [[ $CLASS == "$TARGET_CLASS" ]]; then
    hyprctl dispatch togglespecialworkspace code-terminal
else
    hyprctl dispatch focuswindow "class:$TARGET_CLASS"
fi
