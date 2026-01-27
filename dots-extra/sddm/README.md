# SDDM Theme Integration

This directory contains files for integrating SDDM (Simple Desktop Display Manager) with the dots-hyprland theming system.

### installation

```bash
sudo cp path/to/99-sddm-theme-helper.sudoers /etc/sudoers.d/99-sddm-theme-helper
sudo chmod 0440 /etc/sudoers.d/99-sddm-theme-helper
```

### Testing

1. Verify installed files:

```bash
ls -l ~/.config/quickshell/ii/scripts/colors/sddm/sddm-set-theme.sh
sudo ls -l /etc/sudoers.d/99-sddm-theme-helper
```

2. Test a manual update (replace the path):

```bash
sudo ~/.config/quickshell/ii/scripts/colors/sddm/sddm-set-theme.sh update /path/to/wallpaper
```

3. Check logs for failures or diagnostics:

```bash
journalctl -e -t switchwall
journalctl -e -t sddm-set-theme
```

## Requirements

- SDDM display manager
- Sugar Candy SDDM theme (`sddm-sugar-candy-git` on Arch)
- Qt5 graphical effects and quick controls packages

## Manual Installation

If Sugar Candy is not automatically installed, you can install it manually:

**Arch Linux:**
```bash
paru -S sddm-sugar-candy-git
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

1. Ensure the Sugar Candy theme is installed at `/usr/share/sddm/themes/sugar-candy`.
2. Verify SDDM is configured to use Sugar Candy: check `/etc/sddm.conf.d/theme.conf`.
3. Ensure the sudoers snippet is installed: `/etc/sudoers.d/99-sddm-theme-helper`
4. Check that the helper is installed and executable: `sudo ls -l ~/.config/quickshell/ii/scripts/colors/sddm/sddm-set-theme.sh`.
5. Verify the per-user colors file exists and has valid keys: `~/.config/sddm/theme.conf`.
6. Inspect logs for errors:

```bash
journalctl -e -t switchwall
journalctl -e -t sddm-set-theme
```
