import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Cheat sheet section
    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Cheat Sheet")

        ContentSubsection {
            title: Translation.tr("Super key symbol")
            tooltip: Translation.tr("Choose a symbol to represent the Super/Meta key in keybind displays")

            ConfigSelectionArray {
                currentValue: Config.options.cheatsheet.superKey
                onSelected: newValue => {
                    Config.options.cheatsheet.superKey = newValue;
                }
                options: (["󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "", "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""]).map(icon => {
                    return { displayName: icon, value: icon };
                })
            }
        }

        ConfigSwitch {
            buttonIcon: "keyboard_alt"
            text: Translation.tr("Use macOS-like symbols for modifier keys")
            checked: Config.options.cheatsheet.useMacSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMacSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show ⌃ for Ctrl, ⌥ for Alt, ⇧ for Shift, etc.")
            }
        }

        ConfigSwitch {
            buttonIcon: "function"
            text: Translation.tr("Use symbols for function keys")
            checked: Config.options.cheatsheet.useFnSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useFnSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replace F1–F12 labels with symbolic icons")
            }
        }

        ConfigSwitch {
            buttonIcon: "mouse"
            text: Translation.tr("Use symbols for mouse actions")
            checked: Config.options.cheatsheet.useMouseSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.useMouseSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replace text like \"Scroll ↓\" and \"LMB\" with symbolic mouse icons")
            }
        }

        ConfigSwitch {
            buttonIcon: "highlight_keyboard_focus"
            text: Translation.tr("Split modifier + key into separate keycaps")
            checked: Config.options.cheatsheet.splitButtons
            onCheckedChanged: {
                Config.options.cheatsheet.splitButtons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show \"Ctrl\" + \"A\" as separate keys instead of combined \"Ctrl A\"")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: Translation.tr("Keybind font size")
                value: Config.options.cheatsheet.fontSize.key
                from: 8
                to: 30
                stepSize: 1
                onValueChanged: {
                    Config.options.cheatsheet.fontSize.key = value;
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Description font size")
                value: Config.options.cheatsheet.fontSize.comment
                from: 8
                to: 30
                stepSize: 1
                onValueChanged: {
                    Config.options.cheatsheet.fontSize.comment = value;
                }
            }
        }
    }

    // Scrolling section
    ContentSection {
        icon: "swipe_up"
        title: Translation.tr("Scrolling")

        ConfigSwitch {
            buttonIcon: "speed"
            text: Translation.tr("Faster touchpad scrolling")
            checked: Config.options.interactions.scrolling.fasterTouchpadScroll
            onCheckedChanged: {
                Config.options.interactions.scrolling.fasterTouchpadScroll = checked;
            }
            StyledToolTip {
                text: Translation.tr("Increases the scroll speed when using a touchpad in shell elements")
            }
        }

        ConfigSpinBox {
            icon: "mouse"
            text: Translation.tr("Mouse scroll delta threshold")
            value: Config.options.interactions.scrolling.mouseScrollDeltaThreshold
            from: 10
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.interactions.scrolling.mouseScrollDeltaThreshold = value;
            }
            StyledToolTip {
                text: Translation.tr("Scroll delta at or above this value is treated as mouse scroll (vs touchpad).\nHelps distinguish between mouse wheel and touchpad gestures.")
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "mouse"
                text: Translation.tr("Mouse scroll factor")
                value: Config.options.interactions.scrolling.mouseScrollFactor
                from: 10
                to: 1000
                stepSize: 10
                onValueChanged: {
                    Config.options.interactions.scrolling.mouseScrollFactor = value;
                }
            }
            ConfigSpinBox {
                icon: "touch_app"
                text: Translation.tr("Touchpad scroll factor")
                value: Config.options.interactions.scrolling.touchpadScrollFactor
                from: 10
                to: 2000
                stepSize: 50
                onValueChanged: {
                    Config.options.interactions.scrolling.touchpadScrollFactor = value;
                }
            }
        }
    }

    // Crosshair section
    ContentSection {
        icon: "point_scan"
        title: Translation.tr("Crosshair Overlay")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Crosshair code (Valorant format)")
            text: Config.options.crosshair.code
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.crosshair.code = text.trim() || Config.defaults.crosshair.code;
            }
        }

        RowLayout {
            StyledText {
                Layout.leftMargin: 10
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
            }
            Item { Layout.fillWidth: true }
            RippleButtonWithIcon {
                buttonRadius: Appearance.rounding.full
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open editor")
                onClicked: {
                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                }
                StyledToolTip {
                    text: "www.vcrdb.net"
                }
            }
        }
    }

    // Region selector section
    ContentSection {
        icon: "screenshot_frame_2"
        title: Translation.tr("Region Selector")

        ContentSubsection {
            title: Translation.tr("Hint target regions")
            tooltip: Translation.tr("Highlight interactive regions when using the screen snipping tool")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "select_window"
                    text: Translation.tr("Windows")
                    checked: Config.options.regionSelector.targetRegions.windows
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.windows = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    text: Translation.tr("Layers")
                    checked: Config.options.regionSelector.targetRegions.layers
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.layers = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: Translation.tr("Content")
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Detect content regions using a local image processing algorithm.\nMay not always be accurate.")
                    }
                }
            }

            ConfigSwitch {
                buttonIcon: "label"
                text: Translation.tr("Show region labels")
                checked: Config.options.regionSelector.targetRegions.showLabel
                onCheckedChanged: {
                    Config.options.regionSelector.targetRegions.showLabel = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Display labels on detected target regions")
                }
            }

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Region opacity (%)")
                    value: Math.round(Config.options.regionSelector.targetRegions.opacity * 100)
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.targetRegions.opacity = value / 100;
                    }
                }
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Content opacity (%)")
                    value: Math.round(Config.options.regionSelector.targetRegions.contentRegionOpacity * 100)
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.targetRegions.contentRegionOpacity = value / 100;
                    }
                }
            }

            ConfigSpinBox {
                icon: "padding"
                text: Translation.tr("Selection padding (px)")
                value: Config.options.regionSelector.targetRegions.selectionPadding
                from: 0
                to: 50
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.targetRegions.selectionPadding = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Default selection mode")

            ConfigSelectionArray {
                currentValue: Config.options.regionSelector.useCircleSelection ? "circle" : "rectangles"
                onSelected: newValue => {
                    Config.options.regionSelector.useCircleSelection = (newValue === "circle");
                }
                options: [
                    { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                    { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Rectangular selection")

            ConfigSwitch {
                buttonIcon: "point_scan"
                text: Translation.tr("Show aim lines")
                checked: Config.options.regionSelector.rect.showAimLines
                onCheckedChanged: {
                    Config.options.regionSelector.rect.showAimLines = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Circle selection")

            ConfigSpinBox {
                icon: "eraser_size_3"
                text: Translation.tr("Stroke width")
                value: Config.options.regionSelector.circle.strokeWidth
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.circle.strokeWidth = value;
                }
            }

            ConfigSpinBox {
                icon: "screenshot_frame_2"
                text: Translation.tr("Padding")
                value: Config.options.regionSelector.circle.padding
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.regionSelector.circle.padding = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Annotation")

            ConfigSwitch {
                buttonIcon: "edit"
                text: Translation.tr("Use Satty for annotations")
                checked: Config.options.regionSelector.annotation.useSatty
                onCheckedChanged: {
                    Config.options.regionSelector.annotation.useSatty = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Open screenshots in Satty for annotation instead of copying directly.\nRequires Satty to be installed.")
                }
            }
        }
    }
}
