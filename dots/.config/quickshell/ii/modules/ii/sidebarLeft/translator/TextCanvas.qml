import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool isInput: true // true for input, false for output
    property string placeholderText
    property string text: ""

    readonly property string displayedText: isInput
        ? (inputTextArea ? inputTextArea.text : "")
        : (root.text.length > 0 ? root.text : root.placeholderText)
    property int charCount: isInput
        ? (inputTextArea ? inputTextArea.text.length : 0)
        : root.text.length
    property int wordCount: isInput
        ? (inputTextArea ? inputTextArea.text.trim().split(/\s+/).filter(w => w.length > 0).length : 0)
        : (root.text.trim() ? root.text.trim().split(/\s+/).filter(w => w.length > 0).length : 0)

    // Expose the text edit for external access (e.g., forceActiveFocus)
    property var inputTextArea: inputLoader.item ? inputLoader.item.textEdit : null
    property var outputTextArea: outputLoader.item ? outputLoader.item.textDisplay : null

    signal inputTextChanged() // Signal emitted when text changes

    // Calculate implicit height based on content
    implicitHeight: isInput
        ? (inputTextArea ? inputTextArea.implicitHeight + 12 : 60)
        : (outputTextArea ? outputTextArea.implicitHeight + 12 : 60)

    // Flickable wrapper for input
    Loader {
        id: inputLoader
        active: root.isInput
        visible: root.isInput
        anchors.fill: parent
        sourceComponent: Component {
            Flickable {
                id: inputFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: textEdit.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Property to expose the text edit
                property alias textEdit: textEdit

                StyledTextArea {
                    id: textEdit
                    width: parent.width
                    height: Math.max(implicitHeight, inputFlickable.height)
                    placeholderText: root.placeholderText
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    verticalAlignment: TextEdit.AlignTop
                    onTextChanged: root.inputTextChanged()
                    padding: 0
                }

                // Scrollbar
                ScrollBar.vertical: ScrollBar {
                    policy: textEdit.implicitHeight > inputFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }
    }

    // Flickable wrapper for output
    Loader {
        id: outputLoader
        active: !root.isInput
        visible: !root.isInput
        anchors.fill: parent
        sourceComponent: Component {
            Flickable {
                id: outputFlickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: textDisplay.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Property to expose the text display
                property alias textDisplay: textDisplay

                StyledText {
                    id: textDisplay
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.text.length > 0 ? root.text : root.placeholderText
                    verticalAlignment: Text.AlignTop
                }

                // Scrollbar
                ScrollBar.vertical: ScrollBar {
                    policy: textDisplay.implicitHeight > outputFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }
    }
}
