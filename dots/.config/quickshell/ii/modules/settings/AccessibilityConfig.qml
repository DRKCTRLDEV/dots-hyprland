import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: hyprAnimToggle
        property bool reduceMotion: Config.options.accessibility.reduceMotion
        onReduceMotionChanged: {
            if (reduceMotion) {
                hyprAnimToggle.command = ["hyprctl", "keyword", "animations:enabled", "0"];
            } else {
                hyprAnimToggle.command = ["hyprctl", "keyword", "animations:enabled", "1"];
            }
            hyprAnimToggle.running = true;
        }
    }

    ContentSection {
        icon: "visibility"
        title: Translation.tr("Visual")

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Enable transparency effects")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Disable transparency for better readability and reduced visual complexity.\nUseful for users who find translucent elements distracting.")
            }
        }

        ConfigSwitch {
            buttonIcon: "high_density"
            text: Translation.tr("Reduce motion")
            checked: Config.options.accessibility.reduceMotion
            onCheckedChanged: {
                Config.options.accessibility.reduceMotion = checked;
                // Also disable overlay zoom animation
                Config.options.overlay.openingZoomAnimation = !checked;
            }
            StyledToolTip {
                text: Translation.tr("Disables animations across the shell, Hyprland compositor, and overlays.\nRecommended for users sensitive to motion effects or for performance.")
            }
        }

        ConfigSwitch {
            buttonIcon: "texture"
            text: Translation.tr("Darken screen behind overlays")
            checked: Config.options.overlay.darkenScreen
            onCheckedChanged: {
                Config.options.overlay.darkenScreen = checked;
            }
            StyledToolTip {
                text: Translation.tr("Dims background content when overlays are open.\nImproves focus and readability of overlay content.")
            }
        }

    }

    ContentSection {
        icon: "touch_app"
        title: Translation.tr("Interaction")

        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show tooltips")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
            StyledToolTip {
                text: Translation.tr("Require a click to reveal tooltips instead of hover.\nUseful for touchscreen or accessibility needs.")
            }
        }

        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Faster touchpad scrolling")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: {
                Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
            }
            StyledToolTip {
                text: Translation.tr("Increases scroll sensitivity for touchpad users in shell elements")
            }
        }
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("On-Screen Keyboard")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Show on startup")
                checked: Config.options.osk.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.osk.pinnedOnStartup = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "keyboard_full"
                text: Translation.tr("Use full keyboard layout")
                checked: Config.options.osk.layout === "qwerty_full"
                onCheckedChanged: {
                    Config.options.osk.layout = checked ? "qwerty_full" : "qwerty_compact";
                }
                StyledToolTip {
                    text: Translation.tr("Full layout shows all keys including numbers and symbols.\nDisable for a compact layout with only letters.")
                }
            }
        }
    }

    ContentSection {
        icon: "flash_off"
        title: Translation.tr("Comfort")

        ConfigSwitch {
            buttonIcon: "flash_off"
            text: Translation.tr("Anti-flashbang screen dim on wake")
            checked: Config.options.light.antiFlashbang.enable
            onCheckedChanged: {
                Config.options.light.antiFlashbang.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Briefly dim the screen when waking from sleep to protect eyes from sudden brightness.\nEspecially helpful in dark environments.")
            }
        }

    }

    ContentSection {
        icon: "hearing"
        title: Translation.tr("Volume Normalization")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Enable volume normalization")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents sudden volume spikes and limits maximum volume.\nProtects hearing when switching between quiet and loud content.")
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max step increase (%)")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
                StyledToolTip {
                    text: Translation.tr("Maximum volume increase allowed in a single step")
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume ceiling (%)")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
                StyledToolTip {
                    text: Translation.tr("Absolute maximum volume level (up to 153% for amplified output)")
                }
            }
        }
    }
}
