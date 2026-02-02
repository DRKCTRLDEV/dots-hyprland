import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    anchors.fill: parent
    property bool translatorEnabled: Config.options.sidebar.translator.enable
    property bool mouseConfigEnabled: Config.options.sidebar.mouseConfig.enable

    property var tabButtonList: [
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...(root.mouseConfigEnabled ? [{"icon": "mouse", "name": Translation.tr("Mouse")}] : [])
    ]
    property int tabCount: swipeView.count
    
    // Control service active state based on sidebar visibility
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            // Activate/deactivate RivalCfg service when sidebar opens/closes
            if (root.mouseConfigEnabled) {
                RivalCfg.active = GlobalStates.sidebarLeftOpen
            }
        }
    }
    
    // Also set initial state when component is created
    Component.onCompleted: {
        if (root.mouseConfigEnabled && GlobalStates.sidebarLeftOpen) {
            RivalCfg.active = true
        }
    }
    
    // Cleanup when destroyed
    Component.onDestruction: {
        if (root.mouseConfigEnabled) {
            RivalCfg.active = false
        }
    }

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
        }
        spacing: sidebarPadding

        Toolbar {
            visible: tabButtonList.length > 1
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex

                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    ...(root.translatorEnabled ? [translator.createObject()] : []),
                    ...(root.mouseConfigEnabled ? [mouseConfig.createObject()] : []),
                    ...((root.tabButtonList.length === 0 || (!root.translatorEnabled && !root.mouseConfigEnabled)) ? [placeholder.createObject()] : []),
                ]
            }
        }

        Component {
            id: translator
            Translator {}
        }
        Component {
            id: mouseConfig
            MouseConfig {}
        }
        Component {
            id: placeholder
            Item {
                StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Enjoy your empty sidebar...")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}