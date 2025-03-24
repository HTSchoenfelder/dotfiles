#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    hyprctl notify -1 5000 "rgb(ff1ea3)" "Usage: $0 <command>"
    exit 1
fi

COMMAND=$1

ACTIVE_WINDOW_INFO=$(hyprctl activewindow -j)
ACTIVE_WINDOW_CLASS=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.class')
ACTIVE_WINDOW_TITLE=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.title')

echo "Active window class: $ACTIVE_WINDOW_CLASS"
echo "Active window title: $ACTIVE_WINDOW_TITLE"

if [[ $ACTIVE_WINDOW_CLASS != code && $ACTIVE_WINDOW_CLASS != code-terminal-* ]]; then
    hyprctl notify -1 3000 "rgb(ff1ea3)" "Not in a code or code-terminal window"
    exit 0
fi

PROJECT=$(echo "$ACTIVE_WINDOW_TITLE" | sed 's/ *| *\(Code\|Terminal\)$//')
TARGET_CLASS="code-terminal-$PROJECT-$COMMAND"

function terminal_exists() {
    hyprctl clients -j | jq -e -r --arg class "$TARGET_CLASS" '.[] | select(.class == $class)' > /dev/null
}

function show_terminal() {
    echo "Opening terminal for $TARGET_CLASS"
    if terminal_exists; then
        hyprctl dispatch movetoworkspace "+0, class:$TARGET_CLASS"
    else
        hyprctl dispatch exec "kitty --class $TARGET_CLASS --title \"$PROJECT | Terminal\" --working-directory \"$PROJECT\" $COMMAND"
    fi
}

NEED_TERMINAL=1

if [[ $ACTIVE_WINDOW_CLASS == code-terminal-* ]]; then
    hyprctl dispatch movetoworkspacesilent "special:code-terminal"
    if [[ $ACTIVE_WINDOW_CLASS == "$TARGET_CLASS" ]]; then
        NEED_TERMINAL=0
    fi
fi

if [[ $NEED_TERMINAL -eq 1 ]]; then
    show_terminal
fi
