import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Appearance
    ContentSection {
        icon: "palette"
        title: Translation.tr("Appearance")

        ContentSubsection {
            title: Translation.tr("Accent color override")
            tooltip: Translation.tr("Set a custom accent color hex (e.g. #FF5733). Leave empty to derive from wallpaper.")

            MaterialTextArea {
                placeholderText: Translation.tr("Hex color (e.g. #4285F4) or leave empty")
                text: Config.options.appearance.palette.accentColor
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.palette.accentColor = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Fake screen round corners")
            tooltip: Translation.tr("Draws rounded corners over the screen edges. Useful for displays without physical rounded corners.")

            ConfigSelectionArray {
                currentValue: Config.options.appearance.fakeScreenRounding
                onSelected: newValue => {
                    Config.options.appearance.fakeScreenRounding = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Off"),
                        icon: "close",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Always"),
                        icon: "check",
                        value: 1
                    },
                    {
                        displayName: Translation.tr("When not fullscreen"),
                        icon: "fullscreen_exit",
                        value: 2
                    }
                ]
            }
        }
    }

    // Window decoration
    ContentSection {
        icon: "web_asset"
        title: Translation.tr("Window Decoration")

        ConfigSwitch {
            buttonIcon: "title"
            text: Translation.tr("Show titlebar in shell apps")
            checked: Config.options.windows.showTitlebar
            onCheckedChanged: {
                Config.options.windows.showTitlebar = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show a client-side titlebar in shell applications like this settings window")
            }
        }

        ConfigSwitch {
            buttonIcon: "format_align_center"
            text: Translation.tr("Center title text")
            enabled: Config.options.windows.showTitlebar
            checked: Config.options.windows.centerTitle
            onCheckedChanged: {
                Config.options.windows.centerTitle = checked;
            }
        }
    }

    // Clock
    ContentSection {
        icon: "schedule"
        title: Translation.tr("Clock")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show seconds in all clocks. Increases update frequency.")
            }
        }
    }

    // System tray
    ContentSection {
        icon: "select_window"
        title: Translation.tr("System Tray")

        ConfigSwitch {
            buttonIcon: "label"
            text: Translation.tr("Show tray item IDs")
            checked: Config.options.tray.showItemId
            onCheckedChanged: {
                Config.options.tray.showItemId = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display the internal identifier of each system tray item.\nUseful for configuring the pinned items list.")
            }
        }
    }

    // Sidebar corner trigger
    ContentSection {
        icon: "swipe_right_alt"
        title: Translation.tr("Sidebar Corner Trigger")

        ConfigSwitch {
            buttonIcon: "visibility"
            text: Translation.tr("Visualize trigger region")
            checked: Config.options.sidebar.cornerOpen.visualize
            onCheckedChanged: {
                Config.options.sidebar.cornerOpen.visualize = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show the corner trigger region on screen for positioning reference")
            }
        }

        ConfigRow {
            enabled: Config.options.sidebar.cornerOpen.enable
            ConfigSpinBox {
                icon: "arrow_cool_down"
                text: Translation.tr("Vertical offset")
                value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                from: 0
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value;
                }
                StyledToolTip {
                    text: Translation.tr("Prevents triggering when approaching along the horizontal edge.\nHigher values require approaching more from the vertical edge.")
                }
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.sidebar.cornerOpen.enable
            ConfigSpinBox {
                icon: "arrow_range"
                text: Translation.tr("Region width")
                value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                from: 1
                to: 300
                stepSize: 10
                onValueChanged: {
                    Config.options.sidebar.cornerOpen.cornerRegionWidth = value;
                }
            }
            ConfigSpinBox {
                icon: "height"
                text: Translation.tr("Region height")
                value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                from: 1
                to: 300
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.cornerOpen.cornerRegionHeight = value;
                }
            }
        }
    }

    // Conflict killer
    ContentSection {
        icon: "gavel"
        title: Translation.tr("Conflict Killer")

        ConfigSwitch {
            buttonIcon: "notifications_off"
            text: Translation.tr("Auto-kill notification daemons")
            checked: Config.options.conflictKiller.autoKillNotificationDaemons
            onCheckedChanged: {
                Config.options.conflictKiller.autoKillNotificationDaemons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically kill other notification daemons (e.g. dunst, mako) that may conflict with the shell")
            }
        }

        ConfigSwitch {
            buttonIcon: "shelf_auto_hide"
            text: Translation.tr("Auto-kill system trays")
            checked: Config.options.conflictKiller.autoKillTrays
            onCheckedChanged: {
                Config.options.conflictKiller.autoKillTrays = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically kill other system tray implementations that may conflict")
            }
        }
    }

    // Hacks & workarounds
    ContentSection {
        icon: "build"
        title: Translation.tr("Hacks & Workarounds")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Race condition delay (ms)")
            value: Config.options.hacks.arbitraryRaceConditionDelay
            from: 0
            to: 500
            stepSize: 5
            onValueChanged: {
                Config.options.hacks.arbitraryRaceConditionDelay = value;
            }
            StyledToolTip {
                text: Translation.tr("An arbitrary delay to work around timing issues in Hyprland IPC.\nIncrease this if you experience glitches on startup.")
            }
        }

        ConfigSwitch {
            buttonIcon: "mouse"
            text: Translation.tr("Dead pixel workaround")
            checked: Config.options.interactions.deadPixelWorkaround.enable
            onCheckedChanged: {
                Config.options.interactions.deadPixelWorkaround.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hyprland may leave 1 pixel on the right edge unresponsive to interactions.\nEnable this to work around that issue.")
            }
        }

        ConfigSwitch {
            buttonIcon: "folder_open"
            text: Translation.tr("Use system file picker for wallpaper")
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.useSystemFileDialog = checked;
            }
            StyledToolTip {
                text: Translation.tr("Use the native system file dialog instead of the built-in wallpaper browser.\nMay be needed if the built-in browser has issues on your system.")
            }
        }
    }
}
