import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.mouseConfig
import qs.services

/**
 * MouseConfig - Mouse configuration widget using rivalcfg for SteelSeries mice.
 * Provides device info, DPI settings, polling rate, and button bindings.
 */
Item {
    id: root

    // Padding for content
    property real padding: 8
    // Input handling for button capture
    property string listeningButton: ""
    // Status message
    property string statusMessage: ""
    property bool statusIsError: false
    // Convert a Qt key code to rivalcfg key name
    function keyToRivalcfg(key: int) : string {
        // rivalcfg only supports base keys - NOT shifted characters like !@#$%
        // So we map Qt key codes directly, ignoring event.text for shifted chars
        const keyMap = {
            // Modifier keys (use Qt.Key_ constants only - hex codes are identical)
            [Qt.Key_Shift]: "Shift", [Qt.Key_Control]: "Ctrl", [Qt.Key_Alt]: "Alt",
            [Qt.Key_Meta]: "LeftSuper", [Qt.Key_AltGr]: "RightAlt",
            [Qt.Key_Super_L]: "LeftSuper", [Qt.Key_Super_R]: "RightSuper",
            // Context Menu
            [Qt.Key_Menu]: "ContextMenu",
            // Special keys
            [Qt.Key_Escape]: "Escape", [Qt.Key_Space]: "Space", [Qt.Key_Return]: "Enter",
            [Qt.Key_Enter]: "Enter", [Qt.Key_Tab]: "Tab", [Qt.Key_Backspace]: "BackSpace",
            [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home",
            [Qt.Key_End]: "End", [Qt.Key_PageUp]: "PageUp", [Qt.Key_PageDown]: "PageDown",
            [Qt.Key_CapsLock]: "CapsLock", [Qt.Key_NumLock]: "NumLock",
            [Qt.Key_ScrollLock]: "ScrollLock", [Qt.Key_Pause]: "PauseBreak", [Qt.Key_Print]: "PrintScreen",
            // Arrow keys
            [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
            // Function keys
            [Qt.Key_F1]: "F1", [Qt.Key_F2]: "F2", [Qt.Key_F3]: "F3", [Qt.Key_F4]: "F4",
            [Qt.Key_F5]: "F5", [Qt.Key_F6]: "F6", [Qt.Key_F7]: "F7", [Qt.Key_F8]: "F8",
            [Qt.Key_F9]: "F9", [Qt.Key_F10]: "F10", [Qt.Key_F11]: "F11", [Qt.Key_F12]: "F12",
            // Punctuation
            [Qt.Key_Apostrophe]: "quote", [Qt.Key_Comma]: "comma", [Qt.Key_Minus]: "dash",
            [Qt.Key_Period]: "dot", [Qt.Key_Slash]: "slash", [Qt.Key_Semicolon]: "semicolon",
            [Qt.Key_Equal]: "equal", [Qt.Key_BracketLeft]: "leftbracket", [Qt.Key_Backslash]: "backslash",
            [Qt.Key_BracketRight]: "rightbracket", [Qt.Key_QuoteLeft]: "backtick", [Qt.Key_NumberSign]: "hash"
        };
        
        if (keyMap[key]) return keyMap[key];
        
        // Letters A-Z (uppercase for rivalcfg)
        if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key);
        // Numbers 0-9
        if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key);
        
        return null;
    }

    onFocusChanged: (focus) => {
        if (focus) {
            Qt.callLater(() => {
                if (mainContentLoader.item) {
                    mainContentLoader.item.forceActiveFocus();
                }
            });
        }
    }
    // Key capture for button binding - bind directly on key press
    Keys.onPressed: (event) => {
        if (root.listeningButton.length === 0) return; // Not recording, ignore
        
        const keyName = keyToRivalcfg(event.key);
        if (keyName) {
            RivalCfg.setButtonBinding(root.listeningButton, keyName);
            root.listeningButton = "";
        }
        event.accepted = true;
    }

    // Listen for settings applied/error signals
    Connections {
        function onSettingsApplied() {
            root.statusMessage = Translation.tr("Settings applied successfully!");
            root.statusIsError = false;
            statusTimer.restart();
        }

        function onSettingsError(error) {
            root.statusMessage = error;
            root.statusIsError = true;
            statusTimer.restart();
        }

        target: RivalCfg
    }

    Timer {
        id: statusTimer

        interval: 4000
        onTriggered: {
            root.statusMessage = "";
        }
    }

    // Main container - use Item instead of ColumnLayout to avoid stacking issues
    Item {
        anchors {
            fill: parent
            margins: root.padding
        }

        // Error state - centered, takes full space
        Loader {
            anchors.fill: parent
            active: !RivalCfg.loading && !RivalCfg.available
            visible: active
            z: 5

            sourceComponent: Item {
                anchors.fill: parent

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.margins: 20
                    spacing: 16
                    width: parent.width - 40

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "mouse"
                        iconSize: 48
                        color: Appearance.colors.colError
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: RivalCfg.errorMessage
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                        wrapMode: Text.WordWrap
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 120
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSecondaryContainer
                        onClicked: RivalCfg.refresh()

                        StyledToolTip {
                            text: Translation.tr("Click to retry device detection")
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            MaterialSymbol {
                                text: "refresh"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnSecondaryContainer
                            }

                            StyledText {
                                text: Translation.tr("Retry")
                                color: Appearance.colors.colOnSecondaryContainer
                                font.pixelSize: Appearance.font.pixelSize.small
                            }

                        }
                    }

                    // Show udev install button when needed
                    RippleButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 180
                        Layout.topMargin: 8
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colTertiary
                        visible: RivalCfg.needsUdevInstall
                        onClicked: RivalCfg.installUdevRules()

                        StyledToolTip {
                            text: Translation.tr("Install udev rules to allow access to SteelSeries mice without root")
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            MaterialSymbol {
                                text: "terminal"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnTertiary
                            }

                            StyledText {
                                text: Translation.tr("Install udev rules")
                                color: Appearance.colors.colOnTertiary
                                font.pixelSize: Appearance.font.pixelSize.small
                            }

                        }
                    }

                }

            }

        }

        // Main content when device is available
        Loader {
            id: mainContentLoader

            anchors.fill: parent
            active: !RivalCfg.loading && RivalCfg.available
            visible: active

            sourceComponent: Item {
                anchors.fill: parent

                StyledFlickable {
                    id: contentFlickable

                    anchors.fill: parent
                    contentHeight: mainColumn.implicitHeight
                    clip: true
                    pixelAligned: true
                    synchronousDrag: true

                    ColumnLayout {
                        id: mainColumn

                        spacing: 12
                        width: contentFlickable.width

                        anchors {
                            left: parent.left
                            right: parent.right
                        }

                        // Device Info Section
                        DeviceCard {
                        }

                        // DPI/Sensitivity Section
                        DPICard {
                        }

                        // Button Bindings Section
                        BindingsCard {
                            listeningButton: root.listeningButton
                            onStartListening: (button) => {
                                root.listeningButton = button;
                                root.forceActiveFocus();
                            }
                            onStopListening: {
                                root.listeningButton = "";
                            }
                        }
                    }
                }

                // Status message - pinned to bottom
                Loader {
                    active: root.statusMessage.length > 0
                    visible: active
                    z: 1000

                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 12
                    }

                    sourceComponent: Rectangle {
                        implicitHeight: statusRow.implicitHeight + 16
                        radius: Appearance.rounding.small
                        color: root.statusIsError ? Appearance.colors.colErrorContainer : Appearance.colors.colPrimaryContainer

                        RowLayout {
                            id: statusRow

                            spacing: 8

                            anchors {
                                fill: parent
                                margins: 8
                            }

                            MaterialSymbol {
                                text: root.statusIsError ? "error" : "check_circle"
                                iconSize: Appearance.font.pixelSize.larger
                                color: root.statusIsError ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: root.statusMessage
                                color: root.statusIsError ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnPrimaryContainer
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                wrapMode: Text.WordWrap
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }

                        }

                    }

                }

            }

        }

    }

}
