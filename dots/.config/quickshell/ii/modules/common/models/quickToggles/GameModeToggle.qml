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
            HyprlandConfig.setMany({
                "animations:enabled": 0,
                "decoration:shadow:enabled": 0,
                "decoration:blur:enabled": 0,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "decoration:rounding": 0,
                "general:allow_tearing": 1
            });
        } else {
            HyprlandConfig.resetMany([ //
                "animations:enabled", //
                "decoration:shadow:enabled", //
                "decoration:blur:enabled", //
                "general:gaps_in", //
                "general:gaps_out", //
                "general:border_size", //
                "decoration:rounding", //
                "general:allow_tearing", //
            ]);
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
