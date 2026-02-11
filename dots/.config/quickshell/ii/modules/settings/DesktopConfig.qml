import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Background section
    ContentSection {
        icon: "texture"
        title: Translation.tr("Background")

        ConfigSwitch {
            buttonIcon: "fullscreen"
            text: Translation.tr("Hide wallpaper when fullscreen")
            checked: Config.options.background.hideWhenFullscreen
            onCheckedChanged: {
                Config.options.background.hideWhenFullscreen = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hides the wallpaper layer when a window is in fullscreen mode to save resources")
            }
        }
    }

    // Dock section
    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable dock")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show a dock at the bottom of the screen with pinned and running applications")
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.dock.enable
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Show dock when hovering over the bottom edge.\nWhen disabled, dock only shows on empty workspaces.")
                }
            }
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Always show the dock when the session starts")
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr("Tint app icons")
            enabled: Config.options.dock.enable
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Apply a monochrome tint to dock application icons to match the current theme")
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.dock.enable
            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Height (px)")
                value: Config.options.dock.height
                from: 30
                to: 120
                stepSize: 5
                onValueChanged: {
                    Config.options.dock.height = value;
                }
                StyledToolTip {
                    text: Translation.tr("Height of the dock in pixels")
                }
            }
            ConfigSpinBox {
                icon: "arrow_range"
                text: Translation.tr("Hover region height (px)")
                value: Config.options.dock.hoverRegionHeight
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.dock.hoverRegionHeight = value;
                }
                StyledToolTip {
                    text: Translation.tr("Height of the invisible hover region at the screen edge that triggers the dock")
                }
            }
        }
    }

    // Overview section
    ContentSection {
        icon: "overview_key"
        title: Translation.tr("Overview")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable workspace overview")
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable the workspace overview grid, accessible via the overview key")
            }
        }

        ConfigSwitch {
            buttonIcon: "center_focus_strong"
            text: Translation.tr("Center window icons")
            enabled: Config.options.overview.enable
            checked: Config.options.overview.centerIcons
            onCheckedChanged: {
                Config.options.overview.centerIcons = checked;
            }
        }

        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            enabled: Config.options.overview.enable
            value: Config.options.overview.scale * 100
            from: 1
            to: 100
            stepSize: 1
            onValueChanged: {
                Config.options.overview.scale = value / 100;
            }
            StyledToolTip {
                text: Translation.tr("Size of workspace previews relative to screen size")
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.overview.enable
            ConfigSpinBox {
                icon: "splitscreen_bottom"
                text: Translation.tr("Rows")
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.rows = value;
                }
            }
            ConfigSpinBox {
                icon: "splitscreen_right"
                text: Translation.tr("Columns")
                value: Config.options.overview.columns
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.columns = value;
                }
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.overview.enable
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderRightLeft
                onSelected: newValue => {
                    Config.options.overview.orderRightLeft = newValue;
                }
                options: [
                    { displayName: Translation.tr("Left to right"), icon: "arrow_forward", value: 0 },
                    { displayName: Translation.tr("Right to left"), icon: "arrow_back", value: 1 }
                ]
            }
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderBottomUp
                onSelected: newValue => {
                    Config.options.overview.orderBottomUp = newValue;
                }
                options: [
                    { displayName: Translation.tr("Top-down"), icon: "arrow_downward", value: 0 },
                    { displayName: Translation.tr("Bottom-up"), icon: "arrow_upward", value: 1 }
                ]
            }
        }
    }

    // Lock screen section
    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock Screen")

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: Translation.tr("Launch on startup")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show the lock screen when the session starts.\nUseful if not using a display manager that handles login.")
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: Translation.tr("Require password to power off/restart")
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Adds a password prompt before power off or restart from the lock screen.\nNote: physical power buttons can always force shutdown.")
                }
            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: Translation.tr("Also unlock keyring")
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Unlocks your GNOME Keyring when unlocking the screen.\nNeeded for browsers and apps that store passwords.\nRecommended if using lock on startup instead of a display manager.")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Appearance")

            ConfigSwitch {
                buttonIcon: "shapes"
                text: Translation.tr("Use varying shapes for password characters")
                checked: Config.options.lock.materialShapeChars
                onCheckedChanged: {
                    Config.options.lock.materialShapeChars = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Display Material Design shape icons instead of dots for password entry")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Blur effect")

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Enable blur")
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
            }

            ConfigSpinBox {
                icon: "blur_circular"
                text: Translation.tr("Blur radius")
                enabled: Config.options.lock.blur.enable
                value: Config.options.lock.blur.radius
                from: 0
                to: 200
                stepSize: 10
                onValueChanged: {
                    Config.options.lock.blur.radius = value;
                }
                StyledToolTip {
                    text: Translation.tr("Strength of the blur effect behind the lock screen")
                }
            }

            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Extra wallpaper zoom (%)")
                enabled: Config.options.lock.blur.enable
                value: Config.options.lock.blur.extraZoom * 100
                from: 100
                to: 150
                stepSize: 2
                onValueChanged: {
                    Config.options.lock.blur.extraZoom = value / 100;
                }
                StyledToolTip {
                    text: Translation.tr("Zooms the wallpaper slightly to hide blur edge artifacts")
                }
            }
        }
    }
}
