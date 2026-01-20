#!/usr/bin/env bash
COLOR_FILE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt"

# Define an array of possible VSCode settings file paths for various forks
settings_paths=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - OSS/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
    # Add more paths as needed for other forks
)

new_color=$(cat "$COLOR_FILE_PATH")

# Loop through each settings file path
for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        # Ensure material-code.colors.primary is set to new_color
        if grep -q '"material-code.colors.primary"' "$CODE_SETTINGS_PATH"; then
            sed -i -E "s/(\"material-code.colors.primary\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" "$CODE_SETTINGS_PATH"
        elif grep -q '"material-code.colors"' "$CODE_SETTINGS_PATH"; then
            sed -i '/"material-code.colors"\s*:\s*{/,/}/ s/}/,\n    "primary": "'${new_color}'"\n  }/' "$CODE_SETTINGS_PATH"
        else
            sed -i '$ s/}/,\n  "material-code.colors": {\n    "primary": "'${new_color}'"\n  }\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi

        # Also set the Material Icon Theme colors to the same accent
        for ICON_KEY in "material-icon-theme.folders.color" "material-icon-theme.files.color" "material-icon-theme.rootFolders.color"; do
            if grep -q "\"${ICON_KEY}\"" "$CODE_SETTINGS_PATH"; then
                sed -i -E "s/(\"${ICON_KEY}\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" "$CODE_SETTINGS_PATH"
            else
                sed -i '$ s/}/,\n  "'${ICON_KEY}'": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
                sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
            fi
        done
    fi
done

