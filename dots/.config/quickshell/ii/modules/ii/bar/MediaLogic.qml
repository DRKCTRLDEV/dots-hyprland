import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    property int updateInterval: 1000

    function handlePress(event) {
        if (event.button === Qt.MiddleButton) {
            activePlayer.togglePlaying();
        } else if (event.button === Qt.BackButton) {
            activePlayer.previous();
        } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
            activePlayer.next();
        } else if (event.button === Qt.LeftButton) {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
        }
    }

    property Timer refreshTimer: Timer {
        running: root.activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: root.updateInterval
        repeat: true
        onTriggered: root.activePlayer.positionChanged()
    }
}
