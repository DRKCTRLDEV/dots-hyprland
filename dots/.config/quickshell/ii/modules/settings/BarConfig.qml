import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Positioning section
    ContentSection {
        icon: "spoke"
        title: Translation.tr("Position & Layout")

        ConfigRow {
            uniform: true
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Bar position")

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        { displayName: Translation.tr("Top"), icon: "arrow_upward", value: 0 },
                        { displayName: Translation.tr("Left"), icon: "arrow_back", value: 2 },
                        { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: 1 },
                        { displayName: Translation.tr("Right"), icon: "arrow_forward", value: 3 }
                    ]
                }
            }
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Auto-hide")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Off"), icon: "close", value: false },
                        { displayName: Translation.tr("On"), icon: "check", value: true }
                    ]
                }
            }
        }

        ConfigRow {
            uniform: true
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Corner style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Hug"), icon: "line_curve", value: 0 },
                        { displayName: Translation.tr("Float"), icon: "page_header", value: 1 },
                        { displayName: Translation.tr("Rect"), icon: "toolbar", value: 2 }
                    ]
                }
            }
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Group style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue;
                    }
                    options: [
                        { displayName: Translation.tr("Pills"), icon: "location_chip", value: false },
                        { displayName: Translation.tr("Line-separated"), icon: "split_scene", value: true }
                    ]
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "shadow"
            text: Translation.tr("Show shadow behind floating bar")
            enabled: Config.options.bar.cornerStyle === 1
            checked: Config.options.bar.floatStyleShadow
            onCheckedChanged: {
                Config.options.bar.floatStyleShadow = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display a drop shadow behind the bar when using Float corner style")
            }
        }

        ConfigSwitch {
            buttonIcon: "gradient"
            text: Translation.tr("Show bar background")
            checked: Config.options.bar.showBackground
            onCheckedChanged: {
                Config.options.bar.showBackground = checked;
            }
            StyledToolTip {
                text: Translation.tr("Draw a background behind the bar. Disabling makes the bar transparent.")
            }
        }

        ConfigSwitch {
            buttonIcon: "notes"
            text: Translation.tr("Verbose mode (wider bar)")
            checked: Config.options.bar.verbose
            onCheckedChanged: {
                Config.options.bar.verbose = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show more detailed information in bar modules. Increases bar width.")
            }
        }
    }

    // Auto-hide details
    ContentSection {
        icon: "visibility_off"
        title: Translation.tr("Auto-Hide Details")
        enabled: Config.options.bar.autoHide.enable

        ConfigSpinBox {
            icon: "arrow_range"
            text: Translation.tr("Hover region width (px)")
            value: Config.options.bar.autoHide.hoverRegionWidth
            from: 1
            to: 20
            stepSize: 1
            onValueChanged: {
                Config.options.bar.autoHide.hoverRegionWidth = value;
            }
            StyledToolTip {
                text: Translation.tr("Width of the invisible edge region that triggers the bar to show")
            }
        }

        ConfigSwitch {
            buttonIcon: "swap_vert"
            text: Translation.tr("Push windows when bar appears")
            checked: Config.options.bar.autoHide.pushWindows
            onCheckedChanged: {
                Config.options.bar.autoHide.pushWindows = checked;
            }
            StyledToolTip {
                text: Translation.tr("Resize windows to make room for the bar when it appears, instead of overlapping")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard_command_key"
                text: Translation.tr("Show when pressing Super")
                checked: Config.options.bar.autoHide.showWhenPressingSuper.enable
                onCheckedChanged: {
                    Config.options.bar.autoHide.showWhenPressingSuper.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Briefly reveal the bar when the Super key is pressed")
                }
            }

            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Super show delay (ms)")
                enabled: Config.options.bar.autoHide.showWhenPressingSuper.enable
                value: Config.options.bar.autoHide.showWhenPressingSuper.delay
                from: 0
                to: 1000
                stepSize: 10
                onValueChanged: {
                    Config.options.bar.autoHide.showWhenPressingSuper.delay = value;
                }
                StyledToolTip {
                    text: Translation.tr("Delay before the bar appears after pressing Super")
                }
            }
        }
    }

    // Top left icon
    ContentSection {
        icon: "star"
        title: Translation.tr("Bar Icon")

        Timer {
            id: iconDebounce
            interval: 600
            onTriggered: {
                const val = iconInput.text.trim();
                Config.options.bar.topLeftIcon = val.length > 0 ? val : "spark";
            }
        }

        ConfigRow {
            MaterialTextArea {
                id: iconInput
                Layout.fillWidth: true
                placeholderText: Translation.tr("Icon name (e.g., spark, distro)")
                text: Config.options.bar.topLeftIcon
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    iconDebounce.restart();
                }
            }
        }
    }

    // Resource monitors section
    ContentSection {
        icon: "memory"
        title: Translation.tr("Resource Monitors")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Always show CPU")
                checked: Config.options.bar.resources.alwaysShowCpu
                onCheckedChanged: { Config.options.bar.resources.alwaysShowCpu = checked; }
                StyledToolTip {
                    text: Translation.tr("Always display CPU usage in the bar, even when idle")
                }
            }
            ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: Translation.tr("Always show swap")
                checked: Config.options.bar.resources.alwaysShowSwap
                onCheckedChanged: { Config.options.bar.resources.alwaysShowSwap = checked; }
            }
        }
    }
    
    // Workspaces section
    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "award_star"
                text: Translation.tr("Show app icons")
                checked: Config.options.bar.workspaces.showAppIcons
                onCheckedChanged: { Config.options.bar.workspaces.showAppIcons = checked; }
            }
            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Tint app icons")
                checked: Config.options.bar.workspaces.monochromeIcons
                onCheckedChanged: { Config.options.bar.workspaces.monochromeIcons = checked; }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr("Always show numbers")
                checked: Config.options.bar.workspaces.alwaysShowNumbers
                onCheckedChanged: { Config.options.bar.workspaces.alwaysShowNumbers = checked; }
            }
            ConfigSwitch {
                buttonIcon: "font_download"
                text: Translation.tr("Use Nerd Font")
                checked: Config.options.bar.workspaces.useNerdFont
                onCheckedChanged: { Config.options.bar.workspaces.useNerdFont = checked; }
                StyledToolTip {
                    text: Translation.tr("Display workspace numbers using the configured Nerd Font")
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "view_column"
                text: Translation.tr("Workspaces shown")
                value: Config.options.bar.workspaces.shown
                from: 1
                to: 30
                stepSize: 1
                onValueChanged: { Config.options.bar.workspaces.shown = value; }
            }
            ConfigSpinBox {
                icon: "touch_long"
                text: Translation.tr("Number reveal delay (ms)")
                value: Config.options.bar.workspaces.showNumberDelay
                from: 0
                to: 1000
                stepSize: 50
                onValueChanged: { Config.options.bar.workspaces.showNumberDelay = value; }
                StyledToolTip {
                    text: Translation.tr("Delay before showing workspace numbers when pressing Super")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue);
                }
                options: [
                    { displayName: Translation.tr("Normal"), icon: "timer_10", value: '[]' },
                    { displayName: Translation.tr("Han chars"), icon: "square_dot", value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]' },
                    { displayName: Translation.tr("Roman"), icon: "account_balance", value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]' }
                ]
            }
        }
    }

    // Utility buttons section
    ContentSection {
        icon: "widgets"
        title: Translation.tr("Utility Buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: { Config.options.bar.utilButtons.showScreenSnip = checked; }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: { Config.options.bar.utilButtons.showColorPicker = checked; }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: { Config.options.bar.utilButtons.showKeyboardToggle = checked; }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: { Config.options.bar.utilButtons.showMicToggle = checked; }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: { Config.options.bar.utilButtons.showDarkModeToggle = checked; }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: { Config.options.bar.utilButtons.showPerformanceProfileToggle = checked; }
            }
        }
        ConfigSwitch {
            buttonIcon: "videocam"
            text: Translation.tr("Screen record")
            checked: Config.options.bar.utilButtons.showScreenRecord
            onCheckedChanged: { Config.options.bar.utilButtons.showScreenRecord = checked; }
        }
    }

    // Weather section
    ContentSection {
        icon: "cloud"
        title: Translation.tr("Weather Widget")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable weather in bar")
            checked: Config.options.bar.weather.enable
            onCheckedChanged: {
                Config.options.bar.weather.enable = checked;
            }
        }
    }

    // Tray section
    ContentSection {
        icon: "shelf_auto_hide"
        title: Translation.tr("System Tray")

        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Show unread notification count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display the number of unread notifications on the bar indicator")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pin icons by default")
                checked: Config.options.tray.invertPinnedItems
                onCheckedChanged: {
                    Config.options.tray.invertPinnedItems = checked;
                }
                StyledToolTip {
                    text: Translation.tr("When enabled, all tray items are pinned by default.\nThe pinned items list becomes an exclusion list.")
                }
            }
            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Tint icons")
                checked: Config.options.tray.monochromeIcons
                onCheckedChanged: {
                    Config.options.tray.monochromeIcons = checked;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "filter_list"
            text: Translation.tr("Filter passive items")
            checked: Config.options.tray.filterPassive
            onCheckedChanged: {
                Config.options.tray.filterPassive = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hide tray items that report a passive/inactive status")
            }
        }
    }

    // Tooltips section
    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Bar Tooltips")

        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show tooltips")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
            StyledToolTip {
                text: Translation.tr("Require a click instead of hover to show tooltips on bar elements")
            }
        }
    }
}
