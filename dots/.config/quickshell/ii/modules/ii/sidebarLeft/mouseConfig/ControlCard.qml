pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.mouseConfig
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2
    implicitHeight: settingsCol.implicitHeight + 24

    property string listeningButton: ""
    property int maxDpi: Config.options.sidebar.mouseConfig.maxDpi
    property var editablePresets: RivalCfg.sensitivityPresets && RivalCfg.sensitivityPresets.length > 0 ? RivalCfg.sensitivityPresets.slice() : [800,1600,3200]
    property int selectedIndex: 0

    signal startListening(string button)
    signal stopListening

    Connections {
        target: RivalCfg
        function onSensitivityPresetsChanged() {
            var np = RivalCfg.sensitivityPresets.slice()
            var cur = editablePresets[selectedIndex]
            editablePresets = np
            selectedIndex = cur !== undefined ? Math.max(0, np.indexOf(cur)) : Math.min(selectedIndex, np.length - 1)
        }
    }

    Timer {
        id: debounce
        interval: 350 // Update after 350ms of inactivity
        onTriggered: {
            var roundedValue = Math.round(dpiSlider.value)
            if (editablePresets[selectedIndex] !== roundedValue) {
                editablePresets[selectedIndex] = roundedValue
                editablePresets = editablePresets
                RivalCfg.setSensitivity(editablePresets)
            }
        }
    }

    ColumnLayout {
        id: settingsCol
        anchors.fill: parent
        anchors.margins: 12

        // DPI Section
        StyledSlider {
            id: dpiSlider
            configuration: StyledSlider.Configuration.M
            from: 100; to: root.maxDpi; stepSize: 50
            value: editablePresets[selectedIndex] !== undefined ? editablePresets[selectedIndex] : 800
            tooltipContent: Math.round(value) + " DPI"
            onMoved: debounce.restart()
            onPressedChanged: if (!pressed && debounce.running) { debounce.stop(); debounce.triggered() }
        }

        Flickable {
            Layout.fillWidth: true
            implicitHeight: presetRow.implicitHeight
            contentWidth: presetRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: presetRow
                spacing: 4
                Repeater {
                    model: editablePresets
                    delegate: PresetChip {
                        required property var modelData
                        required property int index
                        dpiValue: modelData
                        presetIndex: index
                        isSelected: root.selectedIndex === index
                        leftmost: index === 0
                        rightmost: index === editablePresets.length - 1
                        onPresetSelected: function(idx) {
                            root.selectedIndex = idx
                        }
                        onPresetRemoveRequested: function(idx) {
                            if (editablePresets.length <= 1) return // omit last preset
                            var np = editablePresets.slice()
                            np.splice(idx, 1)
                            editablePresets = np
                            if (root.selectedIndex >= idx && root.selectedIndex > 0) {
                                root.selectedIndex--
                            }
                            RivalCfg.setSensitivity(np)
                        }
                    }
                }
                PresetChip {
                    isAddButton: true
                    canAdd: editablePresets.length < 5
                    onAddRequested: {
                        var last = editablePresets[editablePresets.length - 1] || 800
                        var nv = Math.min(last + 400, root.maxDpi)
                        while (editablePresets.includes(nv) && nv < root.maxDpi) nv += 50
                        if (editablePresets.includes(nv)) {
                            nv = Math.max(100, last - 400)
                            while (editablePresets.includes(nv) && nv > 100) nv -= 50
                        }
                        if (editablePresets.includes(nv)) return
                        var np = editablePresets.slice()
                        np.push(nv)
                        np.sort((a,b)=>a-b)
                        editablePresets = np
                        root.selectedIndex = np.indexOf(nv)
                        RivalCfg.setSensitivity(np)
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.margins: 6; implicitHeight: 1; color: Appearance.colors.colLayer3 }

        // Bind Section
        ColumnLayout {
            spacing: 6

            Repeater {
                model: RivalCfg.availableButtons
                delegate: ButtonBindingRow {
                    required property string modelData
                    buttonId: modelData
                    buttonName: KeyLib.getButtonDisplayName(modelData)
                    currentAction: RivalCfg.buttonBindings[modelData] || KeyLib.getDefaultAction(modelData)
                    actionDisplay: KeyLib.getActionDisplay(currentAction)
                    isListening: root.listeningButton === modelData
                    availableActions: KeyLib.getAvailableActionsForButton(modelData, currentAction)
                    onStartListeningClicked: root.startListening(modelData)
                    onActionSelected: function(a) { RivalCfg.setButtonBinding(modelData, a) }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.margins: 6; implicitHeight: 1; color: Appearance.colors.colLayer3 }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                implicitHeight: 36
                materialIcon: "restart_alt"
                mainText: "Reset to Defaults"
                colBackground: Appearance.colors.colSecondaryContainer
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                onClicked: RivalCfg.resetToDefaults()
            }
        }
    }

    component ButtonBindingRow: RowLayout {
        property string buttonId: ""
        property string buttonName: ""
        property string currentAction: ""
        property string actionDisplay: ""
        property bool isListening: false
        property var availableActions: []
        signal startListeningClicked
        signal actionSelected(string action)
        spacing: 6
        StyledComboBox {
            implicitHeight: 36
            buttonRadius: Appearance.rounding.small
            enabled: !isListening
            model: availableActions
            textRole: "displayText"
            valueRole: "value"
            currentIndex: { var idx = model.findIndex(function(i) { return i.value === currentAction }); return idx !== -1 ? idx : 0 }
            onActivated: function(idx) { var a = model[idx].value; if (a !== currentAction) actionSelected(a) }
        }
        GroupButton {
            baseWidth: 36; baseHeight: 36
            colBackground: isListening ? Appearance.colors.colError : Appearance.colors.colSecondaryContainer
            colBackgroundHover: isListening ? Appearance.colors.colErrorContainerHover : Appearance.colors.colSecondaryContainerHover
            colBackgroundActive: isListening ? Appearance.colors.colErrorContainerActive : Appearance.colors.colSecondaryContainerActive
            contentItem: MaterialSymbol {
                text: isListening ? "stop" : "fiber_manual_record"
                color: isListening ? Appearance.colors.colOnError : Appearance.colors.colOnSecondaryContainer
                iconSize: Appearance.font.pixelSize.larger
                fill: isListening ? 1 : 0
            }
            onClicked: isListening ? root.stopListening() : startListeningClicked()
        }
    }
}