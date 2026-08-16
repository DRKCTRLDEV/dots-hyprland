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
    // Resolve theme icons to a file path rather than passing a bare icon name:
    // AppSearch/Quickshell look up icons via QIcon, but Kirigami.Icon looks them
    // up through KIconLoader, which can fail (and warn) for the same name.
    readonly property string themeIconPath: AppSearch.iconExists(root.iconName) ? Quickshell.iconPath(root.iconName, true) : ""
    readonly property string customIconPath: tryCustomIcon ? `${Looks.iconsPath}/${root.iconName}${!root.separateLightDark ? "" : Looks.dark ? "-dark" : "-light"}.svg` : ""
    property string effectiveSource: root.themeIconPath !== "" ? root.themeIconPath : root.placeholderIconPath
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
