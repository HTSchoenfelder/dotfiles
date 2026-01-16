REAL_BIN=$(readlink -f "$(which kitty)")
STORE_ROOT=$(echo "$REAL_BIN" | grep -o "/nix/store/[^/]*")
APP_SOURCE=$(find "$STORE_ROOT" -name "kitty.app" -maxdepth 4 -print -quit)

if [ -z "$APP_SOURCE" ]; then echo "Fehler: kitty.app konnte im Nix-Store nicht gefunden werden."; exit 1; fi

sudo rm -rf "/Applications/Nix Apps/kitty.app"
sudo mkdir -p "/Applications/Nix Apps"
sudo cp -rL "$APP_SOURCE" "/Applications/Nix Apps/"
sudo chmod -R u+w "/Applications/Nix Apps/kitty.app"
sudo xattr -r -d com.apple.quarantine "/Applications/Nix Apps/kitty.app" 2>/dev/null
sudo codesign --force --deep --sign - "/Applications/Nix Apps/kitty.app"