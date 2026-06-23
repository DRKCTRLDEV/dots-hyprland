import Quickshell.Io
import QtQuick

Process {
    id: root
    property string directory: ""
    property var extensions: [""]

    signal filesListed(var files)

    running: directory.length > 0
    command: ["ls", "-1", directory]

    stdout: StdioCollector {
        onStreamFinished: {
            if (text.length === 0) {
                root.filesListed([]);
                return;
            }
            const items = text.split("\n").filter(fileName => {
                return root.extensions.some(ext => fileName.endsWith(ext));
            }).map(fileName => `${root.directory}/${fileName}`);
            root.filesListed(items);
        }
    }
}
