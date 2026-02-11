#!/usr/bin/env bash
# icon-accentize.sh — Material You icon accent colorizer
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
COLORS_JSON="$XDG_STATE_HOME/quickshell/user/generated/colors.json"
OVERLAY_BASE="$XDG_DATA_HOME/icons"
CACHE_DIR="$XDG_STATE_HOME/quickshell/icon-accent-cache"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"

get_icon_theme() {
    local theme=""
    if [[ -f "$SHELL_CONFIG_FILE" ]]; then
        local config_theme
        config_theme=$(jq -r '.appearance.iconTheme // empty' "$SHELL_CONFIG_FILE" 2>/dev/null) || true
        [[ -n "$config_theme" && "$config_theme" != "null" ]] && theme="$config_theme"
    fi
    if [[ -z "$theme" ]] && command -v kreadconfig6 &>/dev/null; then
        theme=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null) || true
    fi
    if [[ -z "$theme" ]]; then
        theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'") || true
    fi
    if [[ "$theme" == MaterialYou-* ]]; then
        local idx="$OVERLAY_BASE/$theme/index.theme"
        if [[ -f "$idx" ]]; then
            theme=$(grep '^Inherits=' "$idx" | head -1 | cut -d= -f2 | cut -d, -f1)
        else
            theme="breeze"
        fi
    fi
    theme="${theme%-dark}"
    theme="${theme%-Dark}"
    theme="${theme%-light}"
    theme="${theme%-Light}"
    echo "${theme:-breeze}"
}

find_theme_dir() {
    local theme="$1"
    for d in "$XDG_DATA_HOME/icons/$theme" "/usr/share/icons/$theme" "/usr/local/share/icons/$theme"; do
        [[ -d "$d" ]] && echo "$d" && return
    done
    echo ""
}

resolve_theme_variant() {
    local theme="$1" mode="$2"
    if [[ "$theme" == *-dark || "$theme" == *-Dark || "$theme" == *-light || "$theme" == *-Light ]]; then
        echo "$theme"
        return
    fi
    local variant="${theme}-${mode}"
    if [[ -n "$(find_theme_dir "$variant")" ]]; then
        echo "$variant"
        return
    fi
    variant="${theme}-${mode^}"
    if [[ -n "$(find_theme_dir "$variant")" ]]; then
        echo "$variant"
        return
    fi
    echo "$theme"
}

hex_to_rgb() {
    local h="${1#\#}"
    printf '%d %d %d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

rgb_to_hsl() {
    local r=$1 g=$2 b=$3
    awk -v r="$r" -v g="$g" -v b="$b" 'BEGIN {
        r/=255; g/=255; b/=255
        mx = r; if(g>mx) mx=g; if(b>mx) mx=b
        mn = r; if(g<mn) mn=g; if(b<mn) mn=b
        l = (mx+mn)/2; d = mx-mn
        if(d < 0.001) { h=0; s=0 }
        else {
            s = (l>0.5) ? d/(2-mx-mn) : d/(mx+mn)
            if(mx==r) h = (g-b)/d + (g<b?6:0)
            else if(mx==g) h = (b-r)/d + 2
            else h = (r-g)/d + 4
            h *= 60
        }
        printf "%d %d %d\n", h, s*1000, l*1000
    }'
}

hsl_to_rgb() {
    local h=$1 s=$2 l=$3
    awk -v h="$h" -v s="$s" -v l="$l" 'BEGIN {
        s/=1000; l/=1000
        if(s < 0.001) { r=g=b=l }
        else {
            q = (l<0.5) ? l*(1+s) : l+s-l*s
            p = 2*l - q
            hk = h/360
            tr = hk+1/3; tg = hk; tb = hk-1/3
            if(tr<0) tr+=1; if(tr>1) tr-=1
            if(tg<0) tg+=1; if(tg>1) tg-=1
            if(tb<0) tb+=1; if(tb>1) tb-=1
            r = (6*tr<1) ? p+(q-p)*6*tr : (2*tr<1) ? q : (3*tr<2) ? p+(q-p)*(2/3-tr)*6 : p
            g = (6*tg<1) ? p+(q-p)*6*tg : (2*tg<1) ? q : (3*tg<2) ? p+(q-p)*(2/3-tg)*6 : p
            b = (6*tb<1) ? p+(q-p)*6*tb : (2*tb<1) ? q : (3*tb<2) ? p+(q-p)*(2/3-tb)*6 : p
        }
        printf "%d %d %d\n", int(r*255+0.5), int(g*255+0.5), int(b*255+0.5)
    }'
}

rgb_to_hex() { printf '#%02x%02x%02x' "$1" "$2" "$3"; }

is_neutral() {
    local r=$1 g=$2 b=$3
    read -r _ s _ <<< "$(rgb_to_hsl "$r" "$g" "$b")"
    (( s < 80 ))
}

boost_saturation() {
    local hex="$1" min_s="${2:-700}"
    read -r r g b <<< "$(hex_to_rgb "$hex")"
    read -r h s l <<< "$(rgb_to_hsl "$r" "$g" "$b")"
    local new_s=$(( s * 13 / 10 ))
    (( new_s < min_s )) && new_s=$min_s
    (( new_s > 1000 )) && new_s=1000
    read -r nr ng nb <<< "$(hsl_to_rgb "$h" "$new_s" "$l")"
    rgb_to_hex "$nr" "$ng" "$nb"
}

is_breeze_family() {
    local theme_dir="$1"
    local sample=""
    sample=$(find -L "$theme_dir" -path "*/places/scalable/folder.svg" -print -quit 2>/dev/null)
    if [[ -z "$sample" ]]; then
        for sz in 64 48 32 22 24 16; do
            sample=$(find -L "$theme_dir" -path "*/places/${sz}/folder.svg" -print -quit 2>/dev/null)
            [[ -n "$sample" ]] && break
        done
    fi
    [[ -n "$sample" ]] && grep -q "ColorScheme-Accent" "$sample" 2>/dev/null
}

detect_accent_from_svg() {
    local svg="$1"
    grep -oE '#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?' "$svg" 2>/dev/null \
        | awk '{ h=tolower($0); sub(/^#/,"",h)
            if(length(h)==3) h=substr(h,1,1)substr(h,1,1)substr(h,2,1)substr(h,2,1)substr(h,3,1)substr(h,3,1)
            else if(length(h)!=6) next
            print "#"h }' \
        | sort | uniq -c | sort -rn | awk '
    function hex2dec(str,    i,v,c,d) {
        v=0; str=tolower(str)
        for(i=1;i<=length(str);i++) {
            c=substr(str,i,1)
            if(c>="0"&&c<="9") d=c+0
            else if(c=="a") d=10; else if(c=="b") d=11; else if(c=="c") d=12
            else if(c=="d") d=13; else if(c=="e") d=14; else if(c=="f") d=15
            else d=0; v=v*16+d
        }; return v
    }
    {
        hex=$2; h=substr(hex,2)
        r=hex2dec(substr(h,1,2)); g=hex2dec(substr(h,3,2)); b=hex2dec(substr(h,5,2))
        rf=r/255; gf=g/255; bf=b/255
        mx=rf; if(gf>mx)mx=gf; if(bf>mx)mx=bf
        mn=rf; if(gf<mn)mn=gf; if(bf<mn)mn=bf
        d=mx-mn
        if(d>=0.001){s=((mx+mn)/2>0.5)?d/(2-mx-mn):d/(mx+mn);if(s*1000>=80){print hex;exit}}
    }'
}

create_overlay() {
    local base_theme="$1" base_dir="$2" accent="$3" mode="$4"
    local overlay_name="MaterialYou-${mode^}" # MaterialYou-Dark or MaterialYou-Light
    local overlay_dir="$OVERLAY_BASE/$overlay_name"

    local m3_primary m3_primary_container m3_on_primary_container
    m3_primary="$accent"
    m3_primary_container=$(jq -r '.primary_container' "$COLORS_JSON")
    m3_on_primary_container=$(jq -r '.on_primary_container' "$COLORS_JSON")

    mkdir -p "$CACHE_DIR"
    local cache_key="$CACHE_DIR/${overlay_name}.key"
    local new_key="${base_theme}:${accent}"
    if [[ -f "$cache_key" ]] && [[ "$(cat "$cache_key")" == "$new_key" ]] && [[ -d "$overlay_dir" ]]; then
        echo "[icon-accentize] Cache hit for $overlay_name, skipping"
        return
    fi

    echo "[icon-accentize] Creating $overlay_name (base=$base_theme accent=$accent)"
    rm -rf "$overlay_dir"
    mkdir -p "$overlay_dir"

    local inherit_theme
    inherit_theme=$(resolve_theme_variant "$base_theme" "$mode")
    local inherit_theme_resolved="$inherit_theme"
    local base_index="$base_dir/index.theme"

    local breeze_mode=0
    local -a search_dirs=()
    for _d in "$base_dir"/places "$base_dir"/*/places; do
        [[ -d "$_d" ]] && search_dirs+=("$_d")
    done
    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        while IFS= read -r _d; do
            search_dirs+=("$_d")
        done < <(find -L "$base_dir" -type d -name "places" 2>/dev/null)
    fi

    local _sample=""
    _sample=$(find -L "${search_dirs[@]}" -name "folder.svg" -print -quit 2>/dev/null)
    [[ -n "$_sample" ]] && grep -q "ColorScheme-Accent" "$_sample" 2>/dev/null && breeze_mode=1

    local count=0

    if (( breeze_mode )); then
        local -a _breeze_files=()
        mapfile -t _breeze_files < <(find -L "${search_dirs[@]}" -name "*.svg" -print0 2>/dev/null \
            | xargs -0 grep -l "ColorScheme-Accent" 2>/dev/null)
        count=${#_breeze_files[@]}

        if (( count > 0 )); then
            local _nj; _nj=$(nproc)
            local _chunk=$(( (count + _nj - 1) / _nj ))
            for (( _i=0; _i<_nj; _i++ )); do
                (
                    local _s=$(( _i * _chunk )) _e=$(( (_i + 1) * _chunk ))
                    (( _e > count )) && _e=$count
                    for (( _j=_s; _j<_e; _j++ )); do
                        local svg="${_breeze_files[$_j]}"
                        local rel="${svg#"$base_dir/"}"
                        local dest="$overlay_dir/$rel"
                        mkdir -p "$(dirname "$dest")"
                        sed -E 's/(\.ColorScheme-Accent\s*\{\s*color\s*:\s*)#[0-9a-fA-F]{6}/\1'"${accent}"'/g' "$svg" > "$dest"
                    done
                ) &
            done
            wait
        fi
    else
        # Generic theme: 3-tone Material You recoloring
        local -a candidates=()
        mapfile -t candidates < <(find -L "${search_dirs[@]}" -name "folder.svg" 2>/dev/null)
        if [[ ${#candidates[@]} -eq 0 ]]; then
            echo "[icon-accentize] Warning: No folder.svg found in $base_theme, cannot detect accent"
            return 1
        fi

        local old_accent="" sample_svg=""
        for sample_svg in "${candidates[@]}"; do
            old_accent=$(detect_accent_from_svg "$sample_svg")
            [[ -n "$old_accent" ]] && break
        done
        if [[ -z "$old_accent" ]]; then
            echo "[icon-accentize] Warning: Could not detect accent color in $base_theme"
            return 1
        fi

        local tmp_dir="$CACHE_DIR/tmp.$$"
        mkdir -p "$tmp_dir"
        local sed_script="$tmp_dir/recolor.sed"
        local old_colors="$tmp_dir/old_colors.txt"

        read -r or og ob <<< "$(hex_to_rgb "$old_accent")"
        read -r old_hue _ _ <<< "$(rgb_to_hsl "$or" "$og" "$ob")"
        read -r _ _ m3_dark_l  <<< "$(rgb_to_hsl $(hex_to_rgb "$m3_primary_container"))"
        read -r _ _ m3_mid_l   <<< "$(rgb_to_hsl $(hex_to_rgb "$m3_primary"))"
        read -r _ _ m3_light_l <<< "$(rgb_to_hsl $(hex_to_rgb "$m3_on_primary_container"))"

        find -L "${search_dirs[@]}" -name "*.svg" \
            -exec grep -ohE '#[0-9a-fA-F]{3}([0-9a-fA-F]{3})?' {} + 2>/dev/null \
            | awk '{ h=tolower($0); sub(/^#/,"",h)
                if(length(h)==3) h=substr(h,1,1)substr(h,1,1)substr(h,2,1)substr(h,2,1)substr(h,3,1)substr(h,3,1)
                else if(length(h)!=6) next
                print "#"h }' | sort -u \
            | awk -v oh="$old_hue" \
                  -v m3_dark="$m3_primary_container" \
                  -v m3_mid="$m3_primary" \
                  -v m3_light="$m3_on_primary_container" \
                  -v m3_dark_l="$m3_dark_l" \
                  -v m3_mid_l="$m3_mid_l" \
                  -v m3_light_l="$m3_light_l" \
                  -v sed_file="$sed_script" -v old_file="$old_colors" '
        function hex2dec(str,    i,v,c,d) {
            v=0; str=tolower(str)
            for(i=1;i<=length(str);i++){
                c=substr(str,i,1)
                if(c>="0"&&c<="9") d=c+0
                else if(c=="a") d=10; else if(c=="b") d=11; else if(c=="c") d=12
                else if(c=="d") d=13; else if(c=="e") d=14; else if(c=="f") d=15
                else d=0; v=v*16+d
            }; return v
        }
        function do_rgb2hsl(r,g,b,    rf,gf,bf,mx,mn,lv,d,sv,hv) {
            rf=r/255; gf=g/255; bf=b/255
            mx=rf; if(gf>mx)mx=gf; if(bf>mx)mx=bf
            mn=rf; if(gf<mn)mn=gf; if(bf<mn)mn=bf
            lv=(mx+mn)/2; d=mx-mn
            if(d<0.001){H=0;S=0;L=int(lv*1000);return}
            sv=(lv>0.5)?d/(2-mx-mn):d/(mx+mn)
            if(mx==rf)hv=(gf-bf)/d+(gf<bf?6:0)
            else if(mx==gf)hv=(bf-rf)/d+2
            else hv=(rf-gf)/d+4
            hv*=60; H=int(hv); S=int(sv*1000); L=int(lv*1000)
        }
        function do_hsl2rgb(h,s,l,    sf,lf,q,p,hk,tr,tg,tb) {
            sf=s/1000; lf=l/1000
            if(sf<0.001){R=G=B=int(lf*255+0.5);return}
            q=(lf<0.5)?lf*(1+sf):lf+sf-lf*sf; p=2*lf-q; hk=h/360
            tr=hk+1/3; tg=hk; tb=hk-1/3
            if(tr<0)tr+=1;if(tr>1)tr-=1
            if(tg<0)tg+=1;if(tg>1)tg-=1
            if(tb<0)tb+=1;if(tb>1)tb-=1
            R=(6*tr<1)?p+(q-p)*6*tr:(2*tr<1)?q:(3*tr<2)?p+(q-p)*(2/3-tr)*6:p
            G=(6*tg<1)?p+(q-p)*6*tg:(2*tg<1)?q:(3*tg<2)?p+(q-p)*(2/3-tg)*6:p
            B=(6*tb<1)?p+(q-p)*6*tb:(2*tb<1)?q:(3*tb<2)?p+(q-p)*(2/3-tb)*6:p
            R=int(R*255+0.5); G=int(G*255+0.5); B=int(B*255+0.5)
        }
        function abs(x) { return (x<0)? -x : x }
        function lerp_color(hex_a, hex_b, t,    a1,a2,a3,b1,b2,b3) {
            # Linear interpolation between two hex colors (t=0..1000)
            sub(/^#/,"",hex_a); sub(/^#/,"",hex_b)
            a1=hex2dec(substr(hex_a,1,2)); a2=hex2dec(substr(hex_a,3,2)); a3=hex2dec(substr(hex_a,5,2))
            b1=hex2dec(substr(hex_b,1,2)); b2=hex2dec(substr(hex_b,3,2)); b3=hex2dec(substr(hex_b,5,2))
            R=int(a1+(b1-a1)*t/1000+0.5); G=int(a2+(b2-a2)*t/1000+0.5); B=int(a3+(b3-a3)*t/1000+0.5)
            if(R<0)R=0; if(R>255)R=255
            if(G<0)G=0; if(G>255)G=255
            if(B<0)B=0; if(B>255)B=255
            return sprintf("#%02x%02x%02x",R,G,B)
        }
        {
            hex=$0; sub(/^#/,"",hex)
            r=hex2dec(substr(hex,1,2))
            g=hex2dec(substr(hex,3,2))
            b=hex2dec(substr(hex,5,2))
            do_rgb2hsl(r,g,b)
            if(S<80) next
            pixel_l = L
            if(pixel_l <= m3_dark_l) {
                new_hex = m3_dark
            } else if(pixel_l <= m3_mid_l) {
                range = m3_mid_l - m3_dark_l
                if(range < 1) range = 1
                t = int((pixel_l - m3_dark_l) * 1000 / range)
                new_hex = lerp_color(m3_dark, m3_mid, t)
            } else if(pixel_l <= m3_light_l) {
                range = m3_light_l - m3_mid_l
                if(range < 1) range = 1
                t = int((pixel_l - m3_mid_l) * 1000 / range)
                new_hex = lerp_color(m3_mid, m3_light, t)
            } else {
                new_hex = m3_light
            }

            if(new_hex != "#"hex){
                printf "s/#%s/%s/gI\n",hex,new_hex > sed_file
                printf "#%s\n",hex > old_file
                if(substr(hex,1,1)==substr(hex,2,1) && substr(hex,3,1)==substr(hex,4,1) && substr(hex,5,1)==substr(hex,6,1))
                    printf "#%s%s%s\n",substr(hex,1,1),substr(hex,3,1),substr(hex,5,1) > old_file
            }
        }'

        if [[ -s "$sed_script" ]]; then
            local -a _generic_files=()
            mapfile -t _generic_files < <(find -L "${search_dirs[@]}" -name "*.svg" -print0 2>/dev/null \
                | xargs -0 grep -liFf "$old_colors" 2>/dev/null)
            count=${#_generic_files[@]}

            if (( count > 0 )); then
                local _combined_sed="$tmp_dir/combined.sed"
                {
                    echo 's/#\([0-9a-fA-F]\)\([0-9a-fA-F]\)\([0-9a-fA-F]\)\([^0-9a-fA-F]\)/#\1\1\2\2\3\3\4/g'
                    echo 's/#\([0-9a-fA-F]\)\([0-9a-fA-F]\)\([0-9a-fA-F]\)$/#\1\1\2\2\3\3/g'
                    cat "$sed_script"
                } > "$_combined_sed"
                printf '%s\n' "${_generic_files[@]}" \
                    | sed "s|^${base_dir}/||" \
                    | xargs -I{} dirname "$overlay_dir/{}" \
                    | sort -u | xargs mkdir -p

                local _nj; _nj=$(nproc)
                local _chunk=$(( (count + _nj - 1) / _nj ))
                for (( _i=0; _i<_nj; _i++ )); do
                    (
                        local _s=$(( _i * _chunk )) _e=$(( (_i + 1) * _chunk ))
                        (( _e > count )) && _e=$count
                        for (( _j=_s; _j<_e; _j++ )); do
                            local svg="${_generic_files[$_j]}"
                            local rel="${svg#"$base_dir/"}"
                            sed -f "$_combined_sed" "$svg" > "$overlay_dir/$rel"
                        done
                    ) &
                done
                wait
            fi
        fi

        rm -rf "$tmp_dir"
    fi

    cat > "$overlay_dir/index.theme" << EOF
[Icon Theme]
Name=$overlay_name
Comment=Material You accent-colored overlay (auto-generated)
Inherits=${inherit_theme_resolved},hicolor
FollowsColorScheme=true
EOF

    local overlay_actual_dirs=""
    if [[ -d "$overlay_dir" ]]; then
        overlay_actual_dirs=$(find "$overlay_dir" -name "*.svg" -printf '%h\n' 2>/dev/null \
            | sed "s|^${overlay_dir}/||" | sort -u | tr '\n' ',')
        overlay_actual_dirs="${overlay_actual_dirs%,}"
    fi

    if [[ -n "$overlay_actual_dirs" && -f "$base_index" ]]; then
        local valid_dirs="" section_defs=""
        local IFS=','
        for dir_entry in $overlay_actual_dirs; do
            local sec
            sec=$(awk -v section="[$dir_entry]" '
                $0 == section { found=1; print; next }
                found && /^\[/ { found=0 }
                found { print }
            ' "$base_index" 2>/dev/null)
            if [[ -n "$sec" ]]; then
                valid_dirs="${valid_dirs:+$valid_dirs,}$dir_entry"
                section_defs+="[$dir_entry]"$'\n'"$sec"$'\n\n'
            else
                echo "[icon-accentize] Warning: No [$dir_entry] section in base index.theme, skipping"
            fi
        done
        unset IFS

        if [[ -n "$valid_dirs" ]]; then
            echo "Directories=$valid_dirs" >> "$overlay_dir/index.theme"
            echo "" >> "$overlay_dir/index.theme"
            printf '%s' "$section_defs" >> "$overlay_dir/index.theme"
        fi
    elif [[ -f "$base_index" ]]; then
        grep '^Directories=' "$base_index" >> "$overlay_dir/index.theme" || true
        grep '^ScaledDirectories=' "$base_index" >> "$overlay_dir/index.theme" 2>/dev/null || true
        echo "" >> "$overlay_dir/index.theme"
        awk '
            /^\[Icon Theme\]/ { skip=1; next }
            /^\[.+\]/ { skip=0 }
            !skip { print }
        ' "$base_index" >> "$overlay_dir/index.theme" 2>/dev/null || true
    fi

    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f -t "$overlay_dir" 2>/dev/null || true
    fi

    echo "$new_key" > "$cache_key"
    echo "[icon-accentize] Processed $count SVGs for $overlay_name"
}


apply_overlay() {
    local mode="$1" base_theme="$2"
    local overlay_name="MaterialYou-${mode^}"

    # GTK icon theme
    gsettings set org.gnome.desktop.interface icon-theme "$overlay_name" 2>/dev/null || true
    
    # Force GTK apps to reload by toggling theme
    local current_gtk_theme
    current_gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'") || current_gtk_theme="adw-gtk3-${mode}"
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme "$current_gtk_theme" 2>/dev/null || true

    # GTK4/libadwaita: toggle color-scheme to trigger SettingChanged
    (
        local current_cs
        current_cs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'") || current_cs="prefer-dark"
        gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
        sleep 0.1
        gsettings set org.gnome.desktop.interface color-scheme "$current_cs" 2>/dev/null || true
    ) &

    # KDE icon theme
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme "$overlay_name" 2>/dev/null || true
        
        # Force Qt/KDE apps to reload by toggling widget style
        local current_style
        current_style=$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle 2>/dev/null) || current_style="Darkly"
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Breeze" 2>/dev/null || true
        sleep 0.05
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "$current_style" 2>/dev/null || true
    fi

    if command -v flatpak &>/dev/null; then
        flatpak override --user --env=ICON_THEME="$overlay_name" 2>/dev/null &
    fi

    # Signal Qt/KDE apps to reload icons - comprehensive approach
    dbus-send --session --type=signal /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
    dbus-send --session --type=signal /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:2 int32:0 2>/dev/null || true
    dbus-send --session --type=signal /KGlobalSettings \
        org.kde.KGlobalSettings.notifyChange int32:4 int32:0 2>/dev/null || true
    for group in 0 1 2 3 4 5 6; do
        dbus-send --session --type=signal /KIconLoader \
            org.kde.KIconLoader.iconChanged int32:$group 2>/dev/null || true
    done

    # Force KWin to reconfigure
    dbus-send --session --dest=org.kde.KWin --type=method_call \
        /KWin org.kde.KWin.reconfigure 2>/dev/null || true

    if command -v kbuildsycoca6 &>/dev/null; then
        kbuildsycoca6 --noincremental 2>/dev/null &
    fi

    wait 2>/dev/null
}


main() {
    [[ -f "$COLORS_JSON" ]] || { echo "[icon-accentize] No colors.json found"; exit 1; }

    local accent
    accent=$(jq -r '.primary' "$COLORS_JSON")
    [[ -z "$accent" || "$accent" == "null" ]] && { echo "[icon-accentize] No primary color in colors.json"; exit 1; }
    accent=$(boost_saturation "$accent" 600)

    local mode
    local cs
    cs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'") || cs=""
    if [[ "$cs" == "prefer-dark" ]]; then
        mode="dark"
    else
        mode="light"
    fi

    local base_theme
    base_theme=$(get_icon_theme)
    local source_theme
    source_theme=$(resolve_theme_variant "$base_theme" "$mode")
    local base_dir
    base_dir=$(find_theme_dir "$source_theme")
    if [[ -z "$base_dir" ]]; then
        base_dir=$(find_theme_dir "$base_theme")
    fi

    if [[ -z "$base_dir" ]]; then
        echo "[icon-accentize] Cannot find icon theme directory for '$base_theme'"
        exit 1
    fi

    create_overlay "$base_theme" "$base_dir" "$accent" "$mode"
    apply_overlay "$mode" "$base_theme"
}

main "$@"
