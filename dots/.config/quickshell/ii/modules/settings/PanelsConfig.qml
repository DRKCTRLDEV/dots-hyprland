import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Sidebars section
    ContentSection {
        icon: "view_sidebar"
        title: Translation.tr("Sidebars")

        ConfigSwitch {
            buttonIcon: "memory"
            text: Translation.tr("Keep right sidebar loaded")
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                text: Translation.tr("Keeps the right sidebar content in memory to reduce opening delay.\nUses ~15MB extra RAM. Recommended for slower systems or if you open it frequently.")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "translate"
                text: Translation.tr("Enable translator widget")
                checked: Config.options.sidebar.translator.enable
                onCheckedChanged: {
                    Config.options.sidebar.translator.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Show the translator panel in the right sidebar")
                }
            }
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Request delay (ms)")
                enabled: Config.options.sidebar.translator.enable
                value: Config.options.sidebar.translator.delay
                from: 0
                to: 2000
                stepSize: 50
                onValueChanged: {
                    Config.options.sidebar.translator.delay = value;
                }
                StyledToolTip {
                    text: Translation.tr("Delay before sending translation requests after typing stops.\nHigher values reduce rate limiting and network load.")
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "mouse"
                text: Translation.tr("Enable mouse configuration")
                checked: Config.options.sidebar.mouseConfig.enable
                onCheckedChanged: {
                    Config.options.sidebar.mouseConfig.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Show mouse DPI/sensitivity controls in the sidebar")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.sidebar.mouseConfig.enable
                icon: "speed"
                text: Translation.tr("Max DPI limit")
                value: Config.options.sidebar.mouseConfig.maxDpi
                from: 1000
                to: 12000
                stepSize: 500
                onValueChanged: {
                    Config.options.sidebar.mouseConfig.maxDpi = value;
                }
                StyledToolTip {
                    text: Translation.tr("Maximum DPI value for the mouse sensitivity slider in the sidebar")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")
            tooltip: Translation.tr("Style and layout of the quick toggle buttons in the sidebar")

            ConfigRow {
                uniform: false
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    currentValue: Config.options.sidebar.quickToggles.style
                    onSelected: newValue => {
                        Config.options.sidebar.quickToggles.style = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Classic"), icon: "password_2", value: "classic" },
                        { displayName: Translation.tr("Android"), icon: "action_key", value: "android" }
                    ]
                }

                ConfigSpinBox {
                    enabled: Config.options.sidebar.quickToggles.style === "android"
                    icon: "splitscreen_left"
                    text: Translation.tr("Columns")
                    value: Config.options.sidebar.quickToggles.android.columns
                    from: 1
                    to: 8
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.quickToggles.android.columns = value;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick sliders")
            tooltip: Translation.tr("Toggle which sliders appear in the sidebar control panel")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable sliders")
                checked: Config.options.sidebar.quickSliders.enable
                onCheckedChanged: {
                    Config.options.sidebar.quickSliders.enable = checked;
                }
            }

            ConfigRow {
                uniform: true
                enabled: Config.options.sidebar.quickSliders.enable
                ConfigSwitch {
                    buttonIcon: "brightness_6"
                    text: Translation.tr("Brightness")
                    checked: Config.options.sidebar.quickSliders.showBrightness
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showBrightness = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "volume_up"
                    text: Translation.tr("Volume")
                    checked: Config.options.sidebar.quickSliders.showVolume
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showVolume = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "mic"
                    text: Translation.tr("Microphone")
                    checked: Config.options.sidebar.quickSliders.showMic
                    onCheckedChanged: {
                        Config.options.sidebar.quickSliders.showMic = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")
            tooltip: Translation.tr("Open sidebars by clicking or hovering at screen corners, independent of bar position")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable corner triggers")
                checked: Config.options.sidebar.cornerOpen.enable
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.enable = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to trigger (no click needed)")
                enabled: Config.options.sidebar.cornerOpen.enable
                checked: Config.options.sidebar.cornerOpen.clickless
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.clickless = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Open sidebars just by hovering the corner, without clicking")
                }
            }

            ConfigSwitch {
                buttonIcon: "vertical_align_bottom"
                text: Translation.tr("Place at bottom of screen")
                enabled: Config.options.sidebar.cornerOpen.enable
                checked: Config.options.sidebar.cornerOpen.bottom
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.bottom = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "unfold_more_double"
                text: Translation.tr("Volume/brightness scroll in corner region")
                enabled: Config.options.sidebar.cornerOpen.enable
                checked: Config.options.sidebar.cornerOpen.valueScroll
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.valueScroll = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Scroll in the corner region to adjust brightness or volume")
                }
            }

            Row {
                enabled: Config.options.sidebar.cornerOpen.enable
                ConfigSwitch {
                    enabled: !Config.options.sidebar.cornerOpen.clickless
                    text: Translation.tr("Force hover open at absolute corner")
                    checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("When hover-to-trigger is off, still allow hovering the very corner to open.\nThe rest of the region is used for volume/brightness scroll.")
                    }
                }
            }
        }
    }

    // Notifications section
    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Default timeout (ms)")
            value: Config.options.notifications.timeout
            from: 1000
            to: 60000
            stepSize: 1000
            onValueChanged: {
                Config.options.notifications.timeout = value;
            }
            StyledToolTip {
                text: Translation.tr("How long notifications remain on screen if the app doesn't specify a duration")
            }
        }
    }

    // OSD section
    ContentSection {
        icon: "voting_chip"
        title: Translation.tr("On-Screen Display")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Timeout (ms)")
            value: Config.options.osd.timeout
            from: 100
            to: 3000
            stepSize: 100
            onValueChanged: {
                Config.options.osd.timeout = value;
            }
            StyledToolTip {
                text: Translation.tr("How long the OSD (volume/brightness indicator) stays visible")
            }
        }
    }

    // Overlay section
    ContentSection {
        icon: "select_window"
        title: Translation.tr("Overlays")

        ConfigSwitch {
            buttonIcon: "high_density"
            text: Translation.tr("Opening zoom animation")
            checked: Config.options.overlay.openingZoomAnimation
            onCheckedChanged: {
                Config.options.overlay.openingZoomAnimation = checked;
            }
            StyledToolTip {
                text: Translation.tr("Play a zoom animation when opening overlays like the launcher or overview")
            }
        }

        ConfigSwitch {
            buttonIcon: "texture"
            text: Translation.tr("Darken screen behind overlays")
            checked: Config.options.overlay.darkenScreen
            onCheckedChanged: {
                Config.options.overlay.darkenScreen = checked;
            }
        }

        ConfigSpinBox {
            icon: "opacity"
            text: Translation.tr("Click-through opacity (%)")
            value: Math.round(Config.options.overlay.clickthroughOpacity * 100)
            from: 10
            to: 100
            stepSize: 5
            onValueChanged: {
                Config.options.overlay.clickthroughOpacity = value / 100;
            }
            StyledToolTip {
                text: Translation.tr("Opacity level when an overlay is in click-through mode")
            }
        }
    }
}
