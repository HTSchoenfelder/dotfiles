#!/usr/bin/env bash

set -euo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repository_directory=$(cd -- "$script_directory/../.." && pwd)

if [ "$#" -eq 1 ]; then
  configuration=$1
elif [ "$#" -eq 0 ]; then
  read -r -p "NixOS configuration (desktop/notebook/qemu): " configuration
else
  echo "Usage: $0 [desktop|notebook|qemu]" >&2
  exit 1
fi

case "$configuration" in
  desktop|notebook|qemu) ;;
  *)
    echo "Unknown NixOS configuration: $configuration" >&2
    exit 1
    ;;
esac

hardware_file="$script_directory/configurations/$configuration/hardware.nix"
host_file="$script_directory/configurations/$configuration/host.nix"
monitor_source="$repository_directory/home/.config/hypr/config/hosts/$configuration/monitor.lua"
monitor_link="$HOME/.config/hypr/config/monitor.lua"
profile_file="$HOME/.config/dotfiles/nixos-profile"

for command in nix nix-instantiate nixos-generate-config nixos-rebuild sudo git; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Required command is unavailable: $command" >&2
    exit 1
  fi
done

if [ ! -f "$hardware_file" ] || [ ! -f "$host_file" ] || [ ! -f "$monitor_source" ]; then
  echo "Configuration files are missing for $configuration" >&2
  exit 1
fi

for config_file in "$hardware_file" "$host_file"; do
  if ! git -C "$repository_directory" ls-files --error-unmatch "$config_file" >/dev/null 2>&1; then
    echo "The flake requires a Git-tracked file: $config_file" >&2
    exit 1
  fi
done

if [ -f "$profile_file" ] && [ "$(cat "$profile_file")" != "$configuration" ]; then
  echo "A different NixOS profile is already recorded in $profile_file" >&2
  exit 1
fi

if [ -e "$monitor_link" ] && [ ! -L "$monitor_link" ]; then
  echo "Monitor configuration exists and is not a symlink: $monitor_link" >&2
  exit 1
fi

current_host_name=$(hostname)
read -r -p "Host name [$current_host_name]: " host_name
host_name=${host_name:-$current_host_name}
if [ "${#host_name}" -gt 63 ] || [[ ! "$host_name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Host name must be a lowercase DNS label of at most 63 characters." >&2
  exit 1
fi

detected_state_version=""
for original_config in /etc/nixos/configuration.nix /etc/nixos.bak/configuration.nix; do
  if [ -f "$original_config" ]; then
    candidate=$(sed -nE 's/^[[:space:]]*system\.stateVersion[[:space:]]*=[[:space:]]*"([0-9]{2}\.[0-9]{2})"[[:space:]]*;.*/\1/p' "$original_config")
    if [[ "$candidate" =~ ^[0-9]{2}\.[0-9]{2}$ ]]; then
      detected_state_version=$candidate
      echo "Found initial system.stateVersion $candidate in $original_config"
      break
    fi
  fi
done

if [ -n "$detected_state_version" ]; then
  read -r -p "Initial system.stateVersion [$detected_state_version]: " state_version
  state_version=${state_version:-$detected_state_version}
else
  read -r -p "Initial system.stateVersion (YY.MM): " state_version
fi
if [[ ! "$state_version" =~ ^[0-9]{2}\.[0-9]{2}$ ]]; then
  echo "Initial system.stateVersion must use the YY.MM format." >&2
  exit 1
fi

# Generate mounted filesystems by UUID instead of changing partition labels.
generated_hardware=$(mktemp "$hardware_file.XXXXXX")
generated_host=$(mktemp "$host_file.XXXXXX")
trap 'rm -f -- "$generated_hardware" "$generated_host"' EXIT
nixos-generate-config --show-hardware-config > "$generated_hardware"
printf '{\n  networking.hostName = "%s";\n  system.stateVersion = "%s";\n}\n' \
  "$host_name" "$state_version" > "$generated_host"
nix-instantiate --parse "$generated_hardware" >/dev/null
nix-instantiate --parse "$generated_host" >/dev/null

if ! grep -q 'fileSystems."/"' "$generated_hardware"; then
  echo "Generated hardware configuration has no root filesystem." >&2
  exit 1
fi

if grep -q 'fileSystems."/boot"' "$hardware_file" && \
  ! grep -q 'fileSystems."/boot"' "$generated_hardware"; then
  echo "The existing boot filesystem is not mounted; mount it before setup." >&2
  exit 1
fi

if grep -q '/dev/disk/by-label/' "$generated_hardware"; then
  echo "Generated hardware configuration still contains filesystem labels." >&2
  exit 1
fi

if ! cmp -s "$hardware_file" "$generated_hardware" || ! cmp -s "$host_file" "$generated_host"; then
  echo "Proposed host configuration changes:"
  diff -u "$hardware_file" "$generated_hardware" || true
  diff -u "$host_file" "$generated_host" || true
  read -r -p "Replace the configuration files shown above? Type yes: " confirmation
  if [ "$confirmation" != yes ]; then
    echo "Setup cancelled."
    exit 1
  fi

  backup_directory="$HOME/.local/state/dotfiles/nixos-setup"
  mkdir -p "$backup_directory"
  for config_file in "$hardware_file" "$host_file"; do
    if [ "$config_file" = "$hardware_file" ]; then
      generated_file=$generated_hardware
    else
      generated_file=$generated_host
    fi
    if ! cmp -s "$config_file" "$generated_file"; then
      backup_file=$(mktemp "$backup_directory/$configuration-${config_file##*/}.XXXXXX")
      cp -p -- "$config_file" "$backup_file"
      chmod --reference="$config_file" "$generated_file"
      mv -- "$generated_file" "$config_file"
      echo "Previous configuration saved to $backup_file"
    fi
  done
fi

nix --extra-experimental-features 'nix-command flakes' \
  eval --raw "$script_directory#nixosConfigurations.$configuration.config.system.build.toplevel.drvPath" >/dev/null

read -r -p "Activate NixOS configuration $configuration? Type yes: " confirmation
if [ "$confirmation" != yes ]; then
  echo "Setup cancelled before activation."
  exit 1
fi

sudo nixos-rebuild switch --flake "$script_directory#$configuration" \
  --option experimental-features 'nix-command flakes'

mkdir -p "$HOME/.config/dotfiles" "$HOME/.config/hypr/config" \
  "$HOME/screenshots" "$HOME/projects/dev" "$HOME/projects/temp" "$HOME/projects/work"
profile_temp=$(mktemp "$HOME/.config/dotfiles/.nixos-profile.XXXXXX")
printf '%s\n' "$configuration" > "$profile_temp"
mv -- "$profile_temp" "$profile_file"

stow --dir="$repository_directory" --target="$HOME" --no-folding home
ln -sfnT -- "$monitor_source" "$monitor_link"
bat cache --build
