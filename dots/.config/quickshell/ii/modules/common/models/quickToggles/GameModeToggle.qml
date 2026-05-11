import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common.models.hyprland
import qs.services

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    toggled: GlobalStates.gameModeActive
    icon: "gamepad"

    mainAction: () => {
        GlobalStates.gameModeActive = !GlobalStates.gameModeActive;
        if (GlobalStates.gameModeActive) {
            Quickshell.execDetached(["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1; keyword windowrule opacity 1 override 1 override, no_blur on, match:class .*"]);
        } else {
            Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    HyprlandConfigOption {
        id: confOpt
        key: "animations:enabled"
        onValueChanged: {
            GlobalStates.gameModeActive = !value;
        }
    }

    tooltipText: Translation.tr("Game mode")
}
