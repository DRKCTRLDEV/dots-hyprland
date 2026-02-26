import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    implicitHeight: infoColumn.implicitHeight + 24
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2
    Layout.fillWidth: true

    // Battery-progress
    Rectangle {
        id: progressFill
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: (RivalCfg.hasBattery && typeof RivalCfg.batteryLevel !== 'undefined') ? Math.max(0, Math.min(100, RivalCfg.batteryLevel)) / 100 * parent.width : 0
        color: RivalCfg.isCharging ? Appearance.colors.colPrimaryContainer : (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colErrorContainer : (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colTertiaryContainer : Appearance.colors.colLayer1))
        radius: Appearance.rounding.normal
        opacity: RivalCfg.hasBattery ? 1 : 0
        z: 0
    }

    ColumnLayout {
        id: infoColumn
        anchors.fill: parent
        anchors.margins: 12

        StyledText {
            Layout.fillWidth: true
            visible: (typeof RivalCfg.deviceName !== 'undefined') && (RivalCfg.deviceName !== "")
            text: RivalCfg.deviceName
            color: RivalCfg.hasBattery ? (RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer : (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer : (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer1))) : Appearance.colors.colOnLayer2
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: typeof RivalCfg.connectionType !== 'undefined' && RivalCfg.connectionType !== ""
            text: {
                if (RivalCfg.connectionType === "wireless")
                    return Translation.tr("Connected via 2.4 GHz Dongle");
                else if (RivalCfg.connectionType === "bluetooth")
                    return Translation.tr("Connected via Bluetooth");
                else
                    return Translation.tr("Connected via USB Cable");
            }
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }

    // Battery percentage + charging icon overlay container
    Item {
        id: batteryGroup
        visible: RivalCfg.hasBattery && (typeof RivalCfg.batteryLevel !== 'undefined')
        anchors.fill: parent  // make height equal to root so it doesn't affect implicitHeight

        RowLayout {
            id: batteryRow
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 4

            // horizontal position (left offset) to allow overlay behavior
            x: (function () {
                    var pad = 12;
                    var level = (typeof RivalCfg.batteryLevel !== 'undefined') ? RivalCfg.batteryLevel : -1;
                    var pw = progressFill.width || 0;
                    var w = batteryRow.implicitWidth || 0;
                    if (level > 85) {
                        var overlayX = pw - w - pad; // progressFill.x == 0
                        return overlayX < pad ? pad : overlayX;
                    }
                    return root.width - pad - w;
                })()

            StyledText {
                id: batteryPercent
                visible: (typeof RivalCfg.batteryLevel !== 'undefined') && RivalCfg.hasBattery
                text: (typeof RivalCfg.batteryLevel !== 'undefined') ? (RivalCfg.batteryLevel + "%") : ""
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.family: Appearance.font.family.numbers
                font.weight: Font.Bold
                z: 2
                // Color for contrast when overlayed on the filled area
                color: ((typeof RivalCfg.batteryLevel !== 'undefined' && RivalCfg.batteryLevel > 85) && (progressFill.width >= batteryGroup.x + batteryRow.implicitWidth - 4)) ? (RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer : (RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer : (RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colOnLayer1))) : Appearance.colors.colOnLayer2
            }

            MaterialSymbol {
                id: chargingIcon
                visible: RivalCfg.isCharging && (typeof RivalCfg.batteryLevel !== 'undefined')
                text: "bolt"
                fill: 1
                iconSize: Appearance.font.pixelSize.hugeass
                color: batteryPercent.color
                z: 2
            }
        }
    }
}
