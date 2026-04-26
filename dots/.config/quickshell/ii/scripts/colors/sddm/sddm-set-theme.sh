#!/usr/bin/env sh

set -eu

theme_dir="/usr/share/sddm/themes/silent"
bg_dir="$theme_dir/backgrounds"
theme_conf="$theme_dir/configs/illogical-impulse.conf"
default_conf="$theme_dir/configs/silvia.conf"
metadata="$theme_dir/metadata.desktop"

sudo_user="${SUDO_USER:-}"
if [ -n "$sudo_user" ]; then
  groups="$(id -nG "$sudo_user" 2>/dev/null || true)"
  case " $groups " in *" wheel "*|*" sudo "*) ;; *) exit 0 ;; esac
fi

[ $# -ge 1 ] && [ $# -le 2 ] && [ -f "$1" ] && [ -d "$theme_dir" ] && [ -f "$metadata" ] || exit 1

user_home="$HOME"
[ -n "$sudo_user" ] && user_home="$(awk -F: -v u="$sudo_user" '$1 == u { print $6; exit }' /etc/passwd)"
[ -n "$user_home" ] || user_home="$HOME"

colors_json="${XDG_STATE_HOME:-$user_home/.local/state}/quickshell/user/generated/colors.json"
[ -f "$colors_json" ] || exit 1
theme_uid="$(stat -c '%u' "$colors_json" 2>/dev/null || stat -f '%u' "$colors_json" 2>/dev/null || id -u "${sudo_user:-root}")"
theme_gid="$(stat -c '%g' "$colors_json" 2>/dev/null || stat -f '%g' "$colors_json" 2>/dev/null || id -g "${sudo_user:-root}")"

wallpaper="$1"
placeholder="${2:-}"
ext="${wallpaper##*.}"
[ "$ext" = "$wallpaper" ] && ext="" || ext=".$ext"

mkdir -p "$bg_dir"
cp -f -- "$wallpaper" "$bg_dir/wallpaper$ext"

placeholder_basename=""
if [ -n "$placeholder" ] && [ -f "$placeholder" ]; then
  placeholder_basename="${placeholder##*/}"
  cp -f -- "$placeholder" "$bg_dir/$placeholder_basename"
fi

[ -f "$theme_conf" ] || cp -f -- "$default_conf" "$theme_conf"
sed -i 's|ConfigFile=configs/default.conf|ConfigFile=configs/illogical-impulse.conf|g' "$metadata"

IFS='|' read -r surface_q primary_q outline_q surface_container_q surface_container_high_q error_q text_q <<EOF
$(jq -r '[.surface,.primary_container,.outline,.surface_container,.surface_container_high,.error,(.text // .on_surface)] | map(@json) | join("|")' "$colors_json")
EOF

placeholder_value='""'
[ -n "$placeholder_basename" ] && placeholder_value="$placeholder_basename"
wallpaper_value="\"wallpaper$ext\""

updates="$(
  printf 'General|animated-background-placeholder|%s\n' "$placeholder_value"
  printf 'LockScreen|background|%s\nLockScreen|background-color|%s\nLockScreen|saturation|0.2\n' "$wallpaper_value" "$surface_q"
  for sec in Clock Date Message; do printf 'LockScreen.%s|color|%s\n' "$sec" "$text_q"; done
  printf 'LoginScreen|background|%s\nLoginScreen|background-color|%s\n' "$wallpaper_value" "$surface_q"
  printf 'LoginScreen.LoginArea.Avatar|active-border-color|%s\nLoginScreen.LoginArea.Avatar|inactive-border-color|%s\n' "$primary_q" "$outline_q"
  printf 'LoginScreen.LoginArea.Username|color|%s\n' "$text_q"
  printf 'LoginScreen.LoginArea.PasswordInput|content-color|%s\nLoginScreen.LoginArea.PasswordInput|background-color|%s\nLoginScreen.LoginArea.PasswordInput|border-color|%s\n' "$text_q" "$surface_container_q" "$outline_q"
  printf 'LoginScreen.LoginArea.LoginButton|background-color|%s\nLoginScreen.LoginArea.LoginButton|active-background-color|%s\nLoginScreen.LoginArea.LoginButton|content-color|%s\nLoginScreen.LoginArea.LoginButton|active-content-color|%s\nLoginScreen.LoginArea.LoginButton|border-color|%s\n' "$surface_q" "$primary_q" "$text_q" "$text_q" "$outline_q"
  printf 'LoginScreen.LoginArea.Spinner|color|%s\n' "$text_q"
  printf 'LoginScreen.LoginArea.WarningMessage|normal-color|%s\nLoginScreen.LoginArea.WarningMessage|warning-color|%s\nLoginScreen.LoginArea.WarningMessage|error-color|%s\n' "$text_q" "$primary_q" "$error_q"
  printf 'LoginScreen.MenuArea.Popups|background-color|%s\nLoginScreen.MenuArea.Popups|active-option-background-color|%s\nLoginScreen.MenuArea.Popups|content-color|%s\nLoginScreen.MenuArea.Popups|active-content-color|%s\nLoginScreen.MenuArea.Popups|border-color|%s\n' "$surface_container_high_q" "$primary_q" "$text_q" "$text_q" "$outline_q"
  for sec in Session Layout Keyboard Power; do printf 'LoginScreen.MenuArea.%s|background-color|%s\nLoginScreen.MenuArea.%s|content-color|%s\nLoginScreen.MenuArea.%s|active-content-color|%s\n' "$sec" "$surface_q" "$sec" "$text_q" "$sec" "$text_q"; done
  printf 'LoginScreen.VirtualKeyboard|background-color|%s\nLoginScreen.VirtualKeyboard|key-content-color|%s\nLoginScreen.VirtualKeyboard|key-color|%s\nLoginScreen.VirtualKeyboard|key-active-background-color|%s\nLoginScreen.VirtualKeyboard|selection-background-color|%s\nLoginScreen.VirtualKeyboard|selection-content-color|%s\nLoginScreen.VirtualKeyboard|primary-color|%s\nLoginScreen.VirtualKeyboard|border-color|%s\nTooltips|enable|false\n' "$surface_q" "$text_q" "$surface_container_q" "$primary_q" "$primary_q" "$text_q" "$primary_q" "$outline_q"
)"

tmp="$(mktemp)"
awk -F'|' -v U="$updates" '
  function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
  function flush(sec, i, mk) { for (i = 1; i <= n; i++) if (sct[i] == sec) { mk = sec SUBSEP key[i]; if (!done[mk]) { print key[i] "=" val[i]; done[mk] = 1 } } }
  BEGIN {
    c = split(U, L, /\n/)
    for (i = 1; i <= c; i++) if (L[i] != "") {
      split(L[i], a, "|"); sct[++n] = a[1]; key[n] = a[2]; val[n] = a[3]; map[a[1] SUBSEP a[2]] = a[3]
    }
    sec = ""
  }
  /^\[.*\]$/ { if (sec != "") flush(sec); sec = substr($0, 2, length($0) - 2); seen[sec] = 1; print; next }
  {
    if (sec != "") {
      eq = index($0, "=")
      if (eq > 0) {
        k = trim(substr($0, 1, eq - 1)); mk = sec SUBSEP k
        if (mk in map) { if (!done[mk]) { print k "=" map[mk]; done[mk] = 1 } next }
      }
    }
    print
  }
  END {
    if (sec != "") flush(sec)
    for (i = 1; i <= n; i++) if (!seen[sct[i]]) { print ""; print "[" sct[i] "]"; seen[sct[i]] = 1; flush(sct[i]) }
  }
' "$theme_conf" >"$tmp" && mv "$tmp" "$theme_conf"
chmod 0644 "$theme_conf"
chown "$theme_uid:$theme_gid" "$theme_conf"
