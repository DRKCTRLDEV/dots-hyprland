import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // Default applications section
    ContentSection {
        icon: "open_in_new"
        title: Translation.tr("Default Applications")

        ContentSubsection {
            title: Translation.tr("Application commands")
            tooltip: Translation.tr("Commands used by the shell to launch various applications.\nChange these if you use different apps than the defaults.")
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Terminal (e.g., kitty -1)")
            text: Config.options.apps.terminal
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.terminal = text.trim() || Config.defaults.apps.terminal;
            }
            StyledToolTip {
                text: Translation.tr("Terminal emulator command used for shell actions")
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Task manager")
            text: Config.options.apps.taskManager
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.taskManager = text.trim() || Config.defaults.apps.taskManager;
            }
            StyledToolTip {
                text: Translation.tr("System/process monitor application")
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Volume mixer")
            text: Config.options.apps.volumeMixer
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.volumeMixer = text.trim() || Config.defaults.apps.volumeMixer;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Bluetooth settings")
            text: Config.options.apps.bluetooth
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.bluetooth = text.trim() || Config.defaults.apps.bluetooth;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Network settings")
            text: Config.options.apps.network
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.network = text.trim() || Config.defaults.apps.network;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Ethernet settings")
            text: Config.options.apps.networkEthernet
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.networkEthernet = text.trim() || Config.defaults.apps.networkEthernet;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("User management")
            text: Config.options.apps.manageUser
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.manageUser = text.trim() || Config.defaults.apps.manageUser;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Change password command")
            text: Config.options.apps.changePassword
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.changePassword = text.trim() || Config.defaults.apps.changePassword;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("System update command")
            text: Config.options.apps.update
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.apps.update = text.trim() || Config.defaults.apps.update;
            }
        }
    }

    // Search section
    ContentSection {
        icon: "search"
        title: Translation.tr("Search")

        ConfigSwitch {
            text: Translation.tr("Sloppy matching (Levenshtein distance)")
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                text: Translation.tr("Uses Levenshtein distance instead of fuzzy sort.\nBetter for typo tolerance but may give unexpected results.\nAcronyms like \"GIMP\" might not match.")
            }
        }

        ConfigSwitch {
            buttonIcon: "list"
            text: Translation.tr("Show default actions without prefix")
            checked: Config.options.search.prefix.showDefaultActionsWithoutPrefix
            onCheckedChanged: {
                Config.options.search.prefix.showDefaultActionsWithoutPrefix = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show action results even when you haven't typed the action prefix.\nDisable if you only want actions when explicitly prefixed.")
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Non-app result delay (ms)")
            value: Config.options.search.nonAppResultDelay
            from: 0
            to: 500
            stepSize: 10
            onValueChanged: {
                Config.options.search.nonAppResultDelay = value;
            }
            StyledToolTip {
                text: Translation.tr("Delay before showing non-app results (web, math, etc.) to prevent lag while typing")
            }
        }

        ContentSubsection {
            title: Translation.tr("Search prefixes")
            tooltip: Translation.tr("Characters that trigger specific search modes when typed at the start of a query")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Action (/)")
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.action = text; }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("App (>)")
                    text: Config.options.search.prefix.app
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.app = text; }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Clipboard (;)")
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.clipboard = text; }
                }
            }
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Emojis (:)")
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.emojis = text; }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Math (=)")
                    text: Config.options.search.prefix.math
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.math = text; }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Shell ($)")
                    text: Config.options.search.prefix.shellCommand
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: { Config.options.search.prefix.shellCommand = text; }
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Web search (?)")
                text: Config.options.search.prefix.webSearch
                wrapMode: TextEdit.NoWrap
                onTextChanged: { Config.options.search.prefix.webSearch = text; }
            }
        }

        ContentSubsection {
            title: Translation.tr("Web search")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search engine base URL")
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text.trim() || Config.defaults.search.engineBaseUrl;
                }
                StyledToolTip {
                    text: Translation.tr("URL prefix for web searches. The query will be appended.\ne.g. https://duckduckgo.com/?q=")
                }
            }

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Image search engine base URL")
                text: Config.options.search.imageSearch.imageSearchEngineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.imageSearch.imageSearchEngineBaseUrl = text.trim() || Config.defaults.search.imageSearch.imageSearchEngineBaseUrl;
                }
                StyledToolTip {
                    text: Translation.tr("URL prefix for reverse image searches.\ne.g. https://lens.google.com/uploadbyurl?url=")
                }
            }
        }
    }

    // Weather section
    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")

        ConfigSwitch {
            buttonIcon: "assistant_navigation"
            text: Translation.tr("GPS-based location")
            checked: Config.options.bar.weather.enableGPS
            onCheckedChanged: {
                Config.options.bar.weather.enableGPS = checked;
            }
            StyledToolTip {
                text: Translation.tr("Use your device's location to fetch weather.\nDisable to manually specify a city below.")
            }
        }

        ConfigSwitch {
            buttonIcon: "thermometer"
            text: Translation.tr("Use Fahrenheit")
            checked: Config.options.bar.weather.useUSCS
            onCheckedChanged: {
                Config.options.bar.weather.useUSCS = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display temperature in Fahrenheit instead of Celsius")
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            enabled: !Config.options.bar.weather.enableGPS
            placeholderText: Translation.tr("City name (when GPS is disabled)")
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Fetch interval (minutes)")
            value: Config.options.bar.weather.fetchInterval
            from: 5
            to: 60
            stepSize: 5
            onValueChanged: {
                Config.options.bar.weather.fetchInterval = value;
            }
        }
    }

    // Music recognition section
    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        ConfigSpinBox {
            icon: "timer_off"
            text: Translation.tr("Total timeout (s)")
            value: Config.options.musicRecognition.timeout
            from: 10
            to: 100
            stepSize: 2
            onValueChanged: {
                Config.options.musicRecognition.timeout = value;
            }
            StyledToolTip {
                text: Translation.tr("Maximum time to attempt music recognition before giving up")
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (s)")
            value: Config.options.musicRecognition.interval
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.musicRecognition.interval = value;
            }
        }
    }

    // Media section
    ContentSection {
        icon: "play_circle"
        title: Translation.tr("Media")

        ConfigSwitch {
            buttonIcon: "filter_list"
            text: Translation.tr("Filter duplicate media players")
            checked: Config.options.media.filterDuplicatePlayers
            onCheckedChanged: {
                Config.options.media.filterDuplicatePlayers = checked;
            }
            StyledToolTip {
                text: Translation.tr("Remove duplicate MPRIS players that appear when using Plasma Browser Integration.\nPrevents seeing the same media controls twice.")
            }
        }
    }

    // Networking section
    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("User agent string")
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
            StyledToolTip {
                text: Translation.tr("HTTP User-Agent header used by shell services (weather, web search, etc.)")
            }
        }
    }

    // Resources section
    ContentSection {
        icon: "memory"
        title: Translation.tr("Resource Monitoring")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
            StyledToolTip {
                text: Translation.tr("How often CPU, RAM, and swap usage are refreshed")
            }
        }

        ConfigSpinBox {
            icon: "history"
            text: Translation.tr("History length (data points)")
            value: Config.options.resources.historyLength
            from: 10
            to: 300
            stepSize: 10
            onValueChanged: {
                Config.options.resources.historyLength = value;
            }
            StyledToolTip {
                text: Translation.tr("Number of historical data points kept for resource usage graphs")
            }
        }
    }

    // Save paths section
    ContentSection {
        icon: "file_open"
        title: Translation.tr("Save Paths")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Video recording save path")
            text: Config.options.screenRecord.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenRecord.savePath = text;
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Screenshot save path (leave empty to just copy)")
            text: Config.options.screenSnip.savePath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.screenSnip.savePath = text;
            }
            StyledToolTip {
                text: Translation.tr("Leave empty to only copy screenshots to clipboard without saving to disk")
            }
        }
    }
}
