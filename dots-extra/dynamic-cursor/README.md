# DynamicCursors for Hyprland

## Installation

### Via hyprpm

```sh
hyprpm add https://github.com/VirtCode/hypr-dynamic-cursors
hyprpm enable dynamic-cursors
```

### Via NixOS (Flake)

Add the following to your flake inputs:

```nix
inputs = {
    hyprland.url = "github:hyprwm/Hyprland";
    hypr-dynamic-cursors.url = "github:VirtCode/hypr-dynamic-cursors";
    hypr-dynamic-cursors.inputs.hyprland.follows = "hyprland";
};
```

Then add to your Home Manager config:

```nix
wayland.windowManager.hyprland = {
    enable = true;
    plugins = [ inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors ];
};
```

Or via extraConfig:

```nix
wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
        plugin = ${inputs.hypr-dynamic-cursors.packages.${pkgs.system}.hypr-dynamic-cursors}/lib/libhypr-dynamic-cursors.so
    '';
};
```

## Configuration

No additional configuration is required! The plugin is pre-configured in the dotfiles with sensible defaults (tilt mode enabled, shake to find on, etc.). Simply install and enjoy. 

If you would like to configure anything, it can be done so inside of `~/.config/hypr/custom/general.conf`

For more details on available options, check the [repository](https://github.com/VirtCode/hypr-dynamic-cursors/tree/main).

## Credits

This plugin is created by VirtCode. All credit goes to the [author](https://github.com/VirtCode) for the development and maintenance of [hypr-dynamic-cursors](https://github.com/VirtCode/hypr-dynamic-cursors/tree/main).
