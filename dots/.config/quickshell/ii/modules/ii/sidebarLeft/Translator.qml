import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Translator widget with the `trans` commandline tool.
 */
Item {
    id: root

    // Sizes
    property real padding: 8

    // Widget references
    property var inputTextArea: inputSection.textCanvas.inputTextArea

    // Widget variables
    property bool translationFor: false // Indicates if the translation is for an autocorrected text
    property string translatedText: ""
    property list<string> languages: []

    // Options
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage

    onFocusChanged: focus => {
        if (focus && root.inputTextArea) {
            root.inputTextArea.forceActiveFocus();
        }
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputTextArea && root.inputTextArea.text && root.inputTextArea.text.trim().length > 0) {
                translateProc.running = false;
                translateProc.buffer = ""; // Clear the buffer
                translateProc.running = true; // Restart the process
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c",
            `trans -brief -from '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}' -to '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}' '${StringUtils.shellSingleQuoteEscape(root.inputTextArea ? root.inputTextArea.text.trim() : "")}'`
        ]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // With -brief mode, we get output with no metadata
            root.translatedText = translateProc.buffer.trim();
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Ensure "auto" is always the first language
            let langs = getLanguagesProc.bufferList.filter(lang => lang.trim().length > 0 && lang !== "auto").sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = []; // Clear the buffer
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }

        // Output section
        TranslatorSection {
            id: outputSection
            isInput: false
            languages: root.languages
            currentLanguage: root.targetLanguage
            text: root.translatedText

            onLanguageSelected: newLanguage => {
                root.targetLanguage = newLanguage;
                Config.options.language.translator.targetLanguage = newLanguage;
                // Retranslate if there's input text
                if (root.inputTextArea && root.inputTextArea.text && root.inputTextArea.text.trim().length > 0) {
                    translateTimer.restart();
                }
            }

            onActionTriggered: action => {
                if (action === "copy") {
                    Quickshell.clipboardText = textCanvas.displayedText;
                } else if (action === "search") {
                    let url = Config.options.search.engineBaseUrl + textCanvas.displayedText;
                    for (let site of Config.options.search.excludedSites) {
                        if (site.trim() !== "") {
                            url += ` -site:${site}`;
                        }
                    }
                    Qt.openUrlExternally(url);
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Input section
        TranslatorSection {
            id: inputSection
            isInput: true
            languages: root.languages
            currentLanguage: root.sourceLanguage
            placeholderText: Translation.tr("Enter text to translate...")

            onLanguageSelected: newLanguage => {
                root.sourceLanguage = newLanguage;
                Config.options.language.translator.sourceLanguage = newLanguage;
                // Retranslate if there's input text
                if (root.inputTextArea && root.inputTextArea.text && root.inputTextArea.text.trim().length > 0) {
                    translateTimer.restart();
                }
            }

            onInputTextEdited: {
                translateTimer.restart();
            }

            onActionTriggered: action => {
                if (!root.inputTextArea) return;
                if (action === "paste") {
                    root.inputTextArea.text = Quickshell.clipboardText;
                } else if (action === "delete") {
                    root.inputTextArea.text = "";
                }
            }
        }
    }
}
