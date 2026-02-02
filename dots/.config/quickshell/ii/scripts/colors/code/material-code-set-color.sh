#!/usr/bin/env bash
set -euo pipefail

SD="${XDG_STATE_HOME:-$HOME/.local/state}"
CJ="$SD/quickshell/user/generated/colors.json"

settings_paths=(
  "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
  "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"
  "${XDG_CONFIG_HOME:-$HOME/.config}/Code - OSS/User/settings.json"
  "${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User/settings.json"
  "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
)

command -v jq >/dev/null || exit 1

[[ -f "$CJ" ]] || exit 1

payload=$(jq -c '. as $C | {
  "material-code.colors": {
    primary: ($C.primary // ""),
    foreground: ($C.on_surface // ""),
    mutedForeground: ($C.on_surface_variant // ""),
    background: ($C.surface // ""),
    card: ($C.surface_container // ""),
    popover: ($C.surface_container_high // ""),
    hover: ($C.surface_container_highest // ""),
    border: ($C.outline_variant // ""),
    primaryForeground: ($C.on_primary // ""),
    secondary: ($C.secondary_container // ""),
    secondaryForeground: ($C.on_secondary_container // ""),
    error: ($C.error // ""),
    errorForeground: ($C.on_error // ""),
    success: ($C.tertiary // ""),
    warning: ($C.secondary // "")
  },
  "material-icon-theme": {
    files: {color: ($C.on_surface // "")},
    folders: {color: ($C.primary // "")},
    rootFolders: {color: ($C.secondary // "")}
  }
}' "$CJ")

for p in "${settings_paths[@]}"; do
  [[ -f "$p" ]] && jq --argjson p "$payload" '. * $p' "$p" > "$p.tmp" && mv "$p.tmp" "$p"
done
