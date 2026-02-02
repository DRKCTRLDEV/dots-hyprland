import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * DPI/Sensitivity configuration section with slider and preset management.
 */
Rectangle {
    id: root
    
    property int maxDpi: Config.options.sidebar.mouseConfig.maxDpi
    property var editablePresets: RivalCfg.sensitivityPresets.slice()
    property int selectedPresetIndex: 0
    property bool isEditing: false
    
    implicitHeight: dpiColumn.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    
    // Sync with service when it changes
    Connections {
        target: RivalCfg
        function onSensitivityPresetsChanged() {
            root.editablePresets = RivalCfg.sensitivityPresets.slice()
        }
    }
    
    ColumnLayout {
        id: dpiColumn
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 12
        
        // Section header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            MaterialSymbol {
                text: "speed"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer2
            }
            
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("DPI / Sensitivity")
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
                    color: helpHover.hovered ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }

                HoverHandler {
                    id: helpHover
                }

                StyledToolTip {
                    visible: helpHover.hovered
                    text: Translation.tr("DPI (Dots Per Inch) controls mouse sensitivity.\nHigher DPI = faster cursor movement.\nYou can have multiple presets and cycle through them using the DPI button on your mouse.")
                }
            }
        }
        
        // DPI Slider for selected preset
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                
                StyledText {
                    text: Translation.tr("Adjust preset %1:").arg(root.selectedPresetIndex + 1)
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
                
                Item { Layout.fillWidth: true }
                
                StyledText {
                    text: root.editablePresets[root.selectedPresetIndex]?.toString() || "---"
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    font.family: Appearance.font.family.numbers
                }
                
                StyledText {
                    text: " DPI"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
            
            StyledSlider {
                id: dpiSlider
                Layout.fillWidth: true
                configuration: StyledSlider.Configuration.M
                from: 100
                to: root.maxDpi
                stepSize: 50
                value: root.editablePresets[root.selectedPresetIndex] || 800
                stopIndicatorValues: []
                usePercentTooltip: false
                tooltipContent: Math.round(value) + " DPI"
                
                onMoved: {
                    let newPresets = root.editablePresets.slice()
                    newPresets[root.selectedPresetIndex] = Math.round(value)
                    root.editablePresets = newPresets
                }
                
                onPressedChanged: {
                    if (!pressed) {
                        // Apply when user releases slider
                        RivalCfg.setSensitivity(root.editablePresets)
                    }
                }
                
                Accessible.role: Accessible.Slider
                Accessible.name: Translation.tr("DPI Slider")
                Accessible.description: Translation.tr("Adjust DPI value for selected preset")
            }
        }
        
        // DPI Preset buttons - horizontally scrollable
        Flickable {
            Layout.fillWidth: true
            implicitHeight: presetRow.implicitHeight
            contentWidth: presetRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            Row {
                id: presetRow
                spacing: 6
                
                Repeater {
                    model: root.editablePresets
                    
                    delegate: DpiPresetChip {
                        required property int index
                        required property var modelData
                        
                        property var parentRoot: root
                        
                        dpiValue: modelData
                        isSelected: parentRoot.selectedPresetIndex === index
                        canRemove: parentRoot.editablePresets.length > 1
                        
                        onClicked: {
                            parentRoot.selectedPresetIndex = index
                        }
                        
                        onRemoveClicked: {
                            if (parentRoot.editablePresets && parentRoot.editablePresets.length > 1) {
                                let newPresets = parentRoot.editablePresets.slice()
                                newPresets.splice(index, 1)
                                parentRoot.editablePresets = newPresets
                                // Adjust selected preset index
                                if (parentRoot.selectedPresetIndex >= index) {
                                    parentRoot.selectedPresetIndex = Math.max(0, parentRoot.selectedPresetIndex - 1)
                                }
                                RivalCfg.setSensitivity(newPresets)
                            }
                        }
                    }
                }
                
                // Add preset button
                GroupButton {
                    id: addPresetBtn
                    baseWidth: 36
                    baseHeight: 32
                    bounce: false
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimaryContainer
                    enabled: root.editablePresets.length < 5
                    opacity: enabled ? 1 : 0.4

                    contentItem: Item {
                        implicitWidth: addIcon.implicitWidth
                        implicitHeight: addIcon.implicitHeight

                        MaterialSymbol {
                            id: addIcon
                            anchors.centerIn: parent
                            text: "add"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    onClicked: {
                        // Add a new preset with a reasonable default, avoiding duplicates
                        const lastValue = root.editablePresets[root.editablePresets.length - 1] || 800
                        let newValue = Math.min(lastValue + 400, root.maxDpi)
                        
                        // Find unique value if this one already exists
                        while (root.editablePresets.includes(newValue) && newValue < root.maxDpi) {
                            newValue += 50
                        }
                        if (root.editablePresets.includes(newValue)) {
                            // Try going down instead
                            newValue = Math.max(100, lastValue - 400)
                            while (root.editablePresets.includes(newValue) && newValue > 100) {
                                newValue -= 50
                            }
                        }
                        if (root.editablePresets.includes(newValue)) return // Can't add unique preset
                        
                        let newPresets = root.editablePresets.slice()
                        newPresets.push(newValue)
                        newPresets.sort((a, b) => a - b)
                        root.editablePresets = newPresets
                        root.selectedPresetIndex = newPresets.indexOf(newValue)
                        RivalCfg.setSensitivity(newPresets)
                    }
                    
                    StyledToolTip {
                        text: root.editablePresets.length >= 5 
                            ? Translation.tr("Maximum 5 presets allowed")
                            : Translation.tr("Add new DPI preset")
                    }
                    
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Add DPI preset")
                }
            }
        }
    }
    
    // DPI Preset Chip component
    component DpiPresetChip: Rectangle {
        id: chip
        property int dpiValue: 800
        property bool isSelected: false
        property bool canRemove: true
        property bool showRemoveButton: canRemove && (chipMouseArea.containsMouse || removeButtonMouseArea.containsMouse || isSelected)
        
        signal clicked()
        signal removeClicked()
        
        implicitWidth: chipContent.implicitWidth + 16
        implicitHeight: 32
        radius: Appearance.rounding.full
        color: isSelected ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
        
        Behavior on implicitWidth {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        
        Row {
            id: chipContent
            anchors.centerIn: parent
            spacing: 4
            
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.dpiValue.toString()
                color: chip.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.numbers
                font.weight: chip.isSelected ? Font.Medium : Font.Normal
                
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
            
            // Remove button (smoothly shown on hover)
            Item {
                id: removeButtonContainer
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: chip.showRemoveButton ? 18 : 0
                implicitHeight: 18
                clip: true
                visible: chip.canRemove
                
                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
                
                Rectangle {
                    id: removeButtonBg
                    width: 18
                    height: 18
                    color: "transparent"
                    opacity: chip.showRemoveButton ? 1 : 0
                    
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Appearance.font.pixelSize.small
                        color: chip.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
        }
        
        // Remove button MouseArea - separate from chip MouseArea for proper click handling
        MouseArea {
            id: removeButtonMouseArea
            x: chip.width - removeButtonContainer.width - 8
            anchors.verticalCenter: parent.verticalCenter
            width: removeButtonContainer.width
            height: removeButtonContainer.height
            visible: chip.showRemoveButton
            enabled: chip.showRemoveButton
            cursorShape: Qt.PointingHandCursor
            z: 10
            hoverEnabled: true
            onClicked: {
                chip.removeClicked()
            }
        }
        
        MouseArea {
            id: chipMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 0
            onClicked: {
                chip.clicked()
            }
            // Make sure this MouseArea doesn't interfere with the remove button
            propagateComposedEvents: true
        }
        
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("%1 DPI preset").arg(dpiValue)
        Accessible.description: isSelected 
            ? Translation.tr("Currently selected preset")
            : Translation.tr("Click to select this preset")
    }
    
    Accessible.role: Accessible.Pane
    Accessible.name: Translation.tr("DPI Settings")
    Accessible.description: Translation.tr("Configure mouse sensitivity presets")
}
