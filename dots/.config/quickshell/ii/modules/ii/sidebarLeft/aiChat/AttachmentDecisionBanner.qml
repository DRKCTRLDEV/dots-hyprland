import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Inline decision banner shown above the message input whenever a send needs a
// user decision first: a file whose format the current model can't take as-is
// (convert it?), or a pasted block of text long enough to be a file instead.
Rectangle {
    id: root

    property string title: ""
    property string detail: ""
    property string confirmLabel: Translation.tr("Convert & send")
    property string cancelLabel: Translation.tr("Cancel")
    property string iconName: "description"

    signal confirmed
    signal cancelled

    Layout.fillWidth: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    implicitHeight: contentRow.implicitHeight + 10 * 2

    RowLayout {
        id: contentRow
        anchors {
            fill: parent
            margins: 10
        }
        spacing: 10

        MaterialSymbol {
            text: root.iconName
            iconSize: Appearance.font.pixelSize.hugeass
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.detail.length > 0
                text: root.detail
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        RippleButton {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            implicitHeight: 28
            implicitWidth: 100
            contentItem: StyledText {
                anchors.centerIn: parent
                text: root.confirmLabel
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3onSecondaryContainer
                horizontalAlignment: Text.AlignHCenter
            }
            onClicked: root.confirmed()
        }

        RippleButton {
            Layout.alignment: Qt.AlignVCenter
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer2Base
            implicitHeight: 28
            implicitWidth: 72
            contentItem: StyledText {
                anchors.centerIn: parent
                text: root.cancelLabel
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer1
                horizontalAlignment: Text.AlignHCenter
            }
            onClicked: root.cancelled()
        }
    }
}
