import QtQuick
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

Kirigami.Icon {
    id: root
    required property string icon
    property bool filled: false
    property alias monochrome: root.isMask
    property int implicitSize: 20
    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property string fallbackSource: root.icon !== "" && AppSearch.iconExists(root.icon) ? root.icon : `${Looks.iconsPath}/image-missing.svg`
    source: icon === "" ? "" : `${Looks.iconsPath}/${root.icon}${filled ? "-filled" : ""}.svg`
    fallback: root.fallbackSource
    roundToIconSize: false
    color: Looks.colors.fg
    isMask: true
    animated: true
}
