import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.aiChat
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root

    PagePlaceholder {
        anchors.fill: parent
        z: 9999
        shown: Ai.messageIDs.length === 0
        icon: "neurology"
        title: ""
        description: ""
        shape: MaterialShape.Shape.PixelCircle
    }

    property real padding: 4
    property var inputField: messageInputField
    property string commandPrefix: "/"

    property var suggestionQuery: ""
    property var suggestionList: []
    readonly property real controlHeight: 36
    readonly property real controlSpacing: 6
    readonly property real inputDefaultHeight: 96
    readonly property real inputMaxHeight: Math.max(0, columnLayout.height - controlHeight - root.padding * 4) / 2

    onFocusChanged: focus => {
        if (focus) {
            root.inputField.inputTextArea.forceActiveFocus();
        }
    }

    Keys.onPressed: event => {
        messageInputField.inputTextArea.forceActiveFocus();
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                messageListView.contentY = Math.max(0, messageListView.contentY - messageListView.height / 2);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                messageListView.contentY = Math.min(messageListView.contentHeight - messageListView.height / 2, messageListView.contentY + messageListView.height / 2);
                event.accepted = true;
            }
        }
        if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_O) {
            Ai.clearMessages();
        }
    }

    property var suggestionCommands: [
        { prefix: "model", items: () => Ai.modelList, display: n => Ai.models[n].name, desc: n => Ai.models[n].description },
        { prefix: "prompt", items: () => Ai.getPromptFiles(), display: n => FileUtils.trimFileExt(FileUtils.fileNameForPath(n)), desc: n => Translation.tr("Load prompt from %1").arg(n) },
        { prefix: "save", items: () => Ai.savedChats, display: n => FileUtils.trimFileExt(FileUtils.fileNameForPath(n)).trim(), desc: n => Translation.tr("Save chat to %1").arg(FileUtils.trimFileExt(FileUtils.fileNameForPath(n)).trim()) },
        { prefix: "load", items: () => Ai.savedChats, display: n => FileUtils.trimFileExt(FileUtils.fileNameForPath(n)).trim(), desc: n => Translation.tr("Load chat from %1").arg(n) },
        { prefix: "tool", items: () => Ai.getAvailableTools(), display: n => n, desc: n => Ai.toolDescriptions[n] },
        { prefix: "key", items: () => ["set", "unset"], display: n => n, desc: n => n === "set" ? Translation.tr("Set an API key for the current model") : Translation.tr("Clear the API key") },
    ]

    function getSetCommand(name, description, printFn, setFn, transform) {
        return {
            name: name,
            description: description,
            execute: args => {
                if (args.length === 0 || args[0] === "get") {
                    printFn();
                } else {
                    setFn(transform ? transform(args) : args[0]);
                }
            }
        };
    }

    function argsCommand(name, description, argsName, action) {
        return {
            name: name,
            description: description,
            execute: args => {
                const joined = args.join(" ").trim();
                if (joined.length === 0) {
                    Ai.addMessage(Translation.tr("Usage: %1%2 %3").arg(root.commandPrefix).arg(name).arg(argsName), Ai.interfaceRole);
                    return;
                }
                action(joined);
            }
        };
    }

    property var allCommands: [
        { name: "attach", description: Translation.tr("Attach a file. Only works with Gemini."), execute: args => Ai.attachFile(args.join(" ").trim()) },
        { name: "model", description: Translation.tr("Choose model"), execute: args => Ai.setModel(args[0]) },
        {
            name: "tool",
            description: Translation.tr("Set the tool to use for the model."),
            execute: args => {
                if (args.length === 0 || args[0] === "get") {
                    Ai.addMessage(Translation.tr("Usage: %1tool TOOL_NAME").arg(root.commandPrefix), Ai.interfaceRole);
                } else if (Ai.setTool(args[0])) {
                    Ai.addMessage(Translation.tr("Tool set to: %1").arg(args[0]), Ai.interfaceRole);
                }
            }
        },
        getSetCommand("prompt", Translation.tr("Set the system prompt for the model."), Ai.printPrompt, joined => Ai.loadPrompt(joined), args => args.join(" ").trim()),
        {
            name: "key",
            description: Translation.tr("Manage API key. Use %1key set YOUR_KEY or %1key unset").arg(root.commandPrefix),
            execute: args => {
                if (args.length === 0 || args[0] === "get") {
                    Ai.printApiKey();
                } else if (args[0] === "set") {
                    const keyValue = args.slice(1).join(" ").trim();
                    if (keyValue.length === 0) {
                        Ai.addMessage(Translation.tr("Usage: %1key set YOUR_API_KEY").arg(root.commandPrefix), Ai.interfaceRole);
                    } else {
                        Ai.setApiKey(keyValue);
                    }
                } else if (args[0] === "unset") {
                    Ai.setApiKey("unset");
                } else {
                    Ai.addMessage(Translation.tr("Usage: %1key set YOUR_API_KEY or %1key unset").arg(root.commandPrefix), Ai.interfaceRole);
                }
            }
        },
        argsCommand("save", Translation.tr("Save chat"), "CHAT_NAME", Ai.saveChat),
        argsCommand("load", Translation.tr("Load chat"), "CHAT_NAME", Ai.loadChat),
        { name: "clear", description: Translation.tr("Clear chat history"), execute: () => Ai.clearMessages() },
        getSetCommand("temp", Translation.tr("Set temperature (randomness) of the model. Values range between 0 to 2 for Gemini, 0 to 1 for other models. Default is 0.5."), Ai.printTemperature, temp => Ai.setTemperature(parseFloat(temp))),
        {
            name: "test",
            description: Translation.tr("Markdown test"),
            execute: () => {
                Ai.addMessage(`
<think>
A longer think block to test revealing animation
OwO wem ipsum dowo sit amet, consekituwet awipiscing ewit, sed do eiuwsmod tempow inwididunt ut wabowe et dowo mawa. Ut enim ad minim weniam, quis nostwud exeucitation uwuwamcow bowowis nisi ut awiquip ex ea commowo consequat. Duuis aute iwuwe dowo in wepwependewit in wowuptate velit esse ciwwum dowo eu fugiat nuwa pawiatuw. Excepteuw sint occaecat cupidatat non pwowoident, sunt in cuwpa qui officia desewunt mowit anim id est wabowum. Meouw! >w<
Mowe uwu wem ipsum!
</think>
## ✏️ Markdown test
### Formatting

- *Italic*, \`Monospace\`, **Bold**, [Link](https://example.com)
- Arch lincox icon <img src="${Quickshell.shellPath("assets/icons/arch-symbolic.svg")}" height="${Appearance.font.pixelSize.small}"/>

### Table

Quickshell vs AGS/Astal

|                          | Quickshell       | AGS/Astal         |
|--------------------------|------------------|-------------------|
| UI Toolkit               | Qt               | Gtk3/Gtk4         |
| Language                 | QML              | Js/Ts/Lua         |
| Reactivity               | Implied          | Needs declaration |
| Widget placement         | Mildly difficult | More intuitive    |
| Bluetooth & Wifi support | ❌               | ✅                |
| No-delay keybinds        | ✅               | ❌                |
| Development              | New APIs         | New syntax        |

### Code block

Just a hello world...

\`\`\`cpp
#include <bits/stdc++.h>
// This is intentionally very long to test scrolling
const std::string GREETING = \"UwU\";
int main(int argc, char* argv[]) {
    std::cout << GREETING;
}
\`\`\`

### LaTeX


Inline w/ dollar signs: $\\frac{1}{2} = \\frac{2}{4}$

Inline w/ double dollar signs: $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$

Inline w/ backslash and square brackets \\[\\int_0^\\infty \\frac{1}{x^2} dx = \\infty\\]

Inline w/ backslash and round brackets \\(e^{i\\pi} + 1 = 0\\)
`, Ai.interfaceRole);
            }
        },
    ]

    property bool sending: false

    function startsWithCommand(cmd) {
        return messageInputField.text.startsWith(root.commandPrefix + cmd);
    }

    function insertCommand(text) {
        messageInputField.text = root.commandPrefix + text;
        messageInputField.inputTextArea.cursorPosition = messageInputField.text.length;
        messageInputField.inputTextArea.forceActiveFocus();
    }

    function handleInput(inputText) {
        if (inputText.startsWith(root.commandPrefix)) {
            const command = inputText.split(" ")[0].substring(1);
            const args = inputText.split(" ").slice(1);
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);
            if (commandObj) {
                commandObj.execute(args);
            } else {
                Ai.addMessage(Translation.tr("Unknown command: ") + command, Ai.interfaceRole);
            }
        } else {
            Ai.sendUserMessage(inputText);
        }

        messageListView.positionViewAtEnd();
    }

    function sendCurrentInput() {
        if (root.sending)
            return;
        root.sending = true;
        const inputText = messageInputField.text;
        if (inputText.trim().length === 0) {
            root.sending = false;
            return;
        }
        messageInputField.text = "";
        root.handleInput(inputText);
        root.sending = false;
    }

    function buildSuggestions(commandName, items, displayFn, descriptionFn) {
        root.suggestionQuery = messageInputField.text.split(" ")[1] ?? "";
        const needsPrefix = messageInputField.text.trim().split(" ").length === 1;
        const results = Fuzzy.go(root.suggestionQuery, items.map(item => ({
            name: Fuzzy.prepare(item),
            obj: item
        })), { all: true, key: "name" });
        root.suggestionList = results.map(result => {
            const name = result.target;
            return {
                name: needsPrefix ? root.commandPrefix + commandName + " " + name : name,
                displayName: displayFn(name),
                description: descriptionFn(name)
            };
        });
    }

    Process {
        id: decodeImageAndAttachProc
        property string imageDecodePath: Directories.cliphistDecode
        property string imageDecodeFileName: "image"
        property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`
        function handleEntry(entry: string) {
            imageDecodeFileName = parseInt(entry.match(/^(\d+)\t/)[1]);
            decodeImageAndAttachProc.exec(["bash", "-c", `[ -f ${imageDecodeFilePath} ] || echo '${StringUtils.shellSingleQuoteEscape(entry)}' | ${Cliphist.cliphistBinary} decode > '${imageDecodeFilePath}'`]);
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                Ai.attachFile(imageDecodeFilePath);
            } else {
                console.error("[AiChat] Failed to decode image in clipboard content");
            }
        }
    }

    component StatusItem: MouseArea {
        id: statusItem
        property string icon
        property string statusText
        property string description
        hoverEnabled: true
        implicitHeight: statusItemRowLayout.implicitHeight
        implicitWidth: statusItemRowLayout.implicitWidth

        RowLayout {
            id: statusItemRowLayout
            spacing: 0
            MaterialSymbol {
                text: statusItem.icon
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                text: statusItem.statusText
                color: Appearance.colors.colSubtext
                animateChange: true
            }
        }

        StyledToolTip {
            text: statusItem.description
            extraVisibleCondition: false
            alternativeVisibleCondition: statusItem.containsMouse
        }
    }

    component StatusSeparator: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        radius: implicitWidth / 2
        color: Appearance.colors.colOutlineVariant
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.controlSpacing

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: swipeView.width
                    height: swipeView.height
                    radius: Appearance.rounding.small
                }
            }

            StyledRectangularShadow {
                z: 1
                target: statusBg
                opacity: statusBg.visible && !messageListView.atYBeginning ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
            Rectangle {
                id: statusBg
                z: 2
                visible: Ai.tokenCount.total > 0
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: root.padding
                }
                implicitWidth: statusRowLayout.implicitWidth + 10 * 2
                implicitHeight: Math.max(statusRowLayout.implicitHeight, 38)
                radius: Appearance.rounding.normal - root.padding
                color: messageListView.atYBeginning ? Appearance.colors.colLayer2 : Appearance.colors.colLayer2Base
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                RowLayout {
                    id: statusRowLayout
                    anchors.centerIn: parent
                    spacing: root.controlSpacing

                    StatusSeparator {
                        visible: Ai.tokenCount.total > 0
                    }
                    StatusItem {
                        visible: Ai.tokenCount.total > 0
                        icon: "token"
                        statusText: Ai.tokenCount.total
                        description: Translation.tr("Total token count\nInput: %1\nOutput: %2").arg(Ai.tokenCount.input).arg(Ai.tokenCount.output)
                    }
                }
            }

            ScrollEdgeFade {
                z: 1
                target: messageListView
                vertical: true
            }

            StyledListView { // Message list
                id: messageListView
                z: 0
                anchors.fill: parent
                spacing: root.controlSpacing
                popin: false
                topMargin: statusBg.visible ? (statusBg.implicitHeight + statusBg.anchors.topMargin * 2) : 0

                touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4
                mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4

                add: null

                model: ScriptModel {
                    values: Ai.messageIDs.filter(id => {
                        const message = Ai.messageByID[id];
                        return message?.visibleToUser ?? true;
                    })
                }
                delegate: AiMessage {
                    required property var modelData
                    required property int index
                    messageIndex: index
                    messageData: {
                        Ai.messageByID[modelData];
                    }
                    messageInputField: root.inputField
                }
            }

            ScrollToBottomButton {
                z: 3
                target: messageListView
            }
        }

        DescriptionBox {
            text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
            showArrows: root.suggestionList.length > 1
        }

        FlowButtonGroup {
            id: suggestions
            visible: root.suggestionList.length > 0 && messageInputField.text.length > 0
            property int selectedIndex: 0
            Layout.fillWidth: true
            spacing: root.controlSpacing

            Repeater {
                id: suggestionRepeater
                model: {
                    suggestions.selectedIndex = 0;
                    return root.suggestionList.slice(0, 10);
                }
                delegate: ApiCommandButton {
                    id: commandButton
                    colBackground: suggestions.selectedIndex === index ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                    bounce: false
                    contentItem: StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.displayName ?? modelData.name
                    }

                    onHoveredChanged: {
                        if (commandButton.hovered) {
                            suggestions.selectedIndex = index;
                        }
                    }
                    onClicked: {
                        suggestions.acceptSuggestion(modelData.name);
                    }
                }
            }

            function acceptSuggestion(word) {
                const words = messageInputField.text.trim().split(/\s+/);
                if (words.length > 0) {
                    words[words.length - 1] = word;
                } else {
                    words.push(word);
                }
                const updatedText = words.join(" ") + " ";
                messageInputField.text = updatedText;
                messageInputField.inputTextArea.cursorPosition = messageInputField.text.length;
                messageInputField.inputTextArea.forceActiveFocus();
            }

            function acceptSelectedWord() {
                if (suggestions.selectedIndex >= 0 && suggestions.selectedIndex < suggestionRepeater.count) {
                    const word = root.suggestionList[suggestions.selectedIndex].name;
                    suggestions.acceptSuggestion(word);
                }
            }
        }

        AttachedFileIndicator {
            id: attachedFileIndicator
            visible: Ai.pendingFilePath.length > 0
            Layout.fillWidth: true
            filePath: Ai.pendingFilePath
            onRemove: Ai.attachFile("")
        }

        TextCanvas {
            id: messageInputField
            Layout.fillWidth: true
            maxHeight: root.inputMaxHeight
            placeholderText: Translation.tr('Message the model... "%1" for commands').arg(root.commandPrefix)

            onInputTextChanged: {
                if (messageInputField.text.length === 0) {
                    root.suggestionQuery = "";
                    root.suggestionList = [];
                    return;
                }
                const cmd = root.suggestionCommands.find(c => root.startsWithCommand(c.prefix));
                if (cmd) {
                    root.buildSuggestions(cmd.prefix, cmd.items(), cmd.display, cmd.desc);
                } else if (messageInputField.text.startsWith(root.commandPrefix)) {
                    root.suggestionQuery = messageInputField.text;
                    root.suggestionList = root.allCommands.filter(c => c.name.startsWith(messageInputField.text.substring(1))).map(c => ({
                        name: `${root.commandPrefix}${c.name}`,
                        description: `${c.description}`
                    }));
                }
            }

            onKeyPressed: (event) => {
                if (event.key === Qt.Key_Tab) {
                    suggestions.acceptSelectedWord();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up && suggestions.visible) {
                    suggestions.selectedIndex = Math.max(0, suggestions.selectedIndex - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down && suggestions.visible) {
                    suggestions.selectedIndex = Math.min(root.suggestionList.length - 1, suggestions.selectedIndex + 1);
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        if (messageInputField.inputTextArea)
                            messageInputField.inputTextArea.insert(messageInputField.inputTextArea.cursorPosition, "\n");
                        event.accepted = true;
                    } else {
                        root.sendCurrentInput();
                        event.accepted = true;
                    }
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        messageInputField.text += Quickshell.clipboardText;
                        event.accepted = true;
                        return;
                    }
                    const currentClipboardEntry = Cliphist.entries[0];
                    const cleanCliphistEntry = StringUtils.cleanCliphistEntry(currentClipboardEntry);
                    if (/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(currentClipboardEntry)) {
                        decodeImageAndAttachProc.handleEntry(currentClipboardEntry);
                        event.accepted = true;
                        return;
                    } else if (cleanCliphistEntry.startsWith("file://")) {
                        const fileName = decodeURIComponent(cleanCliphistEntry);
                        Ai.attachFile(fileName);
                        event.accepted = true;
                        return;
                    }
                    event.accepted = false;
                } else if (event.key === Qt.Key_Escape) {
                    if (Ai.pendingFilePath.length > 0) {
                        Ai.attachFile("");
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }
            }
        }

        RowLayout {
            id: commandButtonsRow
            Layout.fillWidth: true
            spacing: root.controlSpacing

            IconButton {
                iconName: "api"
                onClicked: root.insertCommand("model ")
            }

            StatusChip {
                id: keyChip
                icon: Ai.currentModelHasApiKey ? "key" : "key_off"
                text: Ai.currentModelHasApiKey ? Translation.tr("Key set") : Translation.tr("No key")
                visible: Ai.getModel()?.requires_key ?? false
                onClicked: root.insertCommand("key ")
            }

            StatusChip {
                icon: "device_thermostat"
                text: Ai.temperature.toFixed(1)
                scrollable: true
                scrollValue: Ai.temperature
                onScrollUpdated: (value) => Ai.setTemperature(value)
                onClicked: root.insertCommand("temp ")
            }

            StatusChip {
                icon: "service_toolbox"
                text: {
                    const tools = Ai.tools[Ai.getModel()?.api_format]?.[Ai.currentTool];
                    if (tools && tools.length > 0)
                        return Ai.currentTool.charAt(0).toUpperCase() + Ai.currentTool.slice(1);
                    return "None";
                }
                onClicked: root.insertCommand("tool ")
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: root.controlSpacing

                IconButton {
                    labelText: "/"
                    onClicked: root.insertCommand("")
                }

                IconButton {
                    iconName: "delete"
                    onClicked: {
                        root.handleInput(`${root.commandPrefix}clear`);
                        messageInputField.text = "";
                    }
                }
            }
        }
    }
}
