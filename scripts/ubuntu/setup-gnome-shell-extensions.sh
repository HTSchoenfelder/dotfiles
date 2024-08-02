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
    gnome-one-window-wonderland@jqno.nl
    move-to-next-screen@wosar.me
)

function install_gnome_extension() {
    local uuid=$1
    VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?uuid=${uuid}" | jq '.extensions[0].shell_version_map | to_entries | max_by(.value.version) | .value.pk')
    echo "Latest version tag for ${uuid}: ${VERSION_TAG}"
    curl -L "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${VERSION_TAG}" -o "${uuid}.zip"
    echo "Downloaded ${uuid}"
    gnome-extensions install --force "${uuid}.zip"
    echo "Installed ${uuid}"
    rm "${uuid}.zip"
    echo "Cleaned up ${uuid}.zip"
}

function install_gnome_extension_dbus() {
    local uuid=$1

    gdbus call --session \
            --dest org.gnome.Shell.Extensions \
            --object-path /org/gnome/Shell/Extensions \
            --method org.gnome.Shell.Extensions.InstallRemoteExtension \
            "'${uuid}'"
}

for uuid in "${extensions[@]}"; do
    echo "Processing extension: ${uuid}"

    if ! gnome-extensions list | grep --quiet ${uuid}; then
        echo "Instaalling for ${uuid}"
        # install_gnome_extension "${uuid}"        
        install_gnome_extension_dbus "${uuid}"        
        echo "Installed ${uuid}"
    fi

    gnome-extensions enable "${uuid}"
    echo "Enabled ${uuid}"

done

# dconf dump / > current_dconf.ini
cat ~/dotfiles/misc/dconf.ini | dconf load /