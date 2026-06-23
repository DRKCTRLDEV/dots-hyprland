import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

GroupButton {
    id: root
    property string iconName: ""
    property string labelText: ""
    property string tooltipText: ""
    property real iconSize: Appearance.font.pixelSize.larger
    property real labelPixelSize: Appearance.font.pixelSize.small
    property real buttonSize: 36

    baseWidth: root.buttonSize
    baseHeight: root.buttonSize
    clickedWidth: baseWidth
    clickedHeight: baseHeight
    horizontalPadding: 0
    verticalPadding: 0
    buttonRadius: Appearance.rounding.small
    bounce: false

    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.minimumWidth: baseWidth
    Layout.preferredWidth: baseWidth
    Layout.maximumWidth: baseWidth
    Layout.minimumHeight: baseHeight
    Layout.preferredHeight: baseHeight
    Layout.maximumHeight: baseHeight

    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundActive: Appearance.colors.colLayer2Active

    contentItem: Item {
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.labelText.length === 0
            iconSize: root.iconSize
            text: root.iconName
            color: root.enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
        }
        StyledText {
            anchors.centerIn: parent
            visible: root.labelText.length > 0
            text: root.labelText
            color: root.enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
            font.pixelSize: root.labelPixelSize
        }
    }

    Loader {
        active: root.tooltipText.length > 0
        anchors.fill: parent
        sourceComponent: MouseArea {
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            StyledToolTip {
                text: root.tooltipText
                extraVisibleCondition: false
                alternativeVisibleCondition: parent.containsMouse
            }
        }
    }
}
