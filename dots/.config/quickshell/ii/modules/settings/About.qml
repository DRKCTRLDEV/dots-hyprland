import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: aboutPage
    forceWidth: true

    property string cpuModel: ""
    property string gpuModel: ""
    property string kernelVersion: ""
    property string hostname: ""
    property string totalMemory: ""
    property string hyprlandVersion: ""
    property string qtVersion: ""
    property string uptimeText: DateTime.uptime

    Process {
        running: true
        command: ["bash", "-c", "grep 'model name' /proc/cpuinfo | head -1 | sed 's/.*: //'"]
        stdout: SplitParser { onRead: data => { aboutPage.cpuModel = data.trim(); } }
    }
    Process {
        running: true
        command: ["bash", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //'"]
        stdout: SplitParser { onRead: data => { aboutPage.gpuModel = data.trim(); } }
    }
    Process {
        running: true
        command: ["uname", "-r"]
        stdout: SplitParser { onRead: data => { aboutPage.kernelVersion = data.trim(); } }
    }
    Process {
        running: true
        command: ["hostname"]
        stdout: SplitParser { onRead: data => { aboutPage.hostname = data.trim(); } }
    }
    Process {
        running: true
        command: ["bash", "-c", "awk '/MemTotal/ {printf \"%.1f GiB\", $2/1048576}' /proc/meminfo"]
        stdout: SplitParser { onRead: data => { aboutPage.totalMemory = data.trim(); } }
    }
    Process {
        running: true
        command: ["bash", "-c", "hyprctl version -j 2>/dev/null | grep -o '\"tag\": *\"[^\"]*\"' | head -1 | sed 's/.*\"\\([^\"]*\\)\"/\\1/' || hyprctl version 2>/dev/null | head -1"]
        stdout: SplitParser { onRead: data => { aboutPage.hyprlandVersion = data.trim(); } }
    }
    Process {
        running: true
        command: ["bash", "-c", "qmake -query QT_VERSION 2>/dev/null || qmake6 -query QT_VERSION 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => { aboutPage.qtVersion = data.trim(); } }
    }

    ContentSection {
        icon: "person"
        title: Translation.tr("User")

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: 2
            columnSpacing: 20
            rowSpacing: 6

            StyledText { text: Translation.tr("User"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: SystemInfo.username; font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { text: Translation.tr("Hostname"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: aboutPage.hostname || "—"; font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { text: Translation.tr("Uptime"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: aboutPage.uptimeText; font.pixelSize: Appearance.font.pixelSize.small }
        }
    }

    ContentSection {
        icon: "computer"
        title: Translation.tr("System")

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: 2
            columnSpacing: 20
            rowSpacing: 6

            StyledText { text: Translation.tr("Distribution"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            RowLayout {
                spacing: 8
                IconImage {
                    implicitSize: Appearance.font.pixelSize.small + 4
                    source: Quickshell.iconPath(SystemInfo.logo)
                }
                StyledText { text: SystemInfo.distroName; font.pixelSize: Appearance.font.pixelSize.small }
            }

            StyledText { text: Translation.tr("Desktop"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: "Hyprland" + (aboutPage.hyprlandVersion.length > 0 ? ` ${aboutPage.hyprlandVersion}` : ""); font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { text: Translation.tr("Display server"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: "Wayland"; font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { text: Translation.tr("Shell"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: "QuickShell"; font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { text: Translation.tr("Kernel"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: aboutPage.kernelVersion || "—"; font.pixelSize: Appearance.font.pixelSize.small }

            StyledText { visible: aboutPage.qtVersion.length > 0; text: "Qt"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { visible: aboutPage.qtVersion.length > 0; text: aboutPage.qtVersion; font.pixelSize: Appearance.font.pixelSize.small }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Hardware")

        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            columns: 2
            columnSpacing: 20
            rowSpacing: 6

            StyledText { visible: aboutPage.cpuModel.length > 0; text: Translation.tr("Processor"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { visible: aboutPage.cpuModel.length > 0; text: aboutPage.cpuModel; font.pixelSize: Appearance.font.pixelSize.small; Layout.fillWidth: true; elide: Text.ElideRight }

            StyledText { visible: aboutPage.gpuModel.length > 0; text: Translation.tr("Graphics"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { visible: aboutPage.gpuModel.length > 0; text: aboutPage.gpuModel; font.pixelSize: Appearance.font.pixelSize.small; Layout.fillWidth: true; elide: Text.ElideRight }

            StyledText { visible: aboutPage.totalMemory.length > 0; text: Translation.tr("Memory"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { visible: aboutPage.totalMemory.length > 0; text: aboutPage.totalMemory; font.pixelSize: Appearance.font.pixelSize.small }
        }
    }

    ContentSection {
        icon: "auto_awesome"
        title: Translation.tr("Links")

        Flow {
            Layout.fillWidth: true
            spacing: 5

            RippleButtonWithIcon {
                materialIcon: "code"
                mainText: Translation.tr("Source")
                onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland")
            }
            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                onClicked: Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/")
            }
            RippleButtonWithIcon {
                materialIcon: "adjust"
                materialIconFill: false
                mainText: Translation.tr("Issues")
                onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues")
            }
            RippleButtonWithIcon {
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                onClicked: Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions")
            }
            RippleButtonWithIcon {
                materialIcon: "favorite"
                mainText: Translation.tr("Donate")
                onClicked: Qt.openUrlExternally("https://github.com/sponsors/end-4")
            }
        }
    }
}