import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property bool editable: true
    property string placeholderText
    property alias text: canvasTextArea.text
    property var inputTextArea: canvasTextArea
    readonly property alias displayedText: canvasTextArea.text

    property real defaultHeight: 96
    property real maxHeight: Infinity

    Layout.fillWidth: true
    implicitHeight: Math.min(
        Math.max(defaultHeight, canvasTextArea.contentHeight + canvasTextArea.topPadding + canvasTextArea.bottomPadding),
        maxHeight
    )
    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal
    clip: true

    signal inputTextChanged
    signal keyPressed(var event)

    ScrollView {
        id: textScroll
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        StyledTextArea {
            id: canvasTextArea
            width: textScroll.availableWidth
            readOnly: !root.editable
            placeholderText: root.placeholderText
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.text.length > 0 || root.editable ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
            padding: 10
            persistentSelection: true
            background: null
            onTextChanged: {
                if (root.editable) {
                    root.inputTextChanged();
                }
            }
            Keys.onPressed: (event) => root.keyPressed(event)
        }
    }
}
