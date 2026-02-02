import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Polling rate configuration section with dropdown selector.
 */
Rectangle {
    id: root

    implicitHeight: pollingColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    Accessible.role: Accessible.Pane
    Accessible.name: Translation.tr("Polling Rate Settings")
    Accessible.description: Translation.tr("Configure mouse polling rate")

    ColumnLayout {
        id: pollingColumn

        spacing: 12

        anchors {
            fill: parent
            margins: 12
        }

        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: "timer"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Polling Rate")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
            }

            // Info tooltip (non-clickable)
            Item {
                implicitWidth: 24
                implicitHeight: 24

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "help_outline"
                    iconSize: Appearance.font.pixelSize.normal
                    color: pollingHelpHover.hovered ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                HoverHandler {
                    id: pollingHelpHover
                }

                StyledToolTip {
                    visible: pollingHelpHover.hovered
                    text: Translation.tr("Polling rate determines how often the mouse reports its position.\nHigher rates = smoother movement but more CPU usage.\n\n• 125Hz: 8ms response (basic)\n• 250Hz: 4ms response (good)\n• 500Hz: 2ms response (better)\n• 1000Hz: 1ms response (best for gaming)")
                }
            }

        }

        // Polling rate dropdown
        StyledComboBox {
            id: pollingRateCombo

            Layout.fillWidth: true
            buttonIcon: "timer"
            // Use device-supported polling rates from RivalCfg service
            model: RivalCfg.pollingRates.map(rate => ({
                "displayText": rate >= 1000 
                    ? `${rate} Hz (${1000/rate}ms)` 
                    : `${rate} Hz (${Math.round(1000/rate)}ms)`,
                "value": rate
            }))
            textRole: "displayText"
            valueRole: "value"
            currentIndex: {
                const idx = model.findIndex((item) => {
                    return item.value === RivalCfg.pollingRate;
                });
                return idx >= 0 ? idx : model.length - 1; // Default to highest rate
            }
            onActivated: (index) => {
                const newRate = model[index].value;
                if (newRate !== RivalCfg.pollingRate) {
                    RivalCfg.setPollingRate(newRate);
                    rateChangeAnimation.restart();
                }
            }
            Accessible.role: Accessible.ComboBox
            Accessible.name: Translation.tr("Polling Rate")
            Accessible.description: Translation.tr("Select mouse polling rate")

            // Animated feedback
            Rectangle {
                id: rateChangeFeedback

                anchors.fill: parent
                radius: parent.buttonRadius
                color: Appearance.colors.colPrimary
                opacity: 0

                NumberAnimation on opacity {
                    id: rateChangeAnimation

                    running: false
                    from: 0.3
                    to: 0
                    duration: 500
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

}
