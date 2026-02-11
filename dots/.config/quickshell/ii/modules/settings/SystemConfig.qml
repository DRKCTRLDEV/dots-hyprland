import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    // Language section
    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface language")
            tooltip: Translation.tr("Controls the language used throughout the shell UI.\n\"Auto\" will follow your system locale setting.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.availableLanguages.map(lang => {
                        return { displayName: lang, value: lang };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Translator")
            tooltip: Translation.tr("Settings for the sidebar translation service")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Translation engine (\"auto\" or run `trans -list-engines`)")
                text: Config.options.language.translator.engine
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.language.translator.engine = text.trim() || Config.defaults.language.translator.engine;
                }
                StyledToolTip {
                    text: Translation.tr("Translation backend to use. \"auto\" picks the best available.\nRun `trans -list-engines` in terminal for options.")
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Target language (\"auto\" or code)")
                    text: Config.options.language.translator.targetLanguage
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.language.translator.targetLanguage = text.trim() || Config.defaults.language.translator.targetLanguage;
                    }
                    StyledToolTip {
                        text: Translation.tr("Language to translate INTO. \"auto\" uses your system locale.\nRun `trans -list-all` for available language codes.")
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Source language (\"auto\" for detection)")
                    text: Config.options.language.translator.sourceLanguage
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.language.translator.sourceLanguage = text.trim() || Config.defaults.language.translator.sourceLanguage;
                    }
                    StyledToolTip {
                        text: Translation.tr("Language to translate FROM. \"auto\" detects automatically.")
                    }
                }
            }
        }
    }

    // Time & Calendar section
    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time & Calendar")

        ContentSubsection {
            title: Translation.tr("Time format")
            tooltip: Translation.tr("How time is displayed in the bar and other shell elements")

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    Config.options.time.format = newValue;
                }
                options: [
                    { displayName: Translation.tr("24h"), value: "hh:mm" },
                    { displayName: Translation.tr("12h am/pm"), value: "h:mm ap" },
                    { displayName: Translation.tr("12h AM/PM"), value: "h:mm AP" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Date formats")
            tooltip: Translation.tr("Qt date format strings. See Qt documentation for format codes.\ne.g. dd=day, MM=month, yyyy=year, ddd=day name")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Short date (e.g., dd/MM)")
                    text: Config.options.time.shortDateFormat
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.time.shortDateFormat = text.trim() || Config.defaults.time.shortDateFormat; }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Date with year (e.g., dd/MM/yyyy)")
                    text: Config.options.time.dateWithYearFormat
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.time.dateWithYearFormat = text.trim() || Config.defaults.time.dateWithYearFormat; }
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Full date (e.g., ddd, dd/MM)")
                text: Config.options.time.dateFormat
                wrapMode: TextEdit.NoWrap
                onTextChanged: { Config.options.time.dateFormat = text.trim() || Config.defaults.time.dateFormat; }
            }
        }

        ContentSubsection {
            title: Translation.tr("Calendar locale")
            tooltip: Translation.tr("Locale used for calendar day names and formatting")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Locale (e.g., en-GB, de-DE, ja-JP)")
                text: Config.options.calendar.locale
                wrapMode: TextEdit.NoWrap
                onTextChanged: { Config.options.calendar.locale = text.trim() || Config.defaults.calendar.locale; }
            }
        }

        ContentSubsection {
            title: Translation.tr("Pomodoro timer")
            tooltip: Translation.tr("Configure the pomodoro productivity timer durations (in seconds)")

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "target"
                    text: Translation.tr("Focus (s)")
                    value: Config.options.time.pomodoro.focus
                    from: 60
                    to: 7200
                    stepSize: 60
                    onValueChanged: { Config.options.time.pomodoro.focus = value; }
                    StyledToolTip {
                        text: Translation.tr("Duration of each focus session")
                    }
                }
                ConfigSpinBox {
                    icon: "coffee"
                    text: Translation.tr("Break (s)")
                    value: Config.options.time.pomodoro.breakTime
                    from: 60
                    to: 3600
                    stepSize: 60
                    onValueChanged: { Config.options.time.pomodoro.breakTime = value; }
                    StyledToolTip {
                        text: Translation.tr("Duration of each short break session")
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "weekend"
                    text: Translation.tr("Long break (s)")
                    value: Config.options.time.pomodoro.longBreak
                    from: 60
                    to: 7200
                    stepSize: 60
                    onValueChanged: { Config.options.time.pomodoro.longBreak = value; }
                    StyledToolTip {
                        text: Translation.tr("Duration of the long break session")
                    }
                }
                ConfigSpinBox {
                    icon: "repeat"
                    text: Translation.tr("Cycles to long break")
                    value: Config.options.time.pomodoro.cyclesBeforeLongBreak
                    from: 1
                    StyledToolTip {
                        text: Translation.tr("Number of focus-break cycles before a long break")
                    }
                    to: 20
                    stepSize: 1
                    onValueChanged: { Config.options.time.pomodoro.cyclesBeforeLongBreak = value; }
                }
            }
        }
    }

    // Audio section
    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Volume normalization")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Limits volume jumps and sets a maximum allowed volume level.\nProtects your ears from sudden loud audio.")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max increase per step")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
                StyledToolTip {
                    text: Translation.tr("Maximum volume increase allowed in a single step (in %)")
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
                StyledToolTip {
                    text: Translation.tr("Absolute maximum volume (up to 153% for amplified output)")
                }
            }
        }
    }

    // Battery section
    ContentSection {
        icon: "battery_full"
        title: Translation.tr("Battery")
        visible: Battery.available

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning (%)")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: { Config.options.battery.low = value; }
                StyledToolTip {
                    text: Translation.tr("Battery percentage at which a low battery warning is shown")
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning (%)")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: { Config.options.battery.critical = value; }
                StyledToolTip {
                    text: Translation.tr("Battery percentage for critical warning — typically triggers urgent notification")
                }
            }
        }

        ConfigRow {
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full notification (%)")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: { Config.options.battery.full = value; }
                StyledToolTip {
                    text: Translation.tr("Notify when battery reaches this level while charging.\nSet to 101 to disable.")
                }
            }
        }

        ConfigRow {
            uniform: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspend the system when battery drops to the threshold")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at %")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 1
                onValueChanged: { Config.options.battery.suspend = value; }
            }
        }
    }

    // Sounds section
    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")

        ConfigSwitch {
            buttonIcon: "notifications"
            text: Translation.tr("Notification sounds")
            checked: Config.options.sounds.notifications
            onCheckedChanged: {
                Config.options.sounds.notifications = checked;
            }
            StyledToolTip {
                text: Translation.tr("Play sounds for notifications")
            }
        }

        ConfigSwitch {
            buttonIcon: "volume_up"
            text: Translation.tr("System sounds")
            checked: Config.options.sounds.system
            onCheckedChanged: {
                Config.options.sounds.system = checked;
            }
            StyledToolTip {
                text: Translation.tr("Play sounds for system events (e.g., file operations, dialogs)")
            }
        }

        ConfigSwitch {
            visible: Battery.available
            buttonIcon: "battery_full"
            text: Translation.tr("Battery sounds")
            checked: Config.options.sounds.battery
            onCheckedChanged: {
                Config.options.sounds.battery = checked;
            }
            StyledToolTip {
                text: Translation.tr("Play sounds for battery warnings")
            }
        }

        ConfigSwitch {
            buttonIcon: "av_timer"
            text: Translation.tr("Pomodoro sounds")
            checked: Config.options.sounds.pomodoro
            onCheckedChanged: {
                Config.options.sounds.pomodoro = checked;
            }
            StyledToolTip {
                text: Translation.tr("Play sounds for pomodoro phases")
            }
        }

        ContentSubsection {
            title: Translation.tr("Sound theme")
            tooltip: Translation.tr("Freedesktop sound theme used for notification and event sounds")

            Process {
                id: soundThemeProc
                property var themes: ["freedesktop"]
                running: true
                command: ["bash", "-c", "for d in /usr/share/sounds/*/index.theme ~/.local/share/sounds/*/index.theme; do [ -f \"$d\" ] && basename \"$(dirname \"$d\")\"; done 2>/dev/null | sort -u"]
                stdout: SplitParser {
                    onRead: data => {
                        const name = data.trim();
                        if (name.length > 0 && !soundThemeProc.themes.includes(name))
                            soundThemeProc.themes = [...soundThemeProc.themes, name];
                    }
                }
            }

            ConfigSelectionArray {
                currentValue: Config.options.sounds.theme
                onSelected: newValue => {
                    Config.options.sounds.theme = newValue;
                }
                options: soundThemeProc.themes.map(t => {
                    return { displayName: t, value: t };
                })
            }
        }
    }

    // Night light section
    ContentSection {
        icon: "nightlight"
        title: Translation.tr("Night Light")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "schedule"
                text: Translation.tr("Schedule")
                checked: Config.options.light.night.automatic
                onCheckedChanged: {
                    Config.options.light.night.automatic = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically enable night light based on the time schedule below")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.light.night.automatic
                icon: "nightlight"
                text: Translation.tr("Start")
                value: {
                    const parts = Config.options.light.night.from.split(":");
                    return parts.length >= 1 ? parseInt(parts[0]) || 19 : 19;
                }
                from: 0
                to: 23
                stepSize: 1
                onValueChanged: {
                    const newFrom = String(value).padStart(2, '0') + ":00";
                    if (Config.options.light.night.from !== newFrom)
                        Config.options.light.night.from = newFrom;
                }
                StyledToolTip {
                    text: Translation.tr("Hour when night light activates (24h format)")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.light.night.automatic
                icon: "wb_sunny"
                text: Translation.tr("End")
                value: {
                    const parts = Config.options.light.night.to.split(":");
                    return parts.length >= 1 ? parseInt(parts[0]) || 6 : 6;
                }
                from: 0
                to: 23
                stepSize: 1
                onValueChanged: {
                    const newTo = String(value).padStart(2, '0') + ":00";
                    if (Config.options.light.night.to !== newTo)
                        Config.options.light.night.to = newTo;
                }
                StyledToolTip {
                    text: Translation.tr("Hour when night light deactivates (24h format)")
                }
            }
        }

        ConfigSpinBox {
            icon: "thermostat"
            text: Translation.tr("Color temperature (K)")
            value: Config.options.light.night.colorTemperature
            from: 1000
            to: 6500
            stepSize: 100
            onValueChanged: {
                Config.options.light.night.colorTemperature = value;
            }
            StyledToolTip {
                text: Translation.tr("1000K = very warm (orange) · 6500K = neutral daylight")
            }
        }
    }

    // Updates section
    ContentSection {
        icon: "system_update"
        title: Translation.tr("System Updates")
        
        ConfigSwitch {
            buttonIcon: "deployed_code_update"
            text: Translation.tr("System updates (Arch only)")
            checked: Config.options.updates.enableCheck
            onCheckedChanged: {
                Config.options.updates.enableCheck = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically enable system updates (Arch only)")
            }
        }

        ConfigSpinBox {
            enabled: Config.options.updates.enableCheck
            icon: "av_timer"
            text: Translation.tr("Check interval (minutes)")
            value: Config.options.updates.checkInterval
            from: 10
            to: 1440
            stepSize: 10
            onValueChanged: {
                Config.options.updates.checkInterval = value;
            }
            StyledToolTip {
                text: Translation.tr("How often to check for available system updates")
            }
        }

        ConfigSpinBox {
            enabled: Config.options.updates.enableCheck
            icon: "info"
            text: Translation.tr("Suggest update threshold (packages)")
            value: Config.options.updates.adviseUpdateThreshold
            from: 1
            to: 500
            stepSize: 5
            onValueChanged: {
                Config.options.updates.adviseUpdateThreshold = value;
            }
            StyledToolTip {
                text: Translation.tr("Show a gentle update reminder when this many packages are available")
            }
        }

        ConfigSpinBox {
            enabled: Config.options.updates.enableCheck
            icon: "priority_high"
            text: Translation.tr("Strongly advise threshold (packages)")
            value: Config.options.updates.stronglyAdviseUpdateThreshold
            from: 1
            to: 1000
            stepSize: 10
            onValueChanged: {
                Config.options.updates.stronglyAdviseUpdateThreshold = value;
            }
            StyledToolTip {
                text: Translation.tr("Show an urgent update warning when this many packages are pending")
            }
        }
    }
}
