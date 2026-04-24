pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    property bool isWidget: false
    implicitWidth: root.isWidget ? -1 : Appearance.sizes.mediaControlsWidth
    implicitHeight: root.isWidget ? -1 : Appearance.sizes.mediaControlsHeight
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property var visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius
    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    function toggleMute() {
        MprisController.toggleMute(root.player);
    }
    function openExternal() {
        MprisController.openExternal(root.player);
    }


    component IconBtn: RippleButton {
        id: iconBtn
        implicitWidth: 16
        implicitHeight: 16

        property var iconName
        property real iconSize: Appearance.font.pixelSize.hugeass
        rippleEnabled: false
        colBackground: "transparent"
        colBackgroundHover: "transparent"

        contentItem: MaterialSymbol {
            iconSize: iconBtn.iconSize
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.media.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged();
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer;
            return;
        }

        // Download
        root.downloaded = false;
        coverArtDownloaderLoader.active = true;
    }

    Loader {
        id: coverArtDownloaderLoader
        active: false
        sourceComponent: Process {
            property string targetFile: root.artUrl
            property string artFilePath: root.artFilePath
            command: ["bash", "-c", `[ -f '${artFilePath}' ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'`]
            running: true
            onExited: (exitCode, exitStatus) => {
                root.downloaded = true;
                coverArtDownloaderLoader.active = false;
            }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    StyledRectangularShadow {
        target: background
        visible: !root.isWidget
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: root.isWidget ? 0 : Appearance.sizes.elevationMargin
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: background.width
            sourceSize.height: background.height
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                radius: root.radius
            }
        }

        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!(root.player?.volumeSupported && root.player?.canControl))
                    return;

                const delta = event.angleDelta.y / 120;
                root.player.volume = Math.max(0, Math.min(1, (root.player?.volume ?? 0) + delta * 0.05));
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle { // Art background
                id: artBackground
                Layout.fillHeight: true
                implicitWidth: height
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true

                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size
                }

                Rectangle {
                    id: iconShadow
                    anchors.centerIn: parent
                    width: playPauseIcon.width + 16
                    height: width
                    radius: width / 2
                    color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                    scale: artMouseArea.containsMouse ? 1 : 0

                    MaterialSymbol {
                        id: playPauseIcon
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.hugeass * 1.8
                        fill: 1
                        color: blendedColors.colOnLayer0
                        text: root.player?.isPlaying ? "pause" : "play_arrow"
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutBack
                        }
                    }
                }

                MouseArea {
                    id: artMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }
            }

            ColumnLayout { // Info & controls
                Layout.fillWidth: true
                spacing: 0
                ColumnLayout {
                    Layout.fillWidth: true
                    StyledText {
                        id: trackTitle
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.large
                        color: blendedColors.colOnLayer0
                        elide: Text.ElideRight
                        text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                        animateChange: true
                        animationDistanceX: 6
                        animationDistanceY: 0
                    }
                    StyledText {
                        id: trackArtist
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: root.player?.trackArtist
                        animateChange: true
                        animationDistanceX: 6
                        animationDistanceY: 0
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        IconBtn {
                            iconSize: Appearance.font.pixelSize.larger
                            iconName: "open_in_new"
                            downAction: () => {
                                if (MprisController.canOpenExternal(root.player)) {
                                    root.openExternal();
                                }
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: blendedColors.colSubtext
                            elide: Text.ElideRight
                            text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                        }
                        RowLayout {
                            StyledText {
                                color: blendedColors.colSubtext
                                text: Math.round((root.player?.volume ?? 0) * 100) + "%"
                            }
                            IconBtn {
                                iconSize: Appearance.font.pixelSize.larger
                                iconName: (root.player?.volume ?? 0) <= 0 ? "volume_off" : (root.player?.volume ?? 0) < 0.5 ? "volume_down" : "volume_up"
                                downAction: () => root.toggleMute()
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        IconBtn {
                            visible: root.player?.canGoPrevious ?? false
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                            altAction: () => root.player?.seek(-5)
                        }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    id: seekSlider
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    trackDotSize: 0
                                    handleHeight: 16
                                    implicitHeight: 18

                                    Timer {
                                        id: ignoreUpdatesTimer
                                        interval: 800
                                        repeat: false
                                    }

                                    Timer {
                                        id: trackChangeTimer
                                        interval: 800
                                        repeat: false
                                    }

                                    Connections {
                                        target: root.player
                                        function onPostTrackChanged() {
                                            seekSlider.value = 0;
                                            trackChangeTimer.restart();
                                        }
                                    }

                                    Binding {
                                        target: seekSlider
                                        property: "value"
                                        value: {
                                            const length = root.player?.length ?? 0;
                                            if (length <= 0) return 0;
                                            return (root.player?.position ?? 0) / length;
                                        }
                                        when: !seekSlider.pressed && !ignoreUpdatesTimer.running && !seekDebounceTimer.running && !trackChangeTimer.running
                                        restoreMode: Binding.RestoreBindingOrValue
                                    }

                                    Timer {
                                        id: seekDebounceTimer
                                        interval: 150
                                        repeat: false
                                        onTriggered: {
                                            const length = root.player?.length ?? 0;
                                            if (!root.player?.canSeek || length <= 0) return;
                                            root.player.position = seekSlider.value * length;
                                            ignoreUpdatesTimer.restart();
                                        }
                                    }

                                    onMoved: {
                                        if (root.player?.canSeek) {
                                            seekDebounceTimer.restart();
                                        }
                                    }

                                    onPressedChanged: {
                                        if (pressed) {
                                            seekDebounceTimer.stop();
                                            ignoreUpdatesTimer.stop();
                                        } else {
                                            if (root.player?.canSeek) {
                                                seekDebounceTimer.restart();
                                            }
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    wavy: root.player?.isPlaying ?? false
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: root.player?.position / root.player?.length
                                    implicitHeight: 18
                                }
                            }
                        }
                        IconBtn {
                            visible: root.player?.canGoNext ?? false
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                            altAction: () => root.player?.seek(5)
                        }
                    }
                }
            }
        }
    }
}
