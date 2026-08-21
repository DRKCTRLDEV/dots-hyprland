import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {

    ContentSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")

        ConfigSwitch {
            buttonIcon: "unfold_more_double"
            text: Translation.tr("Vertical")
            configPath: "background.parallax.vertical"
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr("Depends on workspace")
                configPath: "background.parallax.enableWorkspace"
            }
            ConfigSwitch {
                buttonIcon: "side_navigation"
                text: Translation.tr("Depends on sidebars")
                configPath: "background.parallax.enableSidebar"
            }
        }
        ConfigSwitch {
            buttonIcon: "widgets"
            text: Translation.tr("Widgets follow parallax")
            configPath: "background.parallax.widgetsFollowParallax"
            StyledToolTip {
                text: Translation.tr("When enabled, background widgets move along with the wallpaper as it pans. When disabled, they stay in place on screen.")
            }
        }

        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Preferred wallpaper zoom (%)")
            value: Config.options.background.parallax.workspaceZoom * 100
            from: 10
            to: 200
            stepSize: 1
            onValueChanged: {
                Config.options.background.parallax.workspaceZoom = value / 100;
            }
        }
    }

    ContentSection {
        id: settingsClock
        icon: "clock_loader_40"
        title: Translation.tr("Widget: Clock")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                configPath: "background.widgets.clock.enable"
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                configPath: "background.widgets.clock.placementStrategy"
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                    {
                        displayName: Translation.tr("Centered"),
                        icon: "center_focus_strong",
                        value: "centered"
                    },
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "lock_clock"
            text: Translation.tr("Show only when locked")
            configPath: "background.widgets.clock.showOnlyWhenLocked"
        }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_distribute"
                    text: Translation.tr("Vertical")
                    configPath: "background.widgets.clock.digital.vertical"
                }
                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Animate time change")
                    configPath: "background.widgets.clock.digital.animateChange"
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "date_range"
                    text: Translation.tr("Show date")
                    configPath: "background.widgets.clock.digital.showDate"
                }
                ConfigSwitch {
                    buttonIcon: "activity_zone"
                    text: Translation.tr("Use adaptive alignment")
                    configPath: "background.widgets.clock.digital.adaptiveAlignment"
                    StyledToolTip {
                        text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
                    }
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family")
                text: Config.options.background.widgets.clock.digital.font.family
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.clock.digital.font.family = text;
                }
            }

            ConfigSlider {
                text: Translation.tr("Font weight")
                configPath: "background.widgets.clock.digital.font.weight"
                usePercentTooltip: false
                buttonIcon: "format_bold"
                from: 1
                to: 1000
                stopIndicatorValues: [350]
            }

            ConfigSlider {
                text: Translation.tr("Font size")
                configPath: "background.widgets.clock.digital.font.size"
                usePercentTooltip: false
                buttonIcon: "format_size"
                from: 50
                to: 700
                stopIndicatorValues: [90]
            }

            ConfigSlider {
                text: Translation.tr("Font width")
                configPath: "background.widgets.clock.digital.font.width"
                usePercentTooltip: false
                buttonIcon: "fit_width"
                from: 25
                to: 125
                stopIndicatorValues: [100]
            }
            ConfigSlider {
                text: Translation.tr("Font roundness")
                configPath: "background.widgets.clock.digital.font.roundness"
                usePercentTooltip: false
                buttonIcon: "line_curve"
                from: 0
                to: 100
            }
        }

        ContentSubsection {
            title: Translation.tr("Quote")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                configPath: "background.widgets.clock.quote.enable"
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Quote")
                text: Config.options.background.widgets.clock.quote.text
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.clock.quote.text = text;
                }
            }
        }
    }
