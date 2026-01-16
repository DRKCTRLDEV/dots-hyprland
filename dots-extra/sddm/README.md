# SDDM Theme Integration

This directory contains files for integrating SDDM (Simple Desktop Display Manager) with the dots-hyprland theming system.

## Components

### 49-sddm-theme-helper.rules
A polkit rule that allows members of the `wheel` group to run the `sddm-theme-helper` script without authentication. This enables automatic SDDM theme updates when changing wallpapers.

## How It Works

1. When you change wallpapers using the wallpaper selector, matugen generates theme colors
2. The colors are saved to `~/.config/sddm/theme.conf.user` via matugen template
3. The `sddm-theme-helper` script (in `~/.config/quickshell/ii/scripts/`) is called via pkexec
4. The script copies the colors and wallpaper to the Sugar Candy theme directory

## Requirements

- SDDM display manager
- Sugar Candy SDDM theme (`sddm-sugar-candy-git` on Arch)
- Qt5 graphical effects and quick controls packages

## Manual Installation

If Sugar Candy is not automatically installed, you can install it manually:

**Arch Linux:**
```bash
yay -S sddm-sugar-candy-git
```

**Fedora:**
Sugar Candy needs to be installed from source. See: https://github.com/Kangie/sddm-sugar-candy

## Configuration

You can disable SDDM theming in the Quickshell config:
```json
{
  "appearance": {
    "wallpaperTheming": {
      "enableSddm": false
    }
  }
}
```

## Troubleshooting

If SDDM theming doesn't work:

1. Ensure Sugar Candy theme is installed at `/usr/share/sddm/themes/sugar-candy`
2. Verify SDDM is configured to use Sugar Candy: check `/etc/sddm.conf.d/theme.conf`
3. Make sure the polkit rule is installed: `/etc/polkit-1/rules.d/49-sddm-theme-helper.rules`
4. Check that the sddm-theme-helper script is executable
