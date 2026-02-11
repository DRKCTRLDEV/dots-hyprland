import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
        Accessible.role: Accessible.RadioButton
        Accessible.name: dark ? Translation.tr("Dark mode") : Translation.tr("Light mode")
    }

    // Color scheme section
    ContentSection {
        icon: "palette"
        title: Translation.tr("Color Scheme")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 340
                implicitHeight: 200

                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    sourceSize.width: parent.implicitWidth
                    sourceSize.height: parent.implicitHeight
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            ColumnLayout {
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: Config.options.cheatsheet.superKey ?? "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Palette type")
            tooltip: Translation.tr("Controls how material colors are generated from your wallpaper.\n\"Auto\" detects the best scheme based on image saturation.")

            ConfigSelectionArray {
                currentValue: Config.options.appearance.palette.type
                onSelected: newValue => {
                    Config.options.appearance.palette.type = newValue;
                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
                }
                options: [
                    { "value": "auto", "displayName": Translation.tr("Auto") },
                    { "value": "scheme-content", "displayName": Translation.tr("Content") },
                    { "value": "scheme-expressive", "displayName": Translation.tr("Expressive") },
                    { "value": "scheme-fidelity", "displayName": Translation.tr("Fidelity") },
                    { "value": "scheme-fruit-salad", "displayName": Translation.tr("Fruit Salad") },
                    { "value": "scheme-monochrome", "displayName": Translation.tr("Monochrome") },
                    { "value": "scheme-neutral", "displayName": Translation.tr("Neutral") },
                    { "value": "scheme-rainbow", "displayName": Translation.tr("Rainbow") },
                    { "value": "scheme-tonal-spot", "displayName": Translation.tr("Tonal Spot") }
                ]
            }
        }

    }

    // Transparency section
    ContentSection {
        icon: "ev_shadow"
        title: Translation.tr("Transparency")

        ConfigSwitch {
            buttonIcon: "ev_shadow"
            text: Translation.tr("Enable transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enables translucent backgrounds for shell elements")
            }
        }

        ConfigSwitch {
            buttonIcon: "auto_awesome"
            text: Translation.tr("Automatic transparency levels")
            enabled: Config.options.appearance.transparency.enable
            checked: Config.options.appearance.transparency.automatic
            onCheckedChanged: {
                Config.options.appearance.transparency.automatic = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically adjusts transparency based on wallpaper vibrancy.\nDisable to set manual values below.")
            }
        }

        ConfigSlider {
            visible: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
            buttonIcon: "gradient"
            text: Translation.tr("Background")
            value: Config.options.appearance.transparency.backgroundTransparency
            from: 0
            to: 0.5
            usePercentTooltip: true
            onValueChanged: {
                Config.options.appearance.transparency.backgroundTransparency = value;
            }
            StyledToolTip {
                text: Translation.tr("Transparency level for background layers")
            }
        }

        ConfigSlider {
            visible: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
            buttonIcon: "layers"
            text: Translation.tr("Content")
            value: Config.options.appearance.transparency.contentTransparency
            from: 0
            to: 1
            usePercentTooltip: true
            onValueChanged: {
                Config.options.appearance.transparency.contentTransparency = value;
            }
            StyledToolTip {
                text: Translation.tr("Transparency level for content container layers")
            }
        }

        ConfigSwitch {
            buttonIcon: "tonality"
            text: Translation.tr("Extra background tint")
            checked: Config.options.appearance.extraBackgroundTint
            onCheckedChanged: {
                Config.options.appearance.extraBackgroundTint = checked;
            }
            StyledToolTip {
                text: Translation.tr("Mixes a slight tint of the primary color into background layers for a more cohesive look")
            }
        }
    }

    // Theming generation section
    ContentSection {
        icon: "colors"
        title: Translation.tr("Theme Generation")

        ConfigSwitch {
            buttonIcon: "hardware"
            text: Translation.tr("Shell & GTK theming")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
            }
            StyledToolTip {
                text: Translation.tr("Generate and apply material colors to the shell, GTK apps, and other themed elements.\nDisabling this skips all color generation when switching wallpapers.")
            }
        }
        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: Translation.tr("Qt apps (KDE/Dolphin/etc.)")
            enabled: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableQtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Apply material colors to Qt/KDE applications via kdeglobals.\nRequires shell & GTK theming to be enabled.\nUpdates titlebars, menubars, and widget colors in apps like Dolphin, KCalc, etc.")
            }
        }
        ConfigSwitch {
            buttonIcon: "terminal"
            text: Translation.tr("Terminal colors")
            enabled: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Apply material colors to terminal emulators via OSC escape sequences.\nAffects all running terminal sessions in real time.")
            }
        }
    }

    // Icons section
    ContentSection {
        icon: "style"
        title: Translation.tr("Icons")

        Process {
            id: iconThemeProc
            property var themes: []
            running: true
            command: ["bash", "-c", [
                "for d in /usr/share/icons/*/index.theme \"${XDG_DATA_HOME:-$HOME/.local/share}/icons\"/*/index.theme \"$HOME/.icons\"/*/index.theme; do",
                "  [ -f \"$d\" ] && grep -q '^Directories=' \"$d\" 2>/dev/null && basename \"$(dirname \"$d\")\" || true",
                "done 2>/dev/null |",
                "  grep -vE '^(MaterialYou-|hicolor$|locolor$|default$|AdwaitaLegacy$)' |",
                "  sed -E 's/-(dark|light|Dark|Light)$//' |",
                "  sort -u",
            ].join("\n")]
            stdout: SplitParser {
                onRead: data => {
                    const name = data.trim();
                    if (name.length > 0 && !iconThemeProc.themes.includes(name))
                        iconThemeProc.themes = [...iconThemeProc.themes, name];
                }
            }
        }

        Process {
            id: currentThemeDetector
            property string detectedTheme: ""
            running: true
            command: ["bash", "-c", [
                "theme=\"\"",
                "command -v kreadconfig6 &>/dev/null && theme=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null) || true",
                "[ -z \"$theme\" ] && theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d \"'\") || true",
                "if [[ \"$theme\" == MaterialYou-* ]]; then",
                "  idx=\"${XDG_DATA_HOME:-$HOME/.local/share}/icons/$theme/index.theme\"",
                "  [ -f \"$idx\" ] && theme=$(grep '^Inherits=' \"$idx\" | head -1 | cut -d= -f2 | cut -d, -f1) || theme=breeze",
                "fi",
                "theme=\"${theme%-dark}\"; theme=\"${theme%-Dark}\"; theme=\"${theme%-light}\"; theme=\"${theme%-Light}\"",
                "echo \"${theme:-breeze}\"",
            ].join("\n")]
            stdout: SplitParser {
                onRead: data => {
                    const name = data.trim();
                    if (name.length > 0) currentThemeDetector.detectedTheme = name;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Icon theme")
            tooltip: Translation.tr("Base icon theme for the desktop.\nMaterial You accent colors will be applied as an overlay on top of this theme.")

            StyledComboBox {
                id: iconThemeSelector
                buttonIcon: "style"
                textRole: "displayName"

                model: [
                    { displayName: currentThemeDetector.detectedTheme
                        ? Translation.tr("Auto-detect") + ` (${currentThemeDetector.detectedTheme})`
                        : Translation.tr("Auto-detect"),
                      value: "" },
                    ...iconThemeProc.themes.map(t => ({ displayName: t, value: t }))
                ]

                currentIndex: 0

                // Imperatively update currentIndex — declarative bindings break
                // when ComboBox internally resets on model changes.
                function updateIndex() {
                    const saved = Config.options.appearance.iconTheme;
                    if (saved && iconThemeProc.themes.length > 0) {
                        const idx = iconThemeProc.themes.indexOf(saved);
                        currentIndex = idx >= 0 ? idx + 1 : 0;
                    } else {
                        currentIndex = 0;
                    }
                }

                onModelChanged: Qt.callLater(updateIndex)
                Component.onCompleted: Qt.callLater(updateIndex)

                onActivated: index => {
                    const theme = model[index].value;
                    Config.options.appearance.iconTheme = theme;
                    const scriptDir = Directories.scriptPath + "/colors";
                    // icon-accentize.sh handles variant resolution (WhiteSur -> WhiteSur-dark)
                    // and sets the correct theme in gsettings/kdeglobals automatically
                    Quickshell.execDetached(["bash", "-c", `'${scriptDir}/icon-accentize.sh'`]);
                }
            }
        }
    }

    // Fonts section
    ContentSection {
        icon: "text_format"
        title: Translation.tr("Fonts")

        ContentSubsection {
            title: Translation.tr("Main font")
            tooltip: Translation.tr("Used for general UI text throughout the shell")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name (e.g., Google Sans Flex)")
                text: Config.options.appearance.fonts.main
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.main = text.trim() || Config.defaults.appearance.fonts.main;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Numbers font")
            tooltip: Translation.tr("Used for displaying numeric values like clocks, counters, and resource monitors")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name")
                text: Config.options.appearance.fonts.numbers
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.numbers = text.trim() || Config.defaults.appearance.fonts.numbers;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Title font")
            tooltip: Translation.tr("Used for headings and section titles")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family name")
                text: Config.options.appearance.fonts.title
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.appearance.fonts.title = text.trim() || Config.defaults.appearance.fonts.title;
                }
            }
        }

        ConfigRow {
            uniform: true
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Monospace font")
                tooltip: Translation.tr("Used for code, terminal output, and fixed-width text")

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g., JetBrains Mono NF")
                    text: Config.options.appearance.fonts.monospace
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.monospace = text.trim() || Config.defaults.appearance.fonts.monospace;
                    }
                }
            }

            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Nerd font icons")
                tooltip: Translation.tr("Font providing Nerd Font icon glyphs")

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g., JetBrains Mono NF")
                    text: Config.options.appearance.fonts.iconNerd
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.iconNerd = text.trim() || Config.defaults.appearance.fonts.iconNerd;
                    }
                }
            }
        }

        ConfigRow {
            uniform: true
            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Reading font")
                tooltip: Translation.tr("Used for large blocks of text like notification bodies")

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g., Readex Pro")
                    text: Config.options.appearance.fonts.reading
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.reading = text.trim() || Config.defaults.appearance.fonts.reading;
                    }
                }
            }

            ContentSubsection {
                Layout.fillWidth: true
                title: Translation.tr("Expressive font")
                tooltip: Translation.tr("Used for decorative and expressive text elements")

                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g., Space Grotesk")
                    text: Config.options.appearance.fonts.expressive
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.expressive = text.trim() || Config.defaults.appearance.fonts.expressive;
                    }
                }
            }
        }
    }
}
