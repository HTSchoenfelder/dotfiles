#!/usr/bin/env bash

PYTHON_VERSION="3.13"

# Find all relevant site-packages directories for the current Python version
find_python_paths() {
    find /nix/store -maxdepth 4 -type d -path "*/lib/python$PYTHON_VERSION/site-packages" 2>/dev/null
}

# Set PYTHONPATH dynamically
export PYTHONPATH="$(find_python_paths | tr '\n' ':')$PYTHONPATH"

# Remove trailing ":" (if any) to avoid empty paths
export PYTHONPATH="${PYTHONPATH%:}"

# Check if essential modules are available
missing_modules=()
for module in west pykwalify ruamel.yaml; do
    python3 -c "import $module" 2>/dev/null || missing_modules+=("$module")
done

if [[ ${#missing_modules[@]} -eq 0 ]]; then
    echo "✅ Zephyr environment is ready! (Python $PYTHON_VERSION)"
else
    echo "⚠️ Warning: The following modules are missing: ${missing_modules[*]}"
fi
