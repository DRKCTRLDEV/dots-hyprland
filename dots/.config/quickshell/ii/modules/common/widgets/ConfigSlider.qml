import qs.modules.common.widgets
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

RowLayout {
    id: root
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    property string text: ""
    property string buttonIcon: ""
    property alias value: slider.value
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: slider.from
    property real to: slider.to
    property real textWidth: 120
    property string configPath: ""
    property real stepSize: 1
    property int snapMode: Slider.SnapOnRelease

    function snapToStep(v) {
        return root.stepSize > 0 ? Math.round(v / root.stepSize) * root.stepSize : v;
    }

    Component.onCompleted: {
        if (root.configPath.length > 0) {
            root.value = root.snapToStep(ConfigPathUtils.getValue(root.configPath, root.value));
        }
    }

    RowLayout {
        id: row
        spacing: 10

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.preferredWidth: root.textWidth
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    StyledSlider {
        id: slider
        configuration: StyledSlider.Configuration.XS
        usePercentTooltip: root.usePercentTooltip
        value: root.value
        from: root.from
        to: root.to
        stepSize: root.stepSize
        snapMode: root.snapMode
        onMoved: {
            if (root.configPath.length > 0) {
                ConfigPathUtils.setValue(root.configPath, root.snapToStep(root.value));
            }
        }
    }
}
