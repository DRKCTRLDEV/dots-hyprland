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

command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }

if [[ -f "$CJ" ]]; then
  payload=$(jq -c '. as $C | {
    "material-code.colors": {
      "primary": ($C.primary // ""),
      "foreground": ($C.on_surface // ""),
      "mutedForeground": ($C.on_surface_variant // ""),
      "background": ($C.surface // ""),
      "card": ($C.surface_container // ""),
      "popover": ($C.surface_container_high // ""),
      "hover": ($C.surface_container_highest // ""),
      "border": ($C.outline_variant // ""),
      "primaryForeground": ($C.on_primary // ""),
      "secondary": ($C.secondary_container // ""),
      "secondaryForeground": ($C.on_secondary_container // ""),
      "error": ($C.error // ""),
      "errorForeground": ($C.on_error // ""),
      "success": ($C.tertiary // ""),
      "warning": ($C.secondary // ""),
      "syntax.comment": ($C.on_surface_variant // ""),
      "syntax.string": ($C.secondary // ""),
      "syntax.function": ($C.primary // ""),
    },
    "material-icon-theme": {
      "files": { "color": ($C.on_surface // "") },
      "folders": { "color": ($C.primary // "") },
      "rootFolders": { "color": ($C.secondary // "") }
    }
  }' "$CJ")
else
  echo "colors.json not found, cannot maintain quality with single color" >&2
  exit 1
fi

for p in "${settings_paths[@]}"; do
  if [[ -f "$p" ]]; then
    t="$(mktemp)"
    jq --argjson p "$payload" '. * $p' "$p" > "$t" && mv "$t" "$p"
  fi
done

echo "Updated VS Code settings with material colors."
