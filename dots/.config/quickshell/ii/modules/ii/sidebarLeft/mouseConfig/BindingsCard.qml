pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * Button bindings configuration section.
 * Allows editing mouse button assignments.
 */
Rectangle {
    id: root
    implicitHeight: bindingsColumn.implicitHeight + 24
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2
    Layout.fillWidth: true

    property string listeningButton: ""
    // Common button actions for the dropdown
    property var buttonActions: [
        {
            "value": "disabled",
            "displayText": Translation.tr("Disabled")
        },
        {
            "value": "button1",
            "displayText": Translation.tr("Left Click (Button 1)")
        },
        {
            "value": "button2",
            "displayText": Translation.tr("Right Click (Button 2)")
        },
        {
            "value": "button3",
            "displayText": Translation.tr("Middle Click")
        },
        {
            "value": "button4",
            "displayText": Translation.tr("Back (Button 4)")
        },
        {
            "value": "button5",
            "displayText": Translation.tr("Forward (Button 5)")
        },
        {
            "value": "button6",
            "displayText": Translation.tr("Button 6")
        },
        {
            "value": "button7",
            "displayText": Translation.tr("Button 7")
        },
        {
            "value": "button8",
            "displayText": Translation.tr("Button 8")
        },
        {
            "value": "button9",
            "displayText": Translation.tr("Button 9")
        },
        {
            "value": "dpi",
            "displayText": Translation.tr("DPI Cycle")
        },
        {
            "value": "scrollup",
            "displayText": Translation.tr("Scroll Up")
        },
        {
            "value": "scrolldown",
            "displayText": Translation.tr("Scroll Down")
        },
        {
            "value": "LeftSuper",
            "displayText": Translation.tr("Super/Win Key")
        },
        {
            "value": "Ctrl",
            "displayText": Translation.tr("Ctrl")
        },
        {
            "value": "Shift",
            "displayText": Translation.tr("Shift")
        },
        {
            "value": "Alt",
            "displayText": Translation.tr("Alt")
        },
        {
            "value": "ContextMenu",
            "displayText": Translation.tr("Context Menu")
        },
        {
            "value": "PlayPause",
            "displayText": Translation.tr("Play/Pause")
        },
        {
            "value": "VolumeUp",
            "displayText": Translation.tr("Volume Up")
        },
        {
            "value": "VolumeDown",
            "displayText": Translation.tr("Volume Down")
        },
        {
            "value": "Mute",
            "displayText": Translation.tr("Mute")
        },
        {
            "value": "Next",
            "displayText": Translation.tr("Next Track")
        },
        {
            "value": "Previous",
            "displayText": Translation.tr("Previous Track")
        }
    ]

    signal startListening(string button)
    signal stopListening

    function getActionDisplay(actionValue: string): string {
        const action = buttonActions.find(a => {
            return a.value === actionValue;
        });
        if (action)
            return action.displayText;

        // For custom values (like key letters)
        if (actionValue && actionValue.length === 1 && /^[A-Z0-9]$/.test(actionValue))
            return actionValue.toUpperCase() + " " + Translation.tr("key");

        // For modifier keys - use generic names since Qt/Wayland can't reliably distinguish left/right
        const modifierNames = {
            "Shift": Translation.tr("Shift"),
            "LeftShift": Translation.tr("Shift"),
            "RightShift": Translation.tr("Shift"),
            "Ctrl": Translation.tr("Ctrl"),
            "LeftCtrl": Translation.tr("Ctrl"),
            "RightCtrl": Translation.tr("Ctrl"),
            "Alt": Translation.tr("Alt"),
            "LeftAlt": Translation.tr("Alt"),
            "RightAlt": Translation.tr("Alt (Right)"),
            "LeftSuper": Translation.tr("Super/Win"),
            "RightSuper": Translation.tr("Super/Win")
        };
        if (modifierNames[actionValue])
            return modifierNames[actionValue];

        // For special keys and aliases
        const specialKeys = {
            "Escape": Translation.tr("Escape"),
            "Space": Translation.tr("Space"),
            "Enter": Translation.tr("Enter"),
            "Tab": Translation.tr("Tab"),
            "BackSpace": Translation.tr("Backspace"),
            "Delete": Translation.tr("Delete"),
            "Insert": Translation.tr("Insert"),
            "Home": Translation.tr("Home"),
            "End": Translation.tr("End"),
            "PageUp": Translation.tr("Page Up"),
            "PageDown": Translation.tr("Page Down"),
            "Up": Translation.tr("Arrow Up"),
            "Down": Translation.tr("Arrow Down"),
            "Left": Translation.tr("Arrow Left"),
            "Right": Translation.tr("Arrow Right"),
            "ContextMenu": Translation.tr("Context Menu"),
            "PrintScreen": Translation.tr("Print Screen"),
            "PauseBreak": Translation.tr("Pause/Break"),
            "ScrollLock": Translation.tr("Scroll Lock"),
            "NumLock": Translation.tr("Num Lock"),
            "quote": "'",
            "comma": ",",
            "dash": "-",
            "dot": ".",
            "slash": "/",
            "semicolon": ";",
            "equal": "=",
            "leftbracket": "[",
            "backslash": "\\\\",
            "rightbracket": "]",
            "backtick": "`",
            "hash": "#",
            // Media keys (use rivalcfg names)
            "PlayPause": Translation.tr("Play/Pause"),
            "VolumeUp": Translation.tr("Volume Up"),
            "VolumeDown": Translation.tr("Volume Down"),
            "Mute": Translation.tr("Mute"),
            "Next": Translation.tr("Next Track"),
            "Previous": Translation.tr("Previous Track"),
            // Scroll actions
            "scrollup": Translation.tr("Scroll Up"),
            "scrolldown": Translation.tr("Scroll Down")
        };
        if (specialKeys[actionValue])
            return specialKeys[actionValue] + (specialKeys[actionValue].length === 1 ? " " + Translation.tr("key") : "");

        // F-keys
        if (/^F\d+$/.test(actionValue))
            return actionValue + " " + Translation.tr("key");

        return actionValue || Translation.tr("Unknown");
    }

    function getButtonDisplayName(buttonId: string): string {
        // Return friendly names with button numbers - handle both "Button1" and "button1" formats
        const id = buttonId.toLowerCase();
        const names = {
            "button1": Translation.tr("Left Click (Button 1)"),
            "button2": Translation.tr("Right Click (Button 2)"),
            "button3": Translation.tr("Middle Click (Button 3)"),
            "button4": Translation.tr("Back (Button 4)"),
            "button5": Translation.tr("Forward (Button 5)"),
            "button6": Translation.tr("DPI (Button 6)"),
            "button7": Translation.tr("Button 7"),
            "button8": Translation.tr("Button 8"),
            "button9": Translation.tr("Button 9")
        };
        return names[id] || buttonId;
    }

    function getDefaultAction(buttonId: string): string {
        const id = buttonId.toLowerCase();
        const defaults = {
            "button1": "button1" // LMB
            ,
            "button2": "button2" // RMB
            ,
            "button3": "button3" // MMB
            ,
            "button4": "button4" // Back
            ,
            "button5": "button5" // Forward
            ,
            "button6": "dpi"      // DPI Cycle
        };
        return defaults[id] || id;
    }

    function getAvailableActionsForButton(buttonId: string, currentAction: string): var {
        let actions = buttonActions.slice();
        const id = buttonId.toLowerCase();
        // Check if buttonId is already in actions
        const hasButtonAction = actions.some(action => action.value === id);
        if (!hasButtonAction && id !== "button6") {
            // Add the button itself as an option (default behavior)
            const buttonNumber = id.replace("button", "");
            actions.push({
                "value": id,
                "displayText": Translation.tr("Default (Button %1)").arg(buttonNumber)
            });
        }
        // Check if currentAction is in actions
        const hasCurrentAction = actions.some(action => action.value === currentAction);
        if (!hasCurrentAction && currentAction && currentAction !== "disabled") {
            // Add the current action as an option
            actions.push({
                "value": currentAction,
                "displayText": root.getActionDisplay(currentAction)
            });
        }
        return actions;
    }

    ColumnLayout {
        id: bindingsColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Repeater {
            model: RivalCfg.availableButtons

            delegate: ButtonBindingRow {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                buttonId: modelData
                buttonName: root.getButtonDisplayName(modelData)
                currentAction: RivalCfg.buttonBindings[modelData] || root.getDefaultAction(modelData)
                actionDisplay: root.getActionDisplay(currentAction)
                isListening: root.listeningButton === modelData
                availableActions: root.getAvailableActionsForButton(modelData, currentAction)
                onStartListeningClicked: root.startListening(modelData)
                onActionSelected: action => RivalCfg.setButtonBinding(modelData, action)
            }
        }

        RippleButtonWithIcon {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            materialIcon: "restart_alt"
            mainText: Translation.tr("Reset to Defaults")
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colErrorContainerHover
            buttonRadius: Appearance.rounding.small
            onClicked: {
                RivalCfg.resetToDefaults();
            }
        }
    }

    component ButtonBindingRow: RowLayout {
        id: bindingRow
        property string buttonId: ""
        property string buttonName: ""
        property string currentAction: ""
        property string actionDisplay: ""
        property bool isListening: false
        property var availableActions: []

        signal startListeningClicked
        signal actionSelected(string action)

        implicitHeight: comboBox.implicitHeight + 12
        spacing: 8

        StyledComboBox {
            id: comboBox
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            buttonRadius: Appearance.rounding.small
            enabled: !isListening
            opacity: enabled ? 1 : 0.5
            model: availableActions
            textRole: "displayText"
            valueRole: "value"
            currentIndex: {
                const idx = model.findIndex(item => item.value === currentAction);
                return idx >= 0 ? idx : 0;
            }
            onActivated: index => {
                const newAction = model[index].value;
                if (newAction !== currentAction)
                    actionSelected(newAction);
            }
        }

        RippleButtonWithIcon {
            implicitWidth: 36
            implicitHeight: 36
            buttonRadius: Appearance.rounding.small
            colBackground: isListening ? Appearance.colors.colError : Appearance.colors.colSecondaryContainer
            colBackgroundHover: isListening ? Appearance.colors.colErrorContainerHover : Appearance.colors.colSecondaryContainerHover

            onClicked: {
                if (isListening)
                    root.stopListening();
                else
                    startListeningClicked();
            }

            StyledToolTip {
                text: isListening ? Translation.tr("Cancel recording") : Translation.tr("Record key press")
            }

            contentItem: Item {
                anchors.fill: parent
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: isListening ? "stop" : "fiber_manual_record"
                    iconSize: Appearance.font.pixelSize.large
                    color: isListening ? Appearance.colors.colOnError : Appearance.colors.colOnSecondaryContainer
                    fill: isListening ? 1 : 0

                    SequentialAnimation on opacity {
                        running: isListening
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.5
                            duration: 400
                        }
                        NumberAnimation {
                            to: 1
                            duration: 400
                        }
                    }
                }
            }

            Behavior on colBackground {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
