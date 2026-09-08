pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Provides some system info: distro, username.
 */
Singleton {
    id: root

    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "linux-symbolic"
    property string username: "user"
    property string homeUrl: ""
    property string documentationUrl: ""
    property string supportUrl: ""
    property string bugReportUrl: ""
    property string privacyPolicyUrl: ""
    property string logo: ""
    property string desktopEnvironment: ""
    property string windowingSystem: ""

    function osReleaseValue(contents, key) {
        const match = contents.match(new RegExp("^" + key + "=(.*)$", "m"));
        if (!match) return "";

        let value = match[1].trim();
        if (value.length >= 2 &&
            ((value[0] === '"' && value[value.length - 1] === '"') ||
             (value[0] === "'" && value[value.length - 1] === "'"))) {
            value = value.slice(1, -1);
        }
        return value;
    }

    function updateOsRelease(contents) {
        const prettyName = root.osReleaseValue(contents, "PRETTY_NAME");
        const name = root.osReleaseValue(contents, "NAME");
        root.distroName = prettyName || (name ? name.replace(/Linux/i, "").trim() : "Unknown");

        root.distroId = (root.osReleaseValue(contents, "ID") || "unknown").toLowerCase();
        const idLike = root.osReleaseValue(contents, "ID_LIKE").toLowerCase().split(/\s+/);

        root.homeUrl = root.osReleaseValue(contents, "HOME_URL");
        root.documentationUrl = root.osReleaseValue(contents, "DOCUMENTATION_URL");
        root.supportUrl = root.osReleaseValue(contents, "SUPPORT_URL");
        root.bugReportUrl = root.osReleaseValue(contents, "BUG_REPORT_URL");
        root.privacyPolicyUrl = root.osReleaseValue(contents, "PRIVACY_POLICY_URL");
        root.logo = root.osReleaseValue(contents, "LOGO");

        // Prefer an exact distro match, then use ID_LIKE for derivatives.
        switch (root.distroId) {
            case "artix":
            case "arch": root.distroIcon = "arch-symbolic"; break;
            case "manjaro": root.distroIcon = "manjaro-symbolic"; break;
            case "endeavouros": root.distroIcon = "endeavouros-symbolic"; break;
            case "cachyos": root.distroIcon = "cachyos-symbolic"; break;
            case "nixos": root.distroIcon = "nixos-symbolic"; break;
            case "fedora": root.distroIcon = "fedora-symbolic"; break;
            case "linuxmint":
            case "ubuntu":
            case "zorin":
            case "popos": root.distroIcon = "ubuntu-symbolic"; break;
            case "debian":
            case "raspbian":
            case "kali": root.distroIcon = "debian-symbolic"; break;
            case "funtoo":
            case "gentoo": root.distroIcon = "gentoo-symbolic"; break;
            default:
                if (idLike.indexOf("arch") !== -1)
                    root.distroIcon = "arch-symbolic";
                else if (idLike.indexOf("fedora") !== -1)
                    root.distroIcon = "fedora-symbolic";
                else if (idLike.indexOf("debian") !== -1)
                    root.distroIcon = "debian-symbolic";
                else
                    root.distroIcon = "linux-symbolic";
                break;
        }

        if (contents.toLowerCase().includes("nyarch"))
            root.distroIcon = "nyarch-symbolic";

        if (root.logo.trim().length === 0)
            root.logo = root.distroIcon;
    }

    Timer {
        triggeredOnStart: true
        interval: 0
        running: true
        repeat: false
        onTriggered: {
            getUsername.running = true;
            fileOsRelease.reload();
        }
    }

    Process {
        id: getUsername
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => {
                root.username = data.trim();
            }
        }
    }

    Process {
        id: getDesktopEnvironment
        running: true
        command: ["bash", "-c", "echo $XDG_CURRENT_DESKTOP,$WAYLAND_DISPLAY"]
        stdout: StdioCollector {
            id: deCollector
            onStreamFinished: {
                const [desktop, wayland] = deCollector.text.split(",");
                root.desktopEnvironment = desktop.trim();
                root.windowingSystem = wayland.trim().length > 0 ? "Wayland" : "X11";
            }
        }
    }

    FileView {
        id: fileOsRelease
        path: "/etc/os-release"
        onLoaded: root.updateOsRelease(text())
        onLoadFailed: {
            root.distroName = "Unknown";
            root.distroId = "unknown";
            root.distroIcon = "linux-symbolic";
        }
    }
}
