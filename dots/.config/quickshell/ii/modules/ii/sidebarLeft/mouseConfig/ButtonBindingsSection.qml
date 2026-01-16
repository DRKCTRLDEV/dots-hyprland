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

    property string listeningButton: ""
    // Common button actions for the dropdown
    property var buttonActions: [{
        "value": "disabled",
        "display": Translation.tr("Disabled")
    }, {
        "value": "button1",
        "display": Translation.tr("Left Click")
    }, {
        "value": "button2",
        "display": Translation.tr("Right Click")
    }, {
        "value": "button3",
        "display": Translation.tr("Middle Click")
    }, {
        "value": "button4",
        "display": Translation.tr("Back")
    }, {
        "value": "button5",
        "display": Translation.tr("Forward")
    }, {
        "value": "dpi",
        "display": Translation.tr("DPI Cycle")
    }, {
        "value": "dpi+",
        "display": Translation.tr("DPI Up")
    }, {
        "value": "dpi-",
        "display": Translation.tr("DPI Down")
    }, {
        "value": "space",
        "display": Translation.tr("Space")
    }, {
        "value": "enter",
        "display": Translation.tr("Enter")
    }, {
        "value": "tab",
        "display": Translation.tr("Tab")
    }, {
        "value": "backspace",
        "display": Translation.tr("Backspace")
    }, {
        "value": "delete",
        "display": Translation.tr("Delete")
    }, {
        "value": "F1",
        "display": "F1"
    }, {
        "value": "F2",
        "display": "F2"
    }, {
        "value": "F3",
        "display": "F3"
    }, {
        "value": "F4",
        "display": "F4"
    }, {
        "value": "F5",
        "display": "F5"
    }, {
        "value": "F6",
        "display": "F6"
    }, {
        "value": "F7",
        "display": "F7"
    }, {
        "value": "F8",
        "display": "F8"
    }, {
        "value": "F9",
        "display": "F9"
    }, {
        "value": "F10",
        "display": "F10"
    }, {
        "value": "F11",
        "display": "F11"
    }, {
        "value": "F12",
        "display": "F12"
    }, {
        "value": "super",
        "display": Translation.tr("Super/Win")
    }]

    signal startListening(string button)
    signal stopListening()

    function getActionDisplay(actionValue: string) : string {
        const action = buttonActions.find((a) => {
            return a.value === actionValue;
        });
        if (action)
            return action.display;

        // For custom values (like key letters)
        if (actionValue && actionValue.length === 1)
            return actionValue.toUpperCase() + " " + Translation.tr("key");

        return actionValue || Translation.tr("Unknown");
    }

    function getButtonDisplayName(buttonId: string) : string {
        // Return friendly names
        const names = {
            "button1": Translation.tr("Left Click"),
            "button2": Translation.tr("Right Click"),
            "button3": Translation.tr("Middle Click"),
            "button4": Translation.tr("Back Btn"),
            "button5": Translation.tr("Forward Btn"),
            "button6": Translation.tr("DPI Button"),
            "button7": Translation.tr("Button 7"),
            "button8": Translation.tr("Button 8"),
            "button9": Translation.tr("Button 9")
        };
        return names[buttonId] || buttonId;
    }

    function getButtonIcon(buttonId: string) : string {
        const icons = {
            "button1": "mouse",
            "button2": "mouse",
            "button3": "mouse",
            "button4": "arrow_back",
            "button5": "arrow_forward",
            "button6": "speed",
            "button7": "radio_button_unchecked",
            "button8": "radio_button_unchecked",
            "button9": "radio_button_unchecked"
        };
        return icons[buttonId] || "radio_button_unchecked";
    }

    implicitHeight: bindingsColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    Accessible.role: Accessible.Pane
    Accessible.name: Translation.tr("Button Bindings")
    Accessible.description: Translation.tr("Configure mouse button actions")

    ColumnLayout {
        id: bindingsColumn

        spacing: 12

        anchors {
            fill: parent
            margins: 12
        }

        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: "touch_app"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Button Bindings")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
            }

            // Info tooltip (non-clickable)
            Item {
                implicitWidth: 24
                implicitHeight: 24

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "help_outline"
                    iconSize: Appearance.font.pixelSize.normal
                    color: bindingsHelpHover.hovered ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                HoverHandler {
                    id: bindingsHelpHover
                }

                StyledToolTip {
                    visible: bindingsHelpHover.hovered
                    text: Translation.tr("Customize what each mouse button does.\n\nClick the record button to capture a key press,\nor use the dropdown to select from common actions.\n\nSet to 'Disabled' to deactivate a button.")
                }
            }

        }

        // Button bindings list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: RivalCfg.availableButtons

                delegate: ButtonBindingRow {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    buttonId: modelData
                    buttonName: root.getButtonDisplayName(modelData)
                    buttonIcon: root.getButtonIcon(modelData)
                    currentAction: RivalCfg.buttonBindings[modelData] || "disabled"
                    actionDisplay: root.getActionDisplay(currentAction)
                    isListening: root.listeningButton === modelData
                    availableActions: root.buttonActions
                    onStartListeningClicked: {
                        root.startListening(modelData);
                    }
                    onActionSelected: (action) => {
                        RivalCfg.setButtonBinding(modelData, action);
                    }
                }

            }

        }

    }

    // Individual button binding row component
    component ButtonBindingRow: Rectangle {
        id: bindingRow

        property string buttonId: ""
        property string buttonName: ""
        property string buttonIcon: ""
        property string currentAction: ""
        property string actionDisplay: ""
        property bool isListening: false
        property var availableActions: []

        signal startListeningClicked()
        signal actionSelected(string action)

        implicitHeight: bindingRowLayout.implicitHeight + 12
        radius: Appearance.rounding.small
        color: isListening ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
        Accessible.role: Accessible.ListItem
        Accessible.name: Translation.tr("%1: %2").arg(bindingRow.buttonName).arg(bindingRow.actionDisplay)

        RowLayout {
            id: bindingRowLayout

            spacing: 8

            anchors {
                fill: parent
                margins: 6
            }

            // Button icon
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: Appearance.rounding.small
                color: bindingRow.isListening ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colLayer2

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: bindingRow.buttonIcon
                    iconSize: Appearance.font.pixelSize.normal
                    color: bindingRow.isListening ? Appearance.colors.colPrimaryContainer : Appearance.colors.colOnLayer2
                }

            }

            // Button name
            StyledText {
                Layout.preferredWidth: 80
                text: bindingRow.buttonName
                color: bindingRow.isListening ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
            }

            // Current action / dropdown
            StyledComboBox {
                id: actionCombo

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                buttonRadius: Appearance.rounding.small
                enabled: !bindingRow.isListening
                opacity: enabled ? 1 : 0.5
                model: bindingRow.availableActions
                textRole: "display"
                valueRole: "value"
                currentIndex: {
                    const idx = model.findIndex((item) => {
                        return item.value === bindingRow.currentAction;
                    });
                    return idx >= 0 ? idx : 0;
                }
                onActivated: (index) => {
                    const newAction = model[index].value;
                    if (newAction !== bindingRow.currentAction)
                        bindingRow.actionSelected(newAction);

                }
                Accessible.role: Accessible.ComboBox
                Accessible.name: Translation.tr("Action for %1").arg(bindingRow.buttonName)
            }

            // Record key button
            GroupButton {
                id: recordButton

                baseWidth: 32
                baseHeight: 32
                bounce: false
                buttonRadius: Appearance.rounding.small
                colBackground: bindingRow.isListening ? Appearance.colors.colError : Appearance.colors.colSecondaryContainer
                onClicked: {
                    if (bindingRow.isListening)
                        root.stopListening();
                    else
                        bindingRow.startListeningClicked();
                }
                Accessible.role: Accessible.Button
                Accessible.name: bindingRow.isListening ? Translation.tr("Stop recording") : Translation.tr("Record key for %1").arg(bindingRow.buttonName)

                StyledToolTip {
                    text: bindingRow.isListening ? Translation.tr("Click to cancel recording") : Translation.tr("Click to record a key press")
                }

                contentItem: Item {
                    implicitWidth: recordIcon.implicitWidth
                    implicitHeight: recordIcon.implicitHeight

                    MaterialSymbol {
                        id: recordIcon
                        anchors.centerIn: parent
                        text: bindingRow.isListening ? "stop" : "fiber_manual_record"
                        iconSize: Appearance.font.pixelSize.normal
                        color: bindingRow.isListening ? Appearance.colors.colOnError : Appearance.colors.colOnSecondaryContainer
                        fill: bindingRow.isListening ? 1 : 0

                        // Pulse animation when listening
                        SequentialAnimation on opacity {
                            running: bindingRow.isListening
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

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

    }

}
