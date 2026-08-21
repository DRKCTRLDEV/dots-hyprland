import QtQuick

QtObject {
    id: root

    required property double percentage
    property int warningThreshold: 100

    readonly property bool warning: percentage * 100 >= warningThreshold
}
