#!/bin/bash
# Shared configuration management functions
# Source this file in your scripts: source "$(dirname "$0")/lib/config.sh"

# Load configuration from a file
# Usage: load_config "/path/to/config-file"
load_config() {
    local config_file="$1"

    if [ -f "$config_file" ]; then
        # shellcheck source=/dev/null
        source "$config_file"
        return 0
    else
        return 1
    fi
}

# Save configuration to a file
# Usage: save_config "/path/to/config-file" "KEY1=value1" "KEY2=value2" ...
save_config() {
    local config_file="$1"
    shift

    # Create/overwrite config file
    : > "$config_file"

    # Write each key=value pair
    for pair in "$@"; do
        echo "$pair" >> "$config_file"
    done

    return 0
}

# Prompt user for input with optional default value
# Usage: result=$(prompt_with_default "Enter name" "default-name")
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        result=${result:-$default}
    else
        read -p "$prompt: " result
    fi

    echo "$result"
}

# Export functions for use in sourcing scripts
export -f load_config
export -f save_config
export -f prompt_with_default
