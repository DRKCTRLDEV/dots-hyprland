import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Device information card showing mouse name, battery status, and connection state.
 */
Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: deviceInfoColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    Accessible.role: Accessible.Pane
    Accessible.name: Translation.tr("Device Information")
    Accessible.description: Translation.tr("Shows mouse name and battery status")

    ColumnLayout {
        id: deviceInfoColumn

        spacing: 8

        anchors {
            fill: parent
            margins: 12
        }

        // Device name row
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: Appearance.rounding.full
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "mouse"
                    iconSize: 24
                    color: Appearance.colors.colOnPrimaryContainer
                }

            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: RivalCfg.deviceName || Translation.tr("SteelSeries Mouse")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (RivalCfg.connectionType === "wireless")
                            return Translation.tr("Connected via 2.4 GHz Dongle");
                        else if (RivalCfg.connectionType === "bluetooth")
                            return Translation.tr("Connected via Bluetooth");
                        else if (RivalCfg.connectionType === "wired")
                            return Translation.tr("Connected via USB Cable");
                        else
                            return Translation.tr("Connected");
                    }
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }

            }

            // Refresh button
            GroupButton {
                id: refreshButton

                baseWidth: 36
                baseHeight: 36
                bounce: false // Disable bounce to prevent position shift when held
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer1
                onClicked: RivalCfg.refresh()
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Refresh")
                Accessible.description: Translation.tr("Refresh mouse device information")

                StyledToolTip {
                    text: Translation.tr("Refresh device information")
                }

                contentItem: Item {
                    implicitWidth: refreshIcon.implicitWidth
                    implicitHeight: refreshIcon.implicitHeight

                    MaterialSymbol {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1

                        RotationAnimation on rotation {
                            id: refreshAnimation
                            running: RivalCfg.loading
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }
                }

            }

        }

        // Battery status (if available)
        Loader {
            Layout.fillWidth: true
            active: RivalCfg.hasBattery
            visible: active

            sourceComponent: Rectangle {
                implicitHeight: batteryRow.implicitHeight + 16
                radius: Appearance.rounding.small
                color: {
                    if (RivalCfg.isCharging)
                        return Appearance.colors.colPrimaryContainer;

                    if (RivalCfg.batteryLevel <= 20)
                        return Appearance.colors.colErrorContainer;

                    if (RivalCfg.batteryLevel <= 40)
                        return Appearance.colors.colTertiaryContainer;

                    return Appearance.colors.colLayer1;
                }

                RowLayout {
                    id: batteryRow
                    spacing: 8
                    anchors { fill: parent; margins: 8 }

                    // Battery text on the left
                    StyledText {
                        Layout.fillWidth: true
                        text: RivalCfg.isCharging ? Translation.tr("Charging - %1%").arg(RivalCfg.batteryLevel) : Translation.tr("Battery: %1%").arg(RivalCfg.batteryLevel)
                        color: RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer :
                               RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer :
                               RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer :
                               Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    // Battery icon on the right
                    MaterialSymbol {
                        text: RivalCfg.isCharging ? "battery_charging_full" :
                              RivalCfg.batteryLevel <= 20 ? "battery_alert" :
                              RivalCfg.batteryLevel <= 50 ? "battery_3_bar" :
                              RivalCfg.batteryLevel <= 80 ? "battery_5_bar" : "battery_full"
                        iconSize: Appearance.font.pixelSize.larger
                        color: RivalCfg.isCharging ? Appearance.colors.colOnPrimaryContainer :
                               RivalCfg.batteryLevel <= 20 ? Appearance.colors.colOnErrorContainer :
                               RivalCfg.batteryLevel <= 40 ? Appearance.colors.colOnTertiaryContainer :
                               Appearance.colors.colOnLayer1
                    }
                }

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

            }

        }

    }

}
