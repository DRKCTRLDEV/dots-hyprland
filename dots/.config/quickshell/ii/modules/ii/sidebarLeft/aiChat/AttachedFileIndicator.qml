pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    signal remove()
    property bool canRemove: true
    property string filePath: ""
    property string mimeType: ""
    property real maxHeight: 200
    property real imageWidth: -1
    property real imageHeight: -1
    property real fileSizeBytes: -1
    property var attachment: null
    onAttachmentChanged: {
        if (root.attachment)
            root.refreshFromDescriptor();
    }
    onFilePathChanged: {
        if (!root.attachment || !root.attachment.mimeType)
            root.refresh();
    }
    visible: (filePath !== "") || (root.attachment?.fileName ?? "") !== ""

    readonly property string displayName: root.attachment?.fileName
        || root.filePath.split("/").pop() || ""

    readonly property bool attachmentIsImage: {
        const mime = root.mimeType && root.mimeType.length > 0 ? root.mimeType : (root.attachment?.mimeType ?? "");
        return mime.startsWith("image/") || root.attachment?.kind === "image";
    }
    readonly property bool modelCanSeeImages: {
        const m = Ai.getModel();
        return !!m && (m.api_format === "gemini" || m.imageUploadSupported === true);
    }
    readonly property string chipLabel: (root.attachmentIsImage && root.modelCanSeeImages)
        ? Translation.tr("Image") : Translation.tr("Document")
    readonly property string infoLine: {
        const bits = [root.chipLabel];
        if (root.fileSizeBytes >= 0)
            bits.push(Ai.humanFileSize(root.fileSizeBytes));
        if (root.attachmentIsImage && root.imageWidth > 0 && root.imageHeight > 0)
            bits.push(`${root.imageWidth}×${root.imageHeight}`);
        return bits.join(" · ");
    }

    function refreshFromDescriptor() {
        root.mimeType = root.attachment?.mimeType ?? "";
        const storedSize = root.attachment?.sizeBytes ?? -1;
        root.fileSizeBytes = (storedSize > 0) ? storedSize : -1;
        const w = root.attachment?.width ?? -1;
        const h = root.attachment?.height ?? -1;
        const hasDimensions = w > 0 && h > 0;
        root.imageWidth = hasDimensions ? w : -1;
        root.imageHeight = hasDimensions ? h : -1;
        if (root.attachmentIsImage && root.filePath.length > 0 && !hasDimensions)
            imageSizeProc.exec(["identify", "-format", "%wx%h", root.filePath]);
        if (root.filePath.length > 0 && root.fileSizeBytes < 0)
            fileSizeProc.exec(["stat", "-c", "%s", root.filePath]);
    }

    function refresh() {
        root.mimeType = "";
        root.imageWidth = -1;
        root.imageHeight = -1;
        fileTypeProc.exec(["file", "-b", "--mime-type", filePath]);
    }

    Process {
        id: fileTypeProc
        command: ["file", "-b", "--mime-type", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mimeType = this.text;
                if (root.mimeType.startsWith("image/"))
                    imageSizeProc.exec(["identify", "-format", "%wx%h", filePath]);
            }
        }
    }

    Process {
        id: imageSizeProc
        command: ["identify", "-format", "%wx%h", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const dimensions = this.text.split("x");
                root.imageWidth = parseInt(dimensions[0]);
                root.imageHeight = parseInt(dimensions[1]);
            }
        }
    }

    Process {
        id: fileSizeProc
        command: ["stat", "-c", "%s", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const size = parseInt(this.text);
                root.fileSizeBytes = (size == NaN) ? -1 : size;
            }
        }
    }

    property real horizontalPadding: 10
    property real verticalPadding: 10
    radius: Appearance.rounding.small - anchors.margins
    color: Appearance.colors.colLayer2
    implicitHeight: visible ? (contentItem.implicitHeight + verticalPadding * 2) : 0

    ColumnLayout {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: {
                    if (root.attachmentIsImage)
                        return "image";
                    if (root.mimeType === "application/pdf")
                        return "picture_as_pdf";
                    if (root.mimeType.startsWith("text/"))
                        return "description";
                    return "file_present";
                }
                iconSize: Appearance.font.pixelSize.hugeass
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    text: root.displayName
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.family: Appearance.font.family.monospace
                    wrapMode: Text.Wrap
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.infoLine
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
            }

            RippleButton {
                visible: root.canRemove
                Layout.alignment: Qt.AlignTop
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer2
                implicitHeight: 28
                implicitWidth: 28
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant
                }

                onClicked: root.remove()
            }
        }

        Loader {
            id: imagePreviewLoader
            visible: root.filePath.length > 0 && (root.imageWidth != -1) && (root.imageHeight != -1)
            active: root.filePath.length > 0 && (root.imageWidth != -1) && (root.imageHeight != -1)
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            sourceComponent: Item {
                id: previewArea
                width: parent ? parent.width : 0
                readonly property real fullHeight: root.imageHeight > 0
                    ? (width / root.imageWidth) * root.imageHeight
                    : 0
                readonly property real viewportHeight: Math.min(fullHeight, root.maxHeight)
                readonly property bool scrollable: fullHeight > viewportHeight
                readonly property real fadeBand: Appearance?.m3colors?.darkmode === true ? 40 : 20
                readonly property color fadeColor: Appearance.colors.colLayer2
                readonly property color fadeClear: {
                    const c = Qt.color(previewArea.fadeColor);
                    return Qt.rgba(c.r, c.g, c.b, 0);
                }
                implicitWidth: parent ? parent.width : 0
                implicitHeight: viewportHeight
                height: viewportHeight

                Item {
                    id: maskedPreview
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: maskedPreview.width
                            height: maskedPreview.height
                            radius: Appearance.rounding.normal
                        }
                    }

                    Flickable {
                        id: previewFlick
                        anchors.fill: parent
                        clip: true
                        contentWidth: width
                        contentHeight: fullHeight
                        boundsBehavior: Flickable.StopAtBounds
                        boundsMovement: Flickable.StopAtBounds
                        interactive: previewArea.scrollable
                        flickDeceleration: 1800

                        StyledImage {
                            width: maskedPreview.width
                            height: fullHeight
                            source: Qt.resolvedUrl(root.filePath)
                            fillMode: Image.PreserveAspectFit
                            antialiasing: true
                            asynchronous: true
                            sourceSize.width: Math.max(1, Math.round(maskedPreview.width))
                            sourceSize.height: Math.max(1, Math.round(fullHeight))
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant
                    radius: Appearance.rounding.normal
                    z: 2
                }
            }
        }
    }
}
