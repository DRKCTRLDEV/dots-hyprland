import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * A reusable section component for the Translator (input or output).
 * Contains a controls row with language selector, stats, and action buttons,
 * followed by a TextCanvas for text content.
 */
Rectangle {
    id: root

    // Configuration properties
    property bool isInput: true
    property var languages: []
    property string currentLanguage: "auto"
    property string placeholderText: ""
    property string text: ""

    // Expose the text canvas for external access
    property alias textCanvas: textCanvas

    // Signals (using unique names to avoid conflicts with property change signals)
    signal languageSelected(string newLanguage)
    signal inputTextEdited()
    signal actionTriggered(string action)

    // Layout properties
    Layout.fillWidth: true
    Layout.preferredHeight: sectionColumn.implicitHeight + 24
    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.small

    ColumnLayout {
        id: sectionColumn
        anchors {
            fill: parent
            margins: 12
        }

        // Controls row
        RowLayout {
            spacing: 6

            StyledComboBox {
                id: languageCombo
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                model: root.languages
                currentIndex: Math.max(0, model.indexOf(root.currentLanguage))
                onActivated: index => {
                    root.languageSelected(model[index]);
                }
            }

            // Statistics rectangle
            Rectangle {
                Layout.preferredHeight: 36
                Layout.minimumWidth: statsText.implicitWidth + 24
                radius: Appearance.rounding.small
                color: Appearance.colors.colSecondaryContainer
                visible: Config.options.sidebar.translator.showCharCount

                StyledText {
                    id: statsText
                    anchors.centerIn: parent
                    text: textCanvas.charCount + " chars • " + textCanvas.wordCount + " words"
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }

            // Action buttons
            Row {
                spacing: 6
                // Input-only buttons
                GroupButton {
                    id: pasteButton
                    visible: isInput
                    baseWidth: 36; baseHeight: 36
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.normal
                        text: "content_paste"
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    onClicked: root.actionTriggered("paste")
                }

                GroupButton {
                    id: deleteButton
                    visible: isInput
                    baseWidth: 36; baseHeight: 36
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    enabled: textCanvas.inputTextArea ? textCanvas.inputTextArea.text.length > 0 : false
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "close"
                        color: deleteButton.enabled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                    }
                    onClicked: root.actionTriggered("delete")
                }

                // Output-only buttons
                GroupButton {
                    id: copyButton
                    visible: !isInput
                    baseWidth: 36; baseHeight: 36
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    enabled: textCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.normal
                        text: "content_copy"
                        color: copyButton.enabled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                    }
                    onClicked: root.actionTriggered("copy")
                }

                GroupButton {
                    id: searchButton
                    visible: !isInput
                    baseWidth: 36; baseHeight: 36
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    enabled: textCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.normal
                        text: "travel_explore"
                        color: searchButton.enabled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                    }
                    onClicked: root.actionTriggered("search")
                }
            }
        }

        // Separator
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; Layout.margins: 6; color: Appearance.colors.colLayer3 }

        // Content area
        TextCanvas {
            id: textCanvas
            isInput: root.isInput
            placeholderText: root.placeholderText
            text: root.text
            Layout.fillWidth: true
            Layout.maximumHeight: 400

            onInputTextChanged: {
                if (isInput) {
                    root.inputTextEdited();
                }
            }
        }
    }
}
