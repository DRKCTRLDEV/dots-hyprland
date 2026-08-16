import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import org.kde.kirigami as Kirigami
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

RowLayout {
    id: root
    required property PwNode node
    property string icon: ""
    property bool monochrome: false

    readonly property string fluentGlyphPath: root.icon === "" ? "" : `${Looks.iconsPath}/${root.icon}.svg`
    readonly property string appIconSource: {
        let icon;
        icon = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
        if (AppSearch.iconExists(icon))
            return icon;
        icon = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
        return AppSearch.iconExists(icon) ? icon : "";
    }

    PwObjectTracker { // Necessary for useful info to be present in 'node'
        objects: [root.node]
    }

    WButton {
        id: iconButton
        implicitWidth: 40
        implicitHeight: 40
        onClicked: root.node.audio.muted = !root.node?.audio.muted

        contentItem: Item {
            Kirigami.Icon {
                id: iconContent
                anchors.centerIn: parent
                implicitWidth: 18
                implicitHeight: 18
                source: root.fluentGlyphPath !== "" ? root.fluentGlyphPath : (root.appIconSource !== "" ? root.appIconSource : `${Looks.iconsPath}/apps.svg`)
                fallback: `${Looks.iconsPath}/apps.svg`
                roundToIconSize: false
                isMask: root.monochrome || root.fluentGlyphPath !== ""
                color: Looks.colors.fg
            }
        }

        FluentIcon {
            id: muteIcon
            visible: root.node?.audio.muted ?? false
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: -1
            }
            implicitSize: 16
            icon: "speaker-mute"
        }

        WToolTip {
            extraVisibleCondition: iconButton.shouldShowTooltip
            text: Audio.appNodeDisplayName(root.node)
        }
    }

    WSlider {
        Layout.fillWidth: true
        Layout.rightMargin: 10
        value: root.node?.audio.volume ?? 0
        onMoved: root.node.audio.volume = value
    }
}
