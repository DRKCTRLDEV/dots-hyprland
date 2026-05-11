import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "gamepad"
    toggled: GlobalStates.gameModeActive

    onClicked: {
        GlobalStates.gameModeActive = !GlobalStates.gameModeActive
        if (GlobalStates.gameModeActive) {
            Quickshell.execDetached(["hyprctl", "--batch", "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1; keyword windowrule opacity 1 override 1 override, no_blur on, match:class .*"])
        } else {
            Quickshell.execDetached(["hyprctl", "reload"])
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -ne 0`]
        onExited: (exitCode, exitStatus) => {
            GlobalStates.gameModeActive = exitCode !== 0 // Inverted because enabled = nonzero exit
        }
    }

    StyledToolTip {
        text: Translation.tr("Game mode")
    }
}
