pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

StyledImage {
    id: avatar
    Layout.alignment: Qt.AlignTop
    sourceSize: Qt.size(32, 32)

    readonly property var candidates: [
        Directories.userAvatarPathAccountsService,
        Directories.userAvatarPathRicersAndWeirdSystems,
        Directories.userAvatarPathRicersAndWeirdSystems2
    ]
    property string chosenSource: ""
    source: chosenSource

    FileView {
        id: accountsProbe
        path: avatar.candidates[0]
        printErrors: false
        onLoaded: avatar.chosenSource = accountsProbe.path
    }
    FileView {
        id: faceProbe
        path: avatar.candidates[1]
        printErrors: false
        onLoaded: { if (!avatar.chosenSource) avatar.chosenSource = faceProbe.path; }
    }
    FileView {
        id: faceIconProbe
        path: avatar.candidates[2]
        printErrors: false
        onLoaded: { if (!avatar.chosenSource) avatar.chosenSource = faceIconProbe.path; }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Circle {
            diameter: avatar.height
        }
    }
}
