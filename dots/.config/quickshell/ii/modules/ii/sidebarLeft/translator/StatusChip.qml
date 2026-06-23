import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string icon: "api"
    property string text: ""
    property string tooltipText: ""
    property bool scrollable: false
    property real scrollValue: 0

    signal scrollUpdated(real value)
    signal clicked()

    radius: Appearance.rounding.small
    color: root.pressed ? Appearance.colors.colLayer2Active : (root.hovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
    implicitHeight: 36
    implicitWidth: indicator.implicitWidth + 10
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    property real pendingScrollValue: root.scrollValue
    Timer {
        id: debounce
        interval: 150
        repeat: false
        onTriggered: root.scrollUpdated(root.pendingScrollValue)
    }

    property string displayText: debounce.running ? root.pendingScrollValue.toFixed(1) : root.text

    // Track hover state for visual feedback
    property bool hovered: false
    property bool pressed: false

    ApiInputBoxIndicator {
        id: indicator
        anchors.centerIn: parent
        icon: root.icon
        text: root.displayText
        tooltipText: root.tooltipText
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onEntered: root.hovered = true
        onExited: { root.hovered = false; root.pressed = false; }
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onClicked: root.clicked()
        onWheel: (wheel) => {
            if (root.scrollable) {
                const delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1;
                root.pendingScrollValue = Math.max(0, Math.min(2, Math.round((root.pendingScrollValue + delta) * 10) / 10));
                debounce.restart();
            }
        }
    }
}
