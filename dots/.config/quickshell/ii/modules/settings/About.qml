import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ContentPage {
    forceWidth: true

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        Layout.topMargin: -8
        Layout.leftMargin: -8
        Layout.rightMargin: -8

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: CF.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.15)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15

            IconImage {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: 120
                source: Quickshell.iconPath("illogical-impulse")
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("illogical-impulse")
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Modern, Material You Desktop Shell")
                font.pixelSize: Appearance.font.pixelSize.normal
                opacity: 0.8
            }
        }
    }

    ContentSection {
        icon: "link"
        title: Translation.tr("Quick Links")

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "auto_stories"
                mainText: Translation.tr("Documentation")
                colBackground: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.5)
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive
                onClicked: {
                    Qt.openUrlExternally("https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/02usage/");
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "code"
                mainText: Translation.tr("GitHub Repository")
                colBackground: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.5)
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland");
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "forum"
                mainText: Translation.tr("Discussions")
                colBackground: CF.ColorUtils.transparentize(Appearance.colors.colTertiaryContainer, 0.5)
                colBackgroundHover: Appearance.colors.colTertiaryContainerHover
                colRipple: Appearance.colors.colTertiaryContainerActive
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/discussions");
                }
            }
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "bug_report"
                mainText: Translation.tr("Report Issue")
                colBackground: CF.ColorUtils.transparentize(Appearance.colors.colTertiaryContainer, 0.5)
                colBackgroundHover: Appearance.colors.colTertiaryContainerHover
                colRipple: Appearance.colors.colTertiaryContainerActive
                onClicked: {
                    Qt.openUrlExternally("https://github.com/end-4/dots-hyprland/issues");
                }
            }
        }
    }

    ContentSection {
        icon: "volunteer_activism"
        title: Translation.tr("Support the Project")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("If you enjoy using illogical-impulse, consider supporting the development!")
                wrapMode: Text.WordWrap
                opacity: 0.9
            }

            RippleButtonWithIcon {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                materialIcon: "favorite"
                mainText: Translation.tr("Sponsor on GitHub")
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                colRipple: Appearance.colors.colPrimaryContainerActive
                onClicked: {
                    Qt.openUrlExternally("https://github.com/sponsors/end-4");
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "star"
                    mainText: Translation.tr("Star on GitHub")
                    colBackground: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.5)
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/end-4/dots-hyprland");
                    }
                }
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "share"
                    mainText: Translation.tr("Share with Friends")
                    colBackground: CF.ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.5)
                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                    colRipple: Appearance.colors.colSecondaryContainerActive
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/end-4/dots-hyprland");
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "box"
        title: Translation.tr("Distribution")

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: contentLayout.implicitHeight + 40
            radius: Appearance.rounding.normal
            color: CF.ColorUtils.transparentize(Appearance.colors.colLayer2, 0.5)

            RowLayout {
                id: contentLayout
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 20

                IconImage {
                    implicitSize: 64
                    source: Quickshell.iconPath(SystemInfo.logo)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: SystemInfo.distroName
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        text: SystemInfo.homeUrl
                        textFormat: Text.MarkdownText
                        opacity: 0.7
                        onLinkActivated: link => {
                            Qt.openUrlExternally(link);
                        }
                        PointingHandLinkHover {}
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8

            RippleButtonWithIcon {
                materialIcon: "auto_stories"
                materialIconFill: false
                mainText: Translation.tr("Docs")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.documentationUrl);
                }
            }
            RippleButtonWithIcon {
                materialIcon: "support"
                materialIconFill: false
                mainText: Translation.tr("Support")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.supportUrl);
                }
            }
            RippleButtonWithIcon {
                materialIcon: "shield_with_heart"
                materialIconFill: false
                mainText: Translation.tr("Privacy")
                onClicked: {
                    Qt.openUrlExternally(SystemInfo.privacyPolicyUrl);
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: versionText.implicitHeight
        Layout.topMargin: 20

        StyledText {
            id: versionText
            anchors.centerIn: parent
            text: Translation.tr("Version %1 • Made with ♥ by end-4 and contributors").arg("2.0")
            font.pixelSize: Appearance.font.pixelSize.smaller
            opacity: 0.6
        }
    }
}
