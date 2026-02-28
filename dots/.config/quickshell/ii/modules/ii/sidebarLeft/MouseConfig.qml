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

Item {
    id: root

    property string listeningButton: ""

    onFocusChanged: {
        if (focus) {
            Qt.callLater(function() {
                if (mainContentLoader.item) mainContentLoader.item.forceActiveFocus()
            })
        }
    }

    Keys.onPressed: {
        if (!root.listeningButton) return
        var k = KeyLib.keyToRivalcfg(event.key)
        if (k) {
            RivalCfg.setButtonBinding(root.listeningButton, k)
            root.listeningButton = ""
        }
        event.accepted = true
    }

    Connections {
        target: RivalCfg
        function onSettingsApplied() {
            Quickshell.execDetached(["notify-send", "Mouse Config", "Settings applied!", "-a", "Shell"])
        }
        function onSettingsError(e) {
            Quickshell.execDetached(["notify-send", "Mouse Config", e, "-a", "Shell", "-u", "critical"])
        }
    }

    Loader {
        anchors { fill: parent; margins: 8 }
        active: !RivalCfg.available
        sourceComponent: ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 16
            MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "mouse"; iconSize: 48; color: Appearance.colors.colError }
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: RivalCfg.errorMessage
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
            }
            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: RivalCfg.refresh()
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol { text: "refresh"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnSecondaryContainer }
                    StyledText { text: "Retry"; color: Appearance.colors.colOnSecondaryContainer; font.pixelSize: Appearance.font.pixelSize.small }
                }
            }
            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 180
                Layout.topMargin: 8
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colTertiary
                visible: RivalCfg.needsUdevInstall
                onClicked: RivalCfg.installUdevRules()
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol { text: "terminal"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colOnTertiary }
                    StyledText { text: "Install udev rules"; color: Appearance.colors.colOnTertiary; font.pixelSize: Appearance.font.pixelSize.small }
                }
            }
        }
    }

    Loader {
        id: mainContentLoader
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        height: item ? item.implicitHeight : 0
        active: RivalCfg.available
        sourceComponent: ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 8
            DeviceCard {}
            ControlCard {
                listeningButton: root.listeningButton
                onStartListening: function(b) { root.listeningButton = b; root.forceActiveFocus() }
                onStopListening: root.listeningButton = ""
            }
        }
    }
}