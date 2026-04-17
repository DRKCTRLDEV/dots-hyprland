pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs
import qs.modules.common.functions

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
    id: root

    signal trackChanged(reverse: bool)

    property bool hasActivePlasmaIntegration: false
    property list<MprisPlayer> players: []
    property var meaningfulPlayers: filterDuplicatePlayers(players)
    property list<real> visualizerPoints: []

    function filterDuplicatePlayers(playersList) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < playersList.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = playersList[i];
            let group = [i];

            for (let j = i + 1; j < playersList.length; ++j) {
                let p2 = playersList[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            let chosenIdx = group.find(idx => playersList[idx].trackArtUrl && playersList[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(playersList[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Component.onCompleted: refreshPlayers()
    Connections {
        target: Config.options.media
        function onFilterDuplicatePlayersChanged() {
            refreshPlayers();
        }
    }
    function refreshPlayers() {
        hasActivePlasmaIntegration = Mpris.players.values.some(player => player.busName && player.busName.startsWith("org.mpris.MediaPlayer2.plasma-browser-integration"));
        players = Mpris.players.values.filter(player => isRealPlayer(player));
    }


    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: {
        if (trackedPlayer && players.indexOf(trackedPlayer) >= 0)
            return trackedPlayer;
        const playing = players.find(player => player.isPlaying);
        return playing ?? players[0] ?? null;
    }

    property bool __reverse: false
    property var __mutedVolumeCache: ({})
    property var activeTrack: ({
            uniqueId: 0,
            artUrl: "",
            title: Translation.tr("Unknown Title"),
            artist: Translation.tr("Unknown Artist"),
            album: Translation.tr("Unknown Album")
        })

    function isRealPlayer(player: MprisPlayer): bool {
        if (!player)
            return false;
        if (!Config.options.media.filterDuplicatePlayers)
            return true;

        const busName = player.busName ?? "";
        if (busName.startsWith("org.mpris.MediaPlayer2.playerctld"))
            return false;
        if (busName.endsWith(".mpd") && !busName.endsWith("MediaPlayer2.mpd"))
            return false;
        if (hasActivePlasmaIntegration && (busName.startsWith("org.mpris.MediaPlayer2.firefox") || busName.startsWith("org.mpris.MediaPlayer2.chromium")))
            return false;

        return true;
    }

    function updateTrack(preserveReverse = false): void {
        activeTrack = {
            uniqueId: activePlayer?.uniqueId ?? 0,
            artUrl: activePlayer?.trackArtUrl ?? "",
            title: activePlayer?.trackTitle || Translation.tr("Unknown Title"),
            artist: activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
            album: activePlayer?.trackAlbum || Translation.tr("Unknown Album")
        };

        trackChanged(__reverse);
        if (!preserveReverse)
            __reverse = false;
    }

    onActivePlayerChanged: updateTrack()

    Instantiator {
        model: Mpris.players

        onObjectAdded: root.refreshPlayers()
        onObjectRemoved: root.refreshPlayers()

        Connections {
            required property MprisPlayer modelData
            target: modelData

            function onPlaybackStateChanged() {
                if (modelData.isPlaying && root.trackedPlayer !== modelData) {
                    root.trackedPlayer = modelData;
                } else if (root.trackedPlayer === modelData) {
                    root.trackedPlayer = null;
                    root.trackedPlayer = modelData;
                }
            }
        }
    }

    Connections {
        target: activePlayer

        function onPostTrackChanged() {
            root.updateTrack();
        }

        function onTrackArtUrlChanged() {
            if (!root.activePlayer)
                return;
            if (root.activePlayer.uniqueId !== root.activeTrack?.uniqueId)
                return;
            if (root.activePlayer.trackArtUrl === root.activeTrack?.artUrl)
                return;
            root.updateTrack(true);
        }
    }

    property bool isPlaying: activePlayer?.isPlaying ?? false
    property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false

    function togglePlaying(): void {
        if (canTogglePlaying)
            activePlayer.togglePlaying();
    }

    property bool canGoPrevious: activePlayer?.canGoPrevious ?? false

    function previous(): void {
        if (!canGoPrevious)
            return;
        __reverse = true;
        activePlayer.previous();
    }

    property bool canGoNext: activePlayer?.canGoNext ?? false

    function next(): void {
        if (!canGoNext)
            return;
        __reverse = false;
        activePlayer.next();
    }

    property bool canChangeVolume: (activePlayer?.volumeSupported && activePlayer?.canControl) ?? false

    function setVolume(volume: real, player: MprisPlayer): void {
        const targetPlayer = player ?? activePlayer;
        if (!(targetPlayer?.volumeSupported && targetPlayer?.canControl))
            return;
        targetPlayer.volume = Math.max(0, Math.min(1, volume));
    }

    function canOpenExternal(player: MprisPlayer): bool {
        const targetPlayer = player ?? activePlayer;
        if (!targetPlayer)
            return false;
        const entry = targetPlayer.desktopEntry ?? "";
        return targetPlayer.canRaise || entry.length > 0;
    }

    function openExternal(player: MprisPlayer): void {
        const targetPlayer = player ?? activePlayer;
        if (!targetPlayer)
            return;

        if (targetPlayer.canRaise) {
            targetPlayer.raise();
        }

        const entry = targetPlayer.desktopEntry ?? "";
        if (entry.length > 0) {
            let className = entry;
            if (className.toLowerCase().endsWith('.desktop')) {
                className = className.substring(0, className.length - 8);
            }
            focusWindowProc.command = ["hyprctl", "dispatch", "focuswindow", `class:(?i).*${className}.*`];
            focusWindowProc.running = true;
        }
    }

    function toggleMute(player: MprisPlayer): void {
        const targetPlayer = player ?? activePlayer;
        if (!(targetPlayer?.volumeSupported && targetPlayer?.canControl))
            return;
        const cacheKey = targetPlayer.busName ?? `${targetPlayer.uniqueId}`;
        const currentVolume = targetPlayer.volume ?? 0;

        if (currentVolume > 0) {
            __mutedVolumeCache[cacheKey] = currentVolume;
            setVolume(0, targetPlayer);
            return;
        }

        const restoredVolume = __mutedVolumeCache[cacheKey];
        setVolume(restoredVolume > 0 ? restoredVolume : 0.5, targetPlayer);
    }

    IpcHandler {
        target: "mpris"

        function pauseAll(): void {
            for (const player of root.players) {
                if (player.canPause)
                    player.pause();
            }
        }

        function playPause(): void { root.togglePlaying(); }
        function previous(): void { root.previous(); }
        function next(): void { root.next(); }
    }

    Process {
        id: cavaProc
        running: GlobalStates.sidebarRightOpen || GlobalStates.mediaControlsOpen
        onRunningChanged: if (!running) root.visualizerPoints = []
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                root.visualizerPoints = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            }
        }
    }

    Process {
        id: focusWindowProc
    }
}
