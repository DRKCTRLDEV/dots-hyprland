import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    implicitHeight: infoCol.implicitHeight + 24
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2
    Layout.fillWidth: true
    
    // Battery progress bar
    Rectangle {
        id: fill
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: RivalCfg.hasBattery ? Math.max(0, Math.min(100, RivalCfg.batteryLevel || 0)) / 100 * parent.width : 0
        radius: Appearance.rounding.small
        color: RivalCfg.isCharging ? Appearance.colors.colPrimaryContainer : (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colErrorContainer : (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colTertiaryContainer : Appearance.colors.colLayer3))
        visible: RivalCfg.hasBattery
    }

    ColumnLayout {
        id: infoCol
        anchors { fill: parent; margins: 12 }
        StyledText {
            text: RivalCfg.deviceName
            color: RivalCfg.hasBattery ? (RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer : (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer : (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer1))) : Appearance.colors.colOnLayer2
            font.pixelSize: Appearance.font.pixelSize.large
        }
        StyledText {
            visible: RivalCfg.connectionType !== ""
            text: RivalCfg.connectionType === "wireless" ? "Connected via 2.4 GHz Dongle" : (RivalCfg.connectionType === "bluetooth" ? "Connected via Bluetooth" : "Connected via USB Cable")
            color: Appearance.colors.colSubtext
        }
    }

    // Battery percentage + charging icon
    RowLayout {
        id: batRow
        visible: RivalCfg.hasBattery
        anchors.bottom: parent.bottom
        anchors.margins: 8
        x: calculateBatteryX()

        function calculateBatteryX() {
            var pad = 12
            var level = RivalCfg.batteryLevel || 0
            var pw = fill.width || 0
            var w = batRow.implicitWidth || 40
            if (level > 85 && pw > 0) {
                var overlayX = pw - w - pad
                return overlayX < pad ? pad : overlayX
            }
            return root.width - pad - w
        }

        StyledText {
            text: (RivalCfg.batteryLevel || 0) + "%"
            font { pixelSize: Appearance.font.pixelSize.hugeass; weight: Font.Bold }
            color: (RivalCfg.batteryLevel > 85 && fill.width >= batRow.x + batRow.implicitWidth - 4) ?
                   (RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer :
                   (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer :
                   (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer3))) :
                   Appearance.colors.colOnLayer2
        }
        MaterialSymbol {
            visible: RivalCfg.isCharging
            text: "bolt"; fill: 1
            iconSize: Appearance.font.pixelSize.huge
            color: parent.children[0].color
        }
    }
}