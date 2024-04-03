#!/bin/bash

sudo apt update
sudo apt install -y \
    gnome-browser-connector \
    gnome-shell-extensions \
    gnome-tweaks \
    dconf-editor \
    gnome-shell-extension-manager

extensions=(
    clipboard-indicator@tudmotu.com
    extension-list@tu.berry
    activate-window-by-title@lucaswerkmeister.de
    weekstartmodifier@saccuzm.gmail.com
    steal-my-focus-window@steal-my-focus-window
    quicktext@brainstormtrooper.github.io
    hue-lights@chlumskyvaclav.gmail.com
    waylandorx11@injcristianrojas.github.com
    all-windows@ezix.org
    simple-message@freddez
    customreboot@nova1545
    emoji-copy@felipeftn
    switcher@landau.fi
    color-picker@tuberry
    activate_gnome@isjerryxiao
    docker@stickman_0x00.com
    window-calls@domandoman.xyz
    focused-window-dbus@flexagoon.com
    super-key@tommimon.github.com
    gnome-one-window-wonderland@jqno.nl
)

for uuid in "${extensions[@]}"; do
    echo "Processing extension: ${uuid}"

    if ! gnome-extensions list | grep --quiet ${uuid}; then
        echo "Attempting remote installation for ${uuid}"
        gdbus call --session \
            --dest org.gnome.Shell.Extensions \
            --object-path /org/gnome/Shell/Extensions \
            --method org.gnome.Shell.Extensions.InstallRemoteExtension \
            "'${uuid}'"
        echo "Remote installation attempted for ${uuid}"
    fi

    gnome-extensions enable "${uuid}"
    echo "Enabled ${uuid}"
done

# dconf dump / > current_dconf.ini
cat ~/dotfiles/misc/dconf.ini | dconf load /
