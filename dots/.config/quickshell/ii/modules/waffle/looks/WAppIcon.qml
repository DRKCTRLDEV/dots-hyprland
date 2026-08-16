import QtQuick
import Quickshell
import Quickshell.Io
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common

Kirigami.Icon {
    id: root
    required property string iconName
    property bool separateLightDark: false
    property bool tryCustomIcon: true
    property alias monochrome: root.isMask

    property real implicitSize: 26
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    animated: true
    roundToIconSize: false
    readonly property string placeholderIconPath: `${Looks.iconsPath}/image-missing.svg`
    readonly property string themeIconName: AppSearch.iconExists(root.iconName) ? root.iconName : ""
    readonly property string customIconPath: tryCustomIcon ? `${Looks.iconsPath}/${root.iconName}${!root.separateLightDark ? "" : Looks.dark ? "-dark" : "-light"}.svg` : ""
    property string effectiveSource: root.themeIconName !== "" ? root.themeIconName : root.placeholderIconPath
    fallback: root.placeholderIconPath
    source: effectiveSource

    FileView {
        id: iconProbe
        path: root.customIconPath
        printErrors: false
        onLoaded: root.effectiveSource = iconProbe.path
    }

    color: Looks.colors.fg
}
