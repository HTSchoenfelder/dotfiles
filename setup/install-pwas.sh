#! /usr/bin/env bash

firefoxpwa runtime install

install_pwa() {
    local manifestUrl="$1"
    local name="$2"

    output=$(firefoxpwa profile create --name "$name")
    profileId=$(echo "$output" | grep -oP '(?<=Profile created: )\w+')
    echo "profileId: $profileId"

    firefoxpwa site install "$manifestUrl" \
        --name "$name" \
        --profile "$profileId"
}

# install_pwa "https://teams.microsoft.com/v2/manifest.json" "Teams 1"
# install_pwa "https://teams.microsoft.com/v2/manifest.json" "Teams 2"
install_pwa "https://outlook.office.com/mail/manifests/pwa.json?culture=en" "Outlook 1"
install_pwa "https://outlook.office.com/mail/manifests/pwa.json?culture=en" "Outlook 2"
