import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import QtQuick

ClassicQuickToggleButton {
    id: root

    toggleModel: CloudflareWarpToggle { available: false }

    contentItem: CustomIcon {
        source: 'cloudflare-dns-symbolic'

        anchors.centerIn: parent
        width: 16
        height: 16
        colorize: true
        color: root.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
