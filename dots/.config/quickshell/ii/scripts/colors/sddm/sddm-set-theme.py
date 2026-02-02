#!/usr/bin/env python3

import configparser
import grp
import json
import os
import shutil
import sys

def main():
    # Config
    SDDM_THEME_DIR = "/usr/share/sddm/themes/silent"
    SDDM_BG_DIR = f"{SDDM_THEME_DIR}/backgrounds"
    THEME_CONF = f"{SDDM_THEME_DIR}/configs/illogical-impulse.conf"
    DEFAULT_CONF = f"{SDDM_THEME_DIR}/configs/silvia.conf"
    METADATA = f"{SDDM_THEME_DIR}/metadata.desktop"

    # Get user info
    sudo_user = os.environ.get('SUDO_USER')
    if sudo_user:
        home = os.path.expanduser(f'~{sudo_user}')
        state_dir = os.environ.get('XDG_STATE_HOME', f'{home}/.local/state')
    else:
        home = os.path.expanduser('~')
        state_dir = os.environ.get('XDG_STATE_HOME', f'{home}/.local/state')

    colors_json = f"{state_dir}/quickshell/user/generated/colors.json"

    # Check permissions
    if sudo_user:
        try:
            user_groups = [g.gr_name for g in grp.getgrall() if sudo_user in g.gr_mem]
            if 'wheel' not in user_groups and 'sudo' not in user_groups:
                sys.exit(0)
        except:
            sys.exit(0)

    # Validate arguments
    if len(sys.argv) < 2 or len(sys.argv) > 3 or not os.path.isfile(sys.argv[1]) or not os.path.isdir(SDDM_THEME_DIR) or not os.path.isfile(colors_json):
        sys.exit(1)

    wallpaper = sys.argv[1]
    placeholder = sys.argv[2] if len(sys.argv) == 3 else None

    # Setup wallpaper
    ext = os.path.splitext(wallpaper)[1]
    wallpaper_dest = f"{SDDM_BG_DIR}/wallpaper{ext}"
    os.makedirs(SDDM_BG_DIR, exist_ok=True)
    shutil.copy2(wallpaper, wallpaper_dest)

    # Setup placeholder if provided
    if placeholder and os.path.isfile(placeholder):
        placeholder_basename = os.path.basename(placeholder)
        placeholder_dest = f"{SDDM_BG_DIR}/{placeholder_basename}"
        shutil.copy2(placeholder, placeholder_dest)

    # Ensure config exists
    if not os.path.isfile(THEME_CONF):
        shutil.copy2(DEFAULT_CONF, THEME_CONF)

    # Update metadata
    with open(METADATA, 'r') as f:
        content = f.read()
    content = content.replace('ConfigFile=configs/default.conf', 'ConfigFile=configs/illogical-impulse.conf')
    with open(METADATA, 'w') as f:
        f.write(content)

    # Load colors
    with open(colors_json) as f:
        colors = json.load(f)

    # Color mappings
    surface = colors['surface']
    on_surface = colors['on_surface']
    primary = colors['primary_container']  # Darker primary for dark scheme
    secondary = colors['secondary_container']  # Darker secondary
    text = colors.get('text', on_surface)
    outline = colors['outline']  # For borders
    surface_container = colors['surface_container']  # For input backgrounds
    surface_container_high = colors['surface_container_high']  # For popup backgrounds
    error = colors['error']  # For error messages

    # Config updates
    updates = {
        'General': {'animated-background-placeholder': placeholder_basename if placeholder else '""'},
        'LockScreen': {
            'background': f'"wallpaper{ext}"',
            'background-color': f'"{surface}"',
            'saturation': '0.2'
        },
        'LockScreen.Clock': {'color': f'"{text}"'},
        'LockScreen.Date': {'color': f'"{text}"'},
        'LockScreen.Message': {'color': f'"{text}"'},
        'LoginScreen': {
            'background': f'"wallpaper{ext}"',
            'background-color': f'"{surface}"'
        },
        'LoginScreen.LoginArea.Avatar': {
            'active-border-color': f'"{primary}"',
            'inactive-border-color': f'"{outline}"'
        },
        'LoginScreen.LoginArea.Username': {'color': f'"{text}"'},
        'LoginScreen.LoginArea.PasswordInput': {
            'content-color': f'"{text}"',
            'background-color': f'"{surface_container}"',
            'border-color': f'"{outline}"'
        },
        'LoginScreen.LoginArea.LoginButton': {
            'background-color': f'"{surface}"',
            'active-background-color': f'"{primary}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"',
            'border-color': f'"{outline}"'
        },
        'LoginScreen.LoginArea.Spinner': {'color': f'"{text}"'},
        'LoginScreen.LoginArea.WarningMessage': {
            'normal-color': f'"{text}"',
            'warning-color': f'"{primary}"',
            'error-color': f'"{error}"'
        },
        'LoginScreen.MenuArea.Popups': {
            'background-color': f'"{surface_container_high}"',
            'active-option-background-color': f'"{primary}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"',
            'border-color': f'"{outline}"'
        },
        'LoginScreen.MenuArea.Session': {
            'background-color': f'"{surface}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"'
        },
        'LoginScreen.MenuArea.Layout': {
            'background-color': f'"{surface}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"'
        },
        'LoginScreen.MenuArea.Keyboard': {
            'background-color': f'"{surface}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"'
        },
        'LoginScreen.MenuArea.Power': {
            'background-color': f'"{surface}"',
            'content-color': f'"{text}"',
            'active-content-color': f'"{text}"'
        },
        'LoginScreen.VirtualKeyboard': {
            'background-color': f'"{surface}"',
            'key-content-color': f'"{text}"',
            'key-color': f'"{surface_container}"',
            'key-active-background-color': f'"{primary}"',
            'selection-background-color': f'"{primary}"',
            'selection-content-color': f'"{text}"',
            'primary-color': f'"{primary}"',
            'border-color': f'"{outline}"'
        },
        'Tooltips': {
            'enable': 'false'
        },
    }

    # Apply config updates
    config = configparser.ConfigParser()
    config.read(THEME_CONF)
    for section, keys in updates.items():
        if not config.has_section(section):
            config.add_section(section)
        for key, value in keys.items():
            config.set(section, key, value)

    with open(THEME_CONF, 'w') as f:
        config.write(f)

if __name__ == '__main__':
    main()
