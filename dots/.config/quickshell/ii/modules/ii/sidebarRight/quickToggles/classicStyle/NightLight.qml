import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.services

ClassicQuickToggleButton {
    id: root

    toggleModel: NightLightToggle {}

    altAction: () => {
        Config.options.light.night.automatic = !Config.options.light.night.automatic
    }
    tooltipText: Translation.tr("Night Light | Right-click to toggle Auto mode")
}
