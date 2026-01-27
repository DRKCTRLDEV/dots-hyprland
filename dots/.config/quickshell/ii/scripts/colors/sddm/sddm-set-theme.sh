#!/bin/sh

SDDM_THEME_DIR=/usr/share/sddm/themes/sugar-candy
SDDM_BG_DIR="$SDDM_THEME_DIR/Backgrounds"
THEME_CONF="$SDDM_THEME_DIR/theme.conf"
MATUGEN_COLORS="$HOME/.config/sddm/theme.conf"

escape(){ printf '%s' "$1" | sed 's/[\/&]/\\&/g'; }
update_conf_key(){
  k=$1; v=$2
  [ -f "$THEME_CONF" ] || printf '[General]\n' > "$THEME_CONF"
  ke=$(escape "$k"); ve=$(escape "$v")
  if grep -q -E "^[[:space:]]*$ke=" "$THEME_CONF" 2>/dev/null; then
    sed -i "s|^[[:space:]]*$ke=.*|$k=$ve|" "$THEME_CONF"
  else
    printf '%s=%s\n' "$k" "$ve" >> "$THEME_CONF"
  fi
}

p=$1; [ -f "$p" ] || exit 1
[ -f "$MATUGEN_COLORS" ] && [ -d "$SDDM_THEME_DIR" ] || exit 0
# Update colors
while IFS= read -r line; do
  case "$line" in ''|\#*|\[*\]) continue ;; esac
  k=${line%%=*}; v=${line#*=}; [ -z "$v" ] && continue
  update_conf_key "$k" "$v"
done < "$MATUGEN_COLORS"
# Update wallpaper
mkdir -p "$SDDM_BG_DIR"
fn="current-wallpaper.${p##*.}"
install -m 0644 "$p" "$SDDM_BG_DIR/$fn" || exit 1
chown root:root "$SDDM_BG_DIR/$fn" 2>/dev/null || true
update_conf_key Background "\"Backgrounds/$fn\""
