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
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""
    readonly property bool canChangeVolume: (root.player?.volumeSupported ?? false) && (root.player?.canControl ?? false)
    property real lastNonZeroVolume: 1


    component IconBtn: RippleButton {
        id: iconBtn
        implicitWidth: 20
        implicitHeight: 20

        property var iconName
        property real iconSize: Appearance.font.pixelSize.hugeass
        colBackground: "transparent"
        colBackgroundHover: "transparent"

        Layout.leftMargin: -2
        Layout.rightMargin: -2

        contentItem: MaterialSymbol {
            iconSize: iconBtn.iconSize
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName
        }
    }

    Timer {
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
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
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

        StyledImage {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
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
            live: root.player?.isPlaying ?? false
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (!root.canChangeVolume)
                    return;

                const direction = Math.sign(event.angleDelta.y);
                if (direction === 0) {
                    return;
                }

                const currentPercent = Math.round((root.player?.volume ?? 0) * 100);
                const remainder = ((currentPercent % 5) + 5) % 5;
                const nextPercent = direction > 0
                    ? (remainder === 0 ? currentPercent + 5 : currentPercent + (5 - remainder))
                    : (remainder === 0 ? currentPercent - 5 : currentPercent - remainder);
                const newVolume = Math.max(0, Math.min(1, nextPercent / 100));
                root.player.volume = newVolume;
                if (newVolume > 0) {
                    root.lastNonZeroVolume = newVolume;
                }
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
                }

                MouseArea {
                    id: artMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.player?.canTogglePlaying ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.player?.canTogglePlaying) {
                            root.player.isPlaying = !(root.player?.isPlaying ?? false);
                        }
                    }
                }

                Rectangle {
                    id: iconShadow
                    anchors.centerIn: parent
                    width: playPauseIcon.width + 16
                    height: width
                    radius: width / 2
                    visible: root.player?.canTogglePlaying ?? false
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
            }

            ColumnLayout { // Info & controls
                ColumnLayout {
                    spacing: 0
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
                    spacing: 0
                    RowLayout {
                        IconBtn {
                            iconSize: Appearance.font.pixelSize.larger
                            iconName: (root.player?.canRaise ?? false) ? "open_in_new" : "open_in_new_off"
                            downAction: () => {
                                if (root.player?.canRaise) {
                                    root.player.raise();
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
                                visible: root.canChangeVolume
                                downAction: () => {
                                    if (!root.canChangeVolume) {
                                        return;
                                    }

                                    const currentVolume = root.player?.volume ?? 0;
                                    if (currentVolume > 0) {
                                        root.lastNonZeroVolume = currentVolume;
                                        root.player.volume = 0;
                                    } else {
                                        root.player.volume = Math.max(0.01, root.lastNonZeroVolume);
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        IconBtn {
                            visible: root.player?.canGoPrevious ?? false
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                            altAction: () => {
                                if (root.player?.canSeek) {
                                    root.player.seek(-5);
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: (root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false)
                                sourceComponent: StyledSlider {
                                    id: seekSlider
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    trackDotSize: 0
                                    handleHeight: 16
                                    Binding on value { when: !seekSlider.pressed; value: (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / (root.player?.length ?? 1) : 0 }
                                    onMoved: {
                                        const length = root.player?.length ?? 0;
                                        if (root.player?.canSeek && root.player?.positionSupported && length > 0) {
                                            root.player.position = value * length;
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors.fill: parent
                                active: !sliderLoader.active
                                sourceComponent: StyledProgressBar {
                                    wavy: root.player?.isPlaying ?? false
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    stopPoint: false
                                    value: (root.player?.length ?? 0) > 0 ? (root.player?.position ?? 0) / (root.player?.length ?? 1) : 0
                                }
                            }
                        }
                        IconBtn {
                            visible: root.player?.canGoNext ?? false
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                            altAction: () => {
                                if (root.player?.canSeek) {
                                    root.player.seek(5);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
