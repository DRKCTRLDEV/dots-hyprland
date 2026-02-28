pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * DPI Preset Chip component for mouse configuration sidebar.
 * Displays a DPI value and allows selection and removal.
 * Can also function as an add button when isAddButton is true.
 */
GroupButton {
    id: root

    property int dpiValue: 800
    property int presetIndex: 0
    property bool isSelected: false
    property bool leftmost: false
    property bool rightmost: false
    property bool isAddButton: false
    property bool canAdd: true

    leftRadius: isAddButton ? buttonRadius : (isSelected || leftmost) ? (height / 2) : Appearance.rounding.unsharpenmore
    rightRadius: isAddButton ? buttonRadius : (isSelected || rightmost) ? (height / 2) : Appearance.rounding.unsharpenmore

    signal presetSelected(int index)
    signal presetRemoveRequested(int index)
    signal addRequested()

    baseWidth: isAddButton ? 36 : chipRow.implicitWidth + horizontalPadding * 2
    baseHeight: 36
    bounce: false
    clip: true
    enabled: isAddButton ? canAdd : true

    toggled: isAddButton ? false : isSelected

    colBackground: Appearance.colors.colSecondaryContainer
    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
    colBackgroundActive: Appearance.colors.colSecondaryContainerActive
    colBackgroundToggled: Appearance.colors.colPrimaryContainer
    colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover
    colBackgroundToggledActive: Appearance.colors.colPrimaryContainerActive

    onClicked: {
        if (isAddButton) {
            addRequested()
        } else {
            presetSelected(presetIndex)
        }
    }

    MouseArea {
        id: rightClickArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.RightButton
        visible: !root.isAddButton
        onClicked: {
            presetRemoveRequested(presetIndex)
        }
    }

    contentItem: RowLayout {
        id: chipRow
        visible: !root.isAddButton
        Item {
            implicitWidth: dpiText.implicitWidth
            implicitHeight: dpiText.implicitHeight
            StyledText {
                id: dpiText
                text: root.dpiValue.toString()
                font.pixelSize: Appearance.font.pixelSize.larger
                animateChange: true
                color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                Layout.alignment: Qt.AlignVCenter
            }
        }
        Rectangle {
            id: closeButton
            implicitWidth: 24; implicitHeight: 24
            color: "transparent"
            visible: root.hovered || root.isSelected
            MaterialSymbol {
                id: closeIcon
                anchors.centerIn: parent
                text: "close"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                rotation: closeMouseArea.containsMouse ? 90 : 0
                transformOrigin: Item.Center
                Behavior on rotation {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }
            MouseArea {
                id: closeMouseArea
                anchors.centerIn: parent
                width: 32; height: 32
                hoverEnabled: true
                onClicked: {
                    root.presetRemoveRequested(root.presetIndex)
                }
            }
        }
    }

    Item {
        id: addButtonContent
        visible: root.isAddButton
        anchors.centerIn: parent
        implicitWidth: addIcon.implicitWidth
        implicitHeight: addIcon.implicitHeight
        MaterialSymbol {
            id: addIcon
            anchors.centerIn: parent
            text: "add"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSecondaryContainer
            rotation: root.hovered ? 90 : 0
            transformOrigin: Item.Center
            Behavior on rotation {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
        }
    }
}
