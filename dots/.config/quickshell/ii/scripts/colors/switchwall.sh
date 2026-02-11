#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
LOCK_FILE="/tmp/switchwall.pid"

# Cached config values (populated by read_config)
CFG_PALETTE_TYPE="auto"
CFG_ACCENT_COLOR=""
CFG_WALLPAPER_PATH=""
CFG_ENABLE_APPS_SHELL="true"
CFG_ICON_THEME=""
CFG_ENABLE_TERMINAL="true"
CFG_ENABLE_QT_APPS="true"

read_config() {
    [[ -f "$SHELL_CONFIG_FILE" ]] || return 0
    local _raw
    _raw=$(jq -r '[
        (.appearance.palette.type // "auto"),
        (.appearance.palette.accentColor // ""),
        (.background.wallpaperPath // ""),
        (.appearance.wallpaperTheming.enableAppsAndShell // true | tostring),
        (.appearance.iconTheme // ""),
        (.appearance.wallpaperTheming.enableTerminal // true | tostring),
        (.appearance.wallpaperTheming.enableQtApps // true | tostring)
    ] | join("\n")' "$SHELL_CONFIG_FILE" 2>/dev/null) || return 0
    {
        read -r CFG_PALETTE_TYPE
        read -r CFG_ACCENT_COLOR
        read -r CFG_WALLPAPER_PATH
        read -r CFG_ENABLE_APPS_SHELL
        read -r CFG_ICON_THEME
        read -r CFG_ENABLE_TERMINAL
        read -r CFG_ENABLE_QT_APPS
    } <<< "$_raw"
}

kill_previous_instance() {
    if [[ -f "$LOCK_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            kill -- -"$old_pid" 2>/dev/null || kill "$old_pid" 2>/dev/null || true
            pkill -f "icon-accentize.sh" 2>/dev/null || true
            sleep 0.05
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

pre_process() {
    local mode_flag="$1"
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    fi
    if command -v flatpak &>/dev/null; then
        flatpak override --user \
            --filesystem=xdg-config/gtk-3.0:ro \
            --filesystem=xdg-config/gtk-4.0:ro \
            --filesystem=xdg-data/icons:ro 2>/dev/null || true
        flatpak override --user --unset-env=GTK_THEME 2>/dev/null || true
    fi
    mkdir -p "$CACHE_DIR/user/generated"
}

apply_terminal_colors() {
    local kitty_conf="$XDG_CONFIG_HOME/kitty/matugen-colors.conf"
    [ -f "$kitty_conf" ] || return

    local adjusted
    adjusted=$(gawk '
    function hex2v(h,  s) { s=tolower(h); sub(/^#/,"",s); return s }
    function h2d(c) {
        c=tolower(c)
        return (index("0123456789abcdef",substr(c,1,1))-1)*16 + \
               (index("0123456789abcdef",substr(c,2,1))-1)
    }
    function hex2r(h) { h=hex2v(h); return h2d(substr(h,1,2)) }
    function hex2g(h) { h=hex2v(h); return h2d(substr(h,3,2)) }
    function hex2b(h) { h=hex2v(h); return h2d(substr(h,5,2)) }
    function slin(c,  v) { v=c/255; return (v<=0.04045)? v/12.92 : ((v+0.055)/1.055)^2.4 }
    function lum(h) { return 0.2126*slin(hex2r(h))+0.7152*slin(hex2g(h))+0.0722*slin(hex2b(h)) }
    function cr(a,b,  la,lb,t) { la=lum(a);lb=lum(b); if(lb>la){t=la;la=lb;lb=t}; return (la+0.05)/(lb+0.05) }
    function clamp(v) { return (v<0)?0:(v>255)?255:int(v+0.5) }
    function ensure_contrast(fg,bg,min_r,  ratio,bl,r,g,b,f,i,nr,ng,nb,nh) {
        ratio=cr(fg,bg); if(ratio>=min_r) return fg
        bl=lum(bg); r=hex2r(fg); g=hex2g(fg); b=hex2b(fg)
        for(i=1;i<=120;i++) {
            f=(bl<0.5)? 1+i*0.015 : 1-i*0.008
            if(f<0.05) f=0.05
            nr=clamp(r*f); ng=clamp(g*f); nb=clamp(b*f)
            nh=sprintf("#%02x%02x%02x",nr,ng,nb)
            if(cr(nh,bg)>=min_r) return nh
        }
        return (bl<0.5)? "#ffffff" : "#000000"
    }
    /^foreground/  { fg=$2; next }
    /^background/  { bg=$2; next }
    /^cursor /     { curs=$2; next }
    /^color[0-9]/ {
        n=$1; sub(/^color/,"",n); n=int(n)
        colors[n]=$2
    }
    END {
        fg=ensure_contrast(fg,bg,4.5)
        curs=ensure_contrast(curs,bg,4.5)
        printf "fg=%s\nbg=%s\ncursor=%s\n",fg,bg,curs
        for(i=0;i<=15;i++) {
            c=colors[i]
            if(i>0) c=ensure_contrast(c,bg,3.0)
            printf "c%d=%s\n",i,c
        }
    }' "$kitty_conf")

    local fg bg cursor
    eval "$adjusted"
    local colors=()
    for i in {0..15}; do eval "colors[$i]=\$c$i"; done

    local e=$'\033' s=""
    for i in {0..15}; do
        s+="${e}]4;${i};${colors[$i]}${e}\\"
    done
    s+="${e}]10;${fg}${e}\\"
    s+="${e}]11;${bg}${e}\\"
    s+="${e}]12;${cursor}${e}\\"
    s+="${e}]708;[100]${bg}${e}\\"

    for f in /dev/pts/*; do
        [[ $f =~ ^/dev/pts/[0-9]+$ ]] && printf '%s' "$s" > "$f" 2>/dev/null &
    done
    wait 2>/dev/null

    if command -v kitty &>/dev/null; then
        pkill -USR1 kitty 2>/dev/null || true
        kitty @ --to unix:@kitty set-colors --all --configured \
            "$kitty_conf" 2>/dev/null || true
    fi
}

# ── Unified post-matugen refresh ────────────────────────────────────────────
# Called ONCE after matugen has finished writing ALL template files.
# Handles: color-schemes, GTK reload, Flatpak propagation, Darkly/Qt live
# refresh, icon recoloring, SDDM, VS Code, terminal colors.
# Nothing else should send D-Bus theme signals — this is the single source.
refresh_running_apps() {
    local mode_flag="$1"
    local wallpaper_path="$2"
    local thumbnail_path="${3:-}"

    # ── Cosmic (propagate to Light variant & notify) ──
    local cosmic_dark="$XDG_CONFIG_HOME/cosmic/com.system76.CosmicTheme.Dark/v1"
    local cosmic_light="$XDG_CONFIG_HOME/cosmic/com.system76.CosmicTheme.Light/v1"
    mkdir -p "$cosmic_light" 2>/dev/null
    # matugen now writes directly to "system" (the active theme file).
    # Copy Dark → Light so both variants use the Material You palette.
    cp "$cosmic_dark/system" "$cosmic_light/system" 2>/dev/null || true
    # Clean up stale "matugen" files left by older configs
    rm -f "$cosmic_dark/matugen" "$cosmic_light/matugen" 2>/dev/null || true
    # Atomic re-write (rename) — ensures inotify MOVED_TO fires even when
    # the file content was written in-place by matugen.
    for _cf in "$cosmic_dark/system" "$cosmic_light/system"; do
        [[ -f "$_cf" ]] && cp "$_cf" "${_cf}.tmp" && mv "${_cf}.tmp" "$_cf"
    done

    # ── SDDM + VS Code (background, non-blocking) ──
    local sddm_args=("$wallpaper_path")
    [[ -n "$thumbnail_path" ]] && sddm_args+=("$thumbnail_path")
    sudo python3 \
        "$SCRIPT_DIR/sddm/sddm-set-theme.py" "${sddm_args[@]}" &
    "$SCRIPT_DIR/code/material-code-set-color.sh" &

    # ── Flatpak CSS propagation ──

    local flatpak_apps_dir="$HOME/.var/app"
    if [[ -d "$flatpak_apps_dir" ]]; then
        for v in 3 4; do
            local src="$XDG_CONFIG_HOME/gtk-${v}.0/gtk.css"
            [[ -f "$src" ]] || continue
            find "$flatpak_apps_dir" -mindepth 1 -maxdepth 1 -type d -exec sh -c '
                src="$1"; v="$2"; shift 2
                for d; do mkdir -p "$d/config/gtk-${v}.0" && cp "$src" "$d/config/gtk-${v}.0/gtk.css" 2>/dev/null; done
            ' _ "$src" "$v" {} +
        done
    fi

    # Terminal colors
    [[ "$CFG_ENABLE_TERMINAL" != "false" ]] && apply_terminal_colors &

    # GTK4/libadwaita portal signal — toggle color-scheme to trigger SettingChanged
    (
        local current_cs
        current_cs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'") || current_cs="prefer-dark"
        gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
        sleep 0.15
        gsettings set org.gnome.desktop.interface color-scheme "$current_cs" 2>/dev/null || true
    ) &

    # Icon recoloring (must complete before Qt/KDE signals)
    "$SCRIPT_DIR/icon-accentize.sh"

    # GTK3: toggle theme to force CSS reload
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-${mode_flag}" 2>/dev/null || true

    # Qt / KDE live refresh
    if [[ "$CFG_ENABLE_QT_APPS" != "false" ]] && command -v kwriteconfig6 &>/dev/null; then
        mkdir -p "$HOME/.local/share/color-schemes"
        local scheme_name="Matugen-${mode_flag}"
        local scheme_file="$HOME/.local/share/color-schemes/${scheme_name}.colors"
        local scheme_alt="${scheme_name}2"
        local scheme_alt_file="$HOME/.local/share/color-schemes/${scheme_alt}.colors"
        cp "$XDG_CONFIG_HOME/kdeglobals" "$scheme_file" 2>/dev/null || true
        sed "s/ColorScheme=${scheme_name}/ColorScheme=${scheme_alt}/" \
            "$scheme_file" > "$scheme_alt_file" 2>/dev/null || true

        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Darkly" 2>/dev/null

        if command -v plasma-apply-colorscheme &>/dev/null; then
            dbus-send --session --dest=org.kde.KWin --type=method_call \
                /org/kde/KWin/BlendChanges org.kde.KWin.BlendChanges.start \
                int32:300 2>/dev/null || true

            # Alternate between two identical scheme copies to force reload
            local current_scheme
            current_scheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null) || current_scheme=""
            if [[ "$current_scheme" == "$scheme_name" ]]; then
                plasma-apply-colorscheme "$scheme_alt" 2>/dev/null
            fi
            plasma-apply-colorscheme "$scheme_name" 2>/dev/null
        else
            kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$scheme_name"
            dbus-send --session --type=signal /KGlobalSettings \
                org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
            dbus-send --session --type=signal /KGlobalSettings \
                org.kde.KGlobalSettings.notifyChange int32:2 int32:0 2>/dev/null || true
        fi

        dbus-send --session --dest=org.kde.KWin --type=method_call \
            /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi

    wait 2>/dev/null
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" &
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    fi
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"
    thumbnail_path=""

    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    read cursorposx cursorposy < <(hyprctl cursorpos -j | jq '.x, .y' | xargs)
    cursorposx=$(awk "BEGIN{printf \"%d\", ($cursorposx - $screenx) * $scale}")
    cursorposy=$(awk "BEGIN{printf \"%d\", ($cursorposy - $screeny) * $scale}")
    cursorposy_inverted=$((screensizey - cursorposy))

    if [[ "$color_flag" == "1" ]]; then
        matugen_args=(color hex "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo 'Aborted'
            exit 0
        fi

        kill_existing_mpvpaper

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            set_wallpaper_path "$imgpath"

            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
            for monitor in $monitors; do
                mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" &
                sleep 0.1
            done

            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null

            set_thumbnail_path "$thumbnail"
            thumbnail_path="$thumbnail"

            if [ -f "$thumbnail" ]; then
                matugen_args=(image "$thumbnail")
                create_restore_script "$video_path"
            else
                echo "Cannot create image to colorgen"
                remove_restore
                exit 1
            fi
        else
            matugen_args=(image "$imgpath")
            set_wallpaper_path "$imgpath"
            remove_restore
        fi
    fi

    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag")

    pre_process "$mode_flag"

    # Check if app and shell theming is enabled
    if [[ "$CFG_ENABLE_APPS_SHELL" == "false" ]]; then
        echo "App and shell theming disabled, skipping matugen and color generation"
        return
    fi

    # Save icon theme before matugen (matugen wipes kdeglobals [Icons])
    local _saved_icon_theme="$CFG_ICON_THEME"
    if [[ -z "$_saved_icon_theme" ]] && command -v kreadconfig6 &>/dev/null; then
        _saved_icon_theme=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null) || true
    fi

    matugen "${matugen_args[@]}"

    # Restore icon theme
    if [[ -n "$_saved_icon_theme" ]] && command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "$_saved_icon_theme" 2>/dev/null || true
    fi

    refresh_running_apps "$mode_flag" "$imgpath" "$thumbnail_path"
}

main() {
    kill_previous_instance
    read_config

    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""

    get_type_from_config() {
        echo "$CFG_PALETTE_TYPE"
    }
    get_accent_color_from_config() {
        echo "$CFG_ACCENT_COLOR"
    }
    set_accent_color() {
        local color="$1"
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
    }

    detect_scheme_type_from_image() {
        local img="$1" mcmd=""
        command -v magick &>/dev/null && mcmd=magick || { command -v convert &>/dev/null && mcmd=convert; }
        if [[ -n "$mcmd" ]]; then
            local sat
            sat=$($mcmd "$img" -resize 64x64! -colorspace HSL -channel G +channel -format "%[fx:mean]" info: 2>/dev/null)
            if [[ -n "$sat" ]] && awk "BEGIN{exit !($sat < 0.15)}"; then
                echo "scheme-neutral"; return
            fi
        fi
        echo "scheme-tonal-spot"
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                    shift 2
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                    shift 2
                else
                    set_accent_color $(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --image)
                imgpath="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                imgpath="$CFG_WALLPAPER_PATH"
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # Validate type_flag
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Prompt for wallpaper if none specified
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        cd "$(xdg-user-dir PICTURES)/Wallpapers/showcase" 2>/dev/null || cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"
    fi

    # Auto-detect scheme type from image
    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color"
}

main "$@"
