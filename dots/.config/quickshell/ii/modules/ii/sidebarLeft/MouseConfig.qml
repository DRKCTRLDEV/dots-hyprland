import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.mouseConfig
import qs.services

/**
 * MouseCtrl - Mouse configuration widget using rivalcfg for SteelSeries mice.
 * Provides device info, DPI settings, polling rate, and button bindings.
 */
Item {
    id: root

    // Padding for content
    property real padding: 4
    // Input handling for button capture
    property string listeningButton: ""
    // Status message
    property string statusMessage: ""
    property bool statusIsError: false
    // Reference to the main content loader
    property var contentLoader: mainContentLoader

    function mapKeyToAction(key: int, modifiers: int) : string {
        // Common key mappings for rivalcfg
        const keyMap = {
            [Qt.Key_Escape]: "disabled",
            [Qt.Key_Space]: "space",
            [Qt.Key_Return]: "enter",
            [Qt.Key_Enter]: "enter",
            [Qt.Key_Tab]: "tab",
            [Qt.Key_Backspace]: "backspace",
            [Qt.Key_Delete]: "delete",
            [Qt.Key_Insert]: "insert",
            [Qt.Key_Home]: "home",
            [Qt.Key_End]: "end",
            [Qt.Key_PageUp]: "pageup",
            [Qt.Key_PageDown]: "pagedown",
            [Qt.Key_Left]: "left",
            [Qt.Key_Right]: "right",
            [Qt.Key_Up]: "up",
            [Qt.Key_Down]: "down",
            [Qt.Key_F1]: "F1",
            [Qt.Key_F2]: "F2",
            [Qt.Key_F3]: "F3",
            [Qt.Key_F4]: "F4",
            [Qt.Key_F5]: "F5",
            [Qt.Key_F6]: "F6",
            [Qt.Key_F7]: "F7",
            [Qt.Key_F8]: "F8",
            [Qt.Key_F9]: "F9",
            [Qt.Key_F10]: "F10",
            [Qt.Key_F11]: "F11",
            [Qt.Key_F12]: "F12",
            [Qt.Key_Super_L]: "super",
            [Qt.Key_Super_R]: "super",
            [Qt.Key_Meta]: "super"
        };
        if (keyMap[key])
            return keyMap[key];

        // For letter keys
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key).toLowerCase();

        // For number keys
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);

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
    // Key capture for button binding
    Keys.onPressed: (event) => {
        if (root.listeningButton.length > 0) {
            // Map key to rivalcfg action
            const action = mapKeyToAction(event.key, event.modifiers);
            if (action) {
                RivalCfg.setButtonBinding(root.listeningButton, action);
                root.listeningButton = "";
            }
            event.accepted = true;
        }
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

        // Loading state - centered, takes full space
        Loader {
            anchors.fill: parent
            active: RivalCfg.loading
            visible: active
            z: 10

            sourceComponent: Item {
                anchors.fill: parent

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 16

                    MaterialLoadingIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        implicitSize: 48
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Detecting mouse...")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                }

            }

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
                        DeviceInfoCard {
                        }

                        // DPI/Sensitivity Section
                        DpiSection {
                            Layout.fillWidth: true
                        }

                        // Polling Rate Section
                        PollingRateSection {
                            Layout.fillWidth: true
                        }

                        // Button Bindings Section
                        ButtonBindingsSection {
                            Layout.fillWidth: true
                            listeningButton: root.listeningButton
                            onStartListening: (button) => {
                                root.listeningButton = button;
                                root.forceActiveFocus();
                            }
                            onStopListening: {
                                root.listeningButton = "";
                            }
                        }

                        // Reset Button
                        RippleButton {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            implicitHeight: 44
                            buttonRadius: Appearance.rounding.normal
                            colBackground: Appearance.colors.colLayer2
                            onClicked: {
                                RivalCfg.resetToDefaults();
                            }
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr("Reset to Defaults")
                            Accessible.description: Translation.tr("Reset all mouse settings to default values")

                            StyledToolTip {
                                text: Translation.tr("Reset all settings (DPI, polling rate, button bindings) to default values")
                            }

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                MaterialSymbol {
                                    text: "restart_alt"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colOnLayer2
                                }

                                StyledText {
                                    text: Translation.tr("Reset to Defaults")
                                    color: Appearance.colors.colOnLayer2
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }

                            }

                        }

                        // Bottom spacing
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 20
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
