#!/bin/bash

extensions=(
    clipboard-indicator@tudmotu.com
    extension-list@tu.berry
    activate-window-by-title@lucaswerkmeister.de
    weekstartmodifier@saccuzm.gmail.com
)

for uuid in "${extensions[@]}"; do
    echo "Processing extension: ${uuid}"

    VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?uuid=${uuid}" | jq '.extensions[0].shell_version_map | to_entries | max_by(.value.version) | .value.pk')
    echo "Latest version tag for ${uuid}: ${VERSION_TAG}"

    curl -L "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${VERSION_TAG}" -o "${uuid}.zip"
    echo "Downloaded ${uuid}"

    gnome-extensions install --force "${uuid}.zip"
    echo "Installed ${uuid}"

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

    rm "${uuid}.zip"
    echo "Cleaned up ${uuid}.zip"
done