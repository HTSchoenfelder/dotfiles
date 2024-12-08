#! /usr/bin/env bash

# Exit if 'code' command is not available
command -v code &> /dev/null || { echo "VSCode (code command) is not installed."; exit 1; }

# Read extensions from the file and sort them
code_extensions=$(sort "$HOME/dotfiles/misc/code_extensions.txt")

# Get the list of installed extensions and sort them
installed_extensions=$(code --list-extensions | sort)

# Find uninstalled extensions
uninstalled_extensions=$(comm -23 <(echo "$code_extensions") <(echo "$installed_extensions"))

echo "Checking for uninstalled VSCode extensions..."

# Exit if all extensions are already installed
[[ -z "$uninstalled_extensions" ]] && { echo "All good!"; exit 0; }

# Install uninstalled extensions
echo "Found $(echo "$uninstalled_extensions" | wc -l)."
while read -r extension; do
  [[ -n "$extension" ]] && echo "Installing $extension..." && code --install-extension "$extension"
done <<< "$uninstalled_extensions"

echo "Done!"
