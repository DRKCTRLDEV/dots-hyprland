import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    PagePlaceholder {
        anchors.fill: parent
        z: 9999
        shown: root.inputText.trim().length === 0 && root.outputText.trim().length === 0
        icon: "translate"
        title: ""
        description: ""
        shape: MaterialShape.Shape.PixelCircle
    }

    property real padding: 4
    property var inputField: inputCanvas.inputTextArea
    property string translatedText: ""
    property list<string> languages: []
    property string speakText: ""

    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage

    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false
    property bool swapping: false

    readonly property real controlHeight: 36
    readonly property real countHeight: controlHeight
    readonly property real controlRadius: Appearance.rounding.small
    readonly property real controlSpacing: 6
    readonly property real canvasMaxHeight: Math.max(0, columnLayout.height - controlHeight * 2 - controlSpacing * 4) / 2
    readonly property real targetCanvasHeight: Math.min(Math.max(outputCanvas.implicitHeight, inputCanvas.implicitHeight), root.canvasMaxHeight)

    readonly property string inputText: inputField ? inputField.text : ""
    readonly property string outputText: outputCanvas.displayedText

    function charCountFor(text) {
        return text.length;
    }

    function wordCountFor(text) {
        const trimmed = text.trim();
        return trimmed.length > 0 ? trimmed.split(/\s+/).length : 0;
    }

    function showLanguageSelectorDialog(isTargetLang) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true;
    }

    function swapLanguages() {
        if (root.swapping)
            return;
        root.swapping = true;
        const oldSource = root.sourceLanguage;
        const oldTarget = root.targetLanguage;
        const translated = root.outputText.trim();

        root.sourceLanguage = oldTarget;
        root.targetLanguage = oldSource;

        if (translated.length > 0 && root.inputField) {
            root.inputField.text = translated;
        }

        Config.options.language.translator.sourceLanguage = root.sourceLanguage;
        Config.options.language.translator.targetLanguage = root.targetLanguage;
        translateTimer.restart();
    }

    function actionButtonColor(enabled) {
        return enabled ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext;
    }

    function speakOutput() {
        const text = root.outputText.trim();
        if (text.length === 0) {
            return;
        }
        root.speakText = text;
        speakProc.running = false;
        speakProc.running = true;
    }

    onFocusChanged: focus => {
        if (focus && root.inputField) {
            root.inputField.forceActiveFocus();
        }
    }

    component TranslatorActionButton: IconButton {
        id: actionButton
        property string iconName: ""

        buttonSize: root.controlHeight
        iconSize: Appearance.font.pixelSize.larger

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            iconSize: actionButton.iconSize
            text: actionButton.iconName
            color: root.actionButtonColor(actionButton.enabled)
        }
    }

    component CountBadge: Rectangle {
        id: countBadge
        property int charCount: 0
        property int wordCount: 0
        property string tooltipText: ""
        readonly property bool compactMode: width < 130

        implicitHeight: root.countHeight
        radius: root.controlRadius
        color: Appearance.colors.colLayer2

        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight
        clip: true

        Loader {
            anchors.centerIn: parent
            sourceComponent: countBadge.compactMode ? compactContent : fullContent
        }

        Component {
            id: fullContent
            RowLayout {
                spacing: 4
                StyledText {
                    text: `${countBadge.charCount} chars`
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: "|"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${countBadge.wordCount} words`
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Component {
            id: compactContent
            RowLayout {
                spacing: 4
                MaterialSymbol {
                    text: "text_fields"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${countBadge.charCount}`
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: "|"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
                MaterialSymbol {
                    text: "notes"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer2
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: `${countBadge.wordCount}`
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Loader {
            active: countBadge.tooltipText.length > 0
            anchors.fill: parent
            sourceComponent: MouseArea {
                id: countBadgeArea
                hoverEnabled: true
                StyledToolTip {
                    text: countBadge.tooltipText
                    extraVisibleCondition: false
                    alternativeVisibleCondition: countBadgeArea.containsMouse
                }
            }
        }
    }

    component ControlsRow: Item {
        id: row
        property string languageText: ""
        property string languageTooltip: ""
        property int charCount: 0
        property int wordCount: 0
        signal languageClicked
        property var actions: []

        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.minimumHeight: root.controlHeight
        Layout.preferredHeight: root.controlHeight
        Layout.maximumHeight: root.controlHeight

        RowLayout {
            anchors.fill: parent
            spacing: root.controlSpacing

            LanguageSelectorButton {
                displayText: row.languageText
                onClicked: row.languageClicked()
            }

            CountBadge {
                charCount: row.charCount
                wordCount: row.wordCount
            }

            ButtonGroup {
                spacing: root.controlSpacing
                Layout.fillHeight: false
                Layout.minimumHeight: root.controlHeight
                Layout.preferredHeight: root.controlHeight
                Layout.maximumHeight: root.controlHeight

                Repeater {
                    model: row.actions
                    delegate: TranslatorActionButton {
                        visible: modelData.visible === undefined ? true : modelData.visible
                        iconName: modelData.icon ? modelData.icon : ""
                        tooltipText: modelData.tooltipText ? modelData.tooltipText : ""
                        enabled: modelData.enabled === undefined ? true : modelData.enabled
                        onClicked: {
                            if (modelData.onClicked) {
                                modelData.onClicked();
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputText.trim().length > 0) {
                translateProc.running = false;
                translateProc.buffer = "";
                translateProc.running = true;
            } else {
                root.translatedText = "";
                root.swapping = false;
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi` + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'` + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'` + ` '${StringUtils.shellSingleQuoteEscape(root.inputText.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: () => {
            root.translatedText = translateProc.buffer.trim();
            root.swapping = false;
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: []
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lang = data.trim();
                if (lang.length > 0 && lang !== "auto") {
                    getLanguagesProc.bufferList.push(lang);
                }
            }
        }
        onExited: () => {
            const langs = getLanguagesProc.bufferList.slice().sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = [];
        }
    }

    Process {
        id: speakProc
        command: ["bash", "-c", `if command -v spd-say >/dev/null 2>&1; then spd-say '${StringUtils.shellSingleQuoteEscape(root.speakText)}'; elif command -v espeak >/dev/null 2>&1; then espeak '${StringUtils.shellSingleQuoteEscape(root.speakText)}'; elif command -v trans >/dev/null 2>&1; then trans -no-bidi -speak '${StringUtils.shellSingleQuoteEscape(root.speakText)}' >/dev/null 2>&1 || trans -no-bidi -play '${StringUtils.shellSingleQuoteEscape(root.speakText)}' >/dev/null 2>&1; fi`]
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.controlSpacing

        ControlsRow {
            languageText: root.targetLanguage
            languageTooltip: Translation.tr("Target language")
            charCount: root.charCountFor(root.outputText)
            wordCount: root.wordCountFor(root.outputText)
            onLanguageClicked: root.showLanguageSelectorDialog(true)
            actions: [
                {
                    icon: "content_copy",
                    enabled: root.outputText.trim().length > 0,
                    onClicked: function () {
                        Quickshell.clipboardText = root.outputText;
                    }
                },
                {
                    icon: "travel_explore",
                    enabled: root.outputText.trim().length > 0,
                    onClicked: function () {
                        let url = Config.options.search.engineBaseUrl + root.outputText;
                        for (let site of Config.options.search.excludedSites) {
                            url += ` -site:${site}`;
                        }
                        Qt.openUrlExternally(url);
                    }
                },
                {
                    icon: "volume_up",
                    enabled: root.outputText.trim().length > 0,
                    onClicked: function () {
                        root.speakOutput();
                    }
                }
            ]
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: root.controlSpacing

                TextCanvas {
                    id: outputCanvas
                    editable: false
                    Layout.preferredHeight: root.targetCanvasHeight
                    placeholderText: Translation.tr("Translation goes here...")
                    text: root.translatedText.trim().length > 0 ? root.translatedText : ""
                }

                Item {
                    Layout.fillHeight: true
                }

                TextCanvas {
                    id: inputCanvas
                    editable: true
                    Layout.preferredHeight: root.targetCanvasHeight
                    placeholderText: Translation.tr("Enter text to translate...")
                    onInputTextChanged: translateTimer.restart()
                }
            }
        }

        ControlsRow {
            languageText: root.sourceLanguage
            languageTooltip: Translation.tr("Source language")
            charCount: root.charCountFor(root.inputText)
            wordCount: root.wordCountFor(root.inputText)
            onLanguageClicked: root.showLanguageSelectorDialog(false)
            actions: [
                {
                    icon: "content_paste",
                    onClicked: function () {
                        root.inputField.text = Quickshell.clipboardText;
                    }
                },
                {
                    icon: "swap_horiz",
                    enabled: !root.swapping,
                    onClicked: function () {
                        root.swapLanguages();
                    }
                },
                {
                    icon: "delete",
                    enabled: root.inputText.length > 0,
                    onClicked: function () {
                        root.inputField.text = "";
                    }
                }
            ]
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            titleText: Translation.tr("Select Language")
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: result => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) {
                    return;
                }

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result;
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result;
                }

                translateTimer.restart();
            }
        }
    }
}
