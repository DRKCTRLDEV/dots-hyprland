# SDDM Theme Integration

SDDM Integration with Illogical-Impulse Dots, Accents + Wallpaper.

This setup uses the [SilentSDDM](https://github.com/uiriansan/SilentSDDM) theme by uiriansan, customized with illogical-impulse colors and dynamic wallpaper support.

## Installation

### Install SilentSDDM Theme

<details>
<summary>Arch Linux</summary>

```bash
# Install SDDM and dependencies
sudo pacman -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia

# Install SilentSDDM theme from AUR
paru -S sddm-silent-theme-git

# Enable SDDM
sudo systemctl enable sddm

# Configure SDDM
sudo bash -c 'cat > /etc/sddm.conf <<EOF
[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=silent
EOF'
```

</details>

<details>
<summary>Fedora</summary>

```bash
# Install SDDM and dependencies
sudo dnf install sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia

# Install SilentSDDM theme
temp_dir=$(mktemp -d)
git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM "$temp_dir"
cd "$temp_dir"
./install.sh
rm -rf "$temp_dir"

# Enable SDDM
sudo systemctl enable sddm
```

</details>

<details>
<summary>Gentoo</summary>

```bash
# Install SDDM and dependencies
sudo emerge --ask sddm dev-qt/qt6-svg dev-qt/qt6-virtualkeyboard dev-qt/qt6-multimedia

# Install SilentSDDM theme
temp_dir=$(mktemp -d)
git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM "$temp_dir"
cd "$temp_dir"
./install.sh
rm -rf "$temp_dir"

# Enable SDDM
sudo systemctl enable sddm
```

</details>

<details>
<summary>NixOS</summary>

first include this flake into your flake inputs:
```nix
inputs = {
   silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
   };
};
```

Next, import the default nixosModule and set to enable
```nix
{
  inputs,
  ...
}: {
    imports = [inputs.silentSDDM.nixosModules.default];
    programs.silentSDDM = {
        enable = true;
        theme = "rei";
        # settings = { ... }; see example in module
    };
}
```
</details>

### Apply Illogical-Impulse Configuration

The SDDM theme script should automatically handle creating a new config and updating the metadata. The following commands are intended as a fallback if the script does not work as intended—only run them if required.

```bash
# Copy the custom illogical-impulse config (UNREQUIRED)
sudo cp /usr/share/sddm/themes/silent/configs/default.conf /usr/share/sddm/themes/silent/configs/illogical-impulse.conf

# Update metadata to use the custom config (UNREQUIRED)
sudo sed -i 's|ConfigFile=configs/default.conf|ConfigFile=configs/illogical-impulse.conf|' /usr/share/sddm/themes/silent/metadata.desktop
```
```bash
# Install sudoers snippet (REQUIRED)
sudo cp <path-to-99-sddm-theme-helper.sudoers> /etc/sudoers.d/99-sddm-theme-helper
sudo chmod 0440 /etc/sudoers.d/99-sddm-theme-helper
```

## Credits

- **SilentSDDM Theme**: Created by [uiriansan](https://github.com/uiriansan/SilentSDDM)
- **SDDM**: Simple Desktop Display Manager - [sddm-project.org](https://github.com/sddm/sddm)
