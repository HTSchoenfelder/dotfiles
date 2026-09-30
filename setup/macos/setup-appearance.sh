#!/usr/bin/env bash

set -euo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repository_directory=$(cd -- "$script_directory/../.." && pwd)
state_directory=${XDG_STATE_HOME:-"$HOME/.local/state"}/dotfiles/macos-appearance
restore_script="$state_directory/restore-defaults.sh"
kitty_source="$repository_directory/home/.config/kitty/macos-appearance.conf"
kitty_target="$HOME/.config/kitty/macos-appearance-enabled.conf"

restart_desktop_ui() {
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
}

append_restore_command() {
  local domain=$1
  local key=$2
  local type=$3
  local value

  if value=$(defaults read "$domain" "$key" 2>/dev/null); then
    printf 'defaults write %q %q -%s %q\n' "$domain" "$key" "$type" "$value" \
      >> "$restore_script"
  else
    printf 'defaults delete %q %q >/dev/null 2>&1 || true\n' "$domain" "$key" \
      >> "$restore_script"
  fi
}

snapshot_defaults() {
  if [ -f "$restore_script" ]; then return; fi
  mkdir -p "$state_directory"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' > "$restore_script"
  append_restore_command com.apple.dock autohide bool
  append_restore_command com.apple.dock show-recents bool
  append_restore_command com.apple.dock launchanim bool
  append_restore_command com.apple.dock expose-animation-duration float
  append_restore_command NSGlobalDomain _HIHideMenuBar bool
  append_restore_command NSGlobalDomain NSAutomaticWindowAnimationsEnabled bool
  chmod 700 "$restore_script"
}

system_apply() {
  snapshot_defaults
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock launchanim -bool false
  defaults write com.apple.dock expose-animation-duration -float 0.12
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  restart_desktop_ui
  echo "macOS appearance settings applied."
}

system_restore() {
  if [ ! -f "$restore_script" ]; then
    echo "No saved macOS appearance settings found."
    return
  fi
  "$restore_script"
  restart_desktop_ui
  rm -f "$restore_script"
  rmdir "$state_directory" 2>/dev/null || true
  echo "Saved macOS appearance settings restored."
}

kitty_enable() {
  mkdir -p "$(dirname -- "$kitty_target")"
  if [ -e "$kitty_target" ] || [ -L "$kitty_target" ]; then
    if [ "$(readlink "$kitty_target" 2>/dev/null || true)" = "$kitty_source" ]; then
      echo "Kitty appearance is already enabled."
      return
    fi
    echo "Refusing to replace existing file: $kitty_target" >&2
    exit 1
  fi
  ln -s "$kitty_source" "$kitty_target"
  echo "Kitty appearance enabled for new windows."
}

kitty_disable() {
  if [ -L "$kitty_target" ] \
      && [ "$(readlink "$kitty_target")" = "$kitty_source" ]; then
    rm "$kitty_target"
    echo "Kitty appearance disabled for new windows."
  else
    echo "Kitty appearance is not enabled by this script."
  fi
}

borders_start() {
  command -v borders >/dev/null || {
    echo "JankyBorders is not installed. Run brew bundle --file $script_directory/Brewfile." >&2
    exit 1
  }
  brew services start borders
}

borders_stop() {
  brew services stop borders
}

status() {
  printf 'Layout borders: configured in ~/.hammerspoon/config.lua\n'
  if [ -L "$kitty_target" ]; then
    printf 'Kitty appearance: enabled\n'
  else
    printf 'Kitty appearance: disabled\n'
  fi
  if [ -f "$restore_script" ]; then
    printf 'macOS defaults: applied; restore snapshot available\n'
  else
    printf 'macOS defaults: no restore snapshot\n'
  fi
  brew services list 2>/dev/null | awk '$1 == "borders" {print "JankyBorders service: " $2}'
}

usage() {
  cat <<'EOF'
Usage: setup-appearance.sh COMMAND

Commands:
  apply            Apply macOS defaults and enable Kitty appearance
  restore          Restore macOS defaults and disable Kitty appearance
  system-apply     Apply only the optional macOS defaults
  system-restore   Restore only the captured macOS defaults
  kitty-enable     Enable the optional Kitty title-bar configuration
  kitty-disable    Disable the optional Kitty title-bar configuration
  borders-start    Start JankyBorders as a Homebrew login service
  borders-stop     Stop the JankyBorders Homebrew service
  status           Show appearance-layer state
EOF
}

case ${1:-} in
  apply)
    system_apply
    kitty_enable
    ;;
  restore)
    system_restore
    kitty_disable
    ;;
  system-apply) system_apply ;;
  system-restore) system_restore ;;
  kitty-enable) kitty_enable ;;
  kitty-disable) kitty_disable ;;
  borders-start) borders_start ;;
  borders-stop) borders_stop ;;
  status) status ;;
  *) usage; exit 2 ;;
esac
