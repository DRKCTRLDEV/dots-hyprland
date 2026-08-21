pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root
    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    function updateWindowList() {
        getAll.running = true;
    }

    function updateLayers() {
        getAll.running = true;
    }

    function updateMonitors() {
        getAll.running = true;
    }

    function updateWorkspaces() {
        getAll.running = true;
    }

    function updateAll() {
        getAll.running = true;
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }

    function splitJsonDocuments(text, count) {
        const docs = [];
        let i = 0;
        const n = text.length;
        for (let d = 0; d < count; d++) {
            while (i < n) {
                const ws = text.charCodeAt(i);
                if (ws !== 32 && ws !== 9 && ws !== 10 && ws !== 13) break;
                i++;
            }
            if (i >= n) break;
            const open = text.charCodeAt(i); // '[' = 91, '{' = 123
            if (open !== 91 && open !== 123) break;
            const close = open === 91 ? 93 : 125; // ']' = 93, '}' = 125
            const start = i;
            let depth = 0;
            let inString = false;
            let escaped = false;
            i++;
            for (; i < n; i++) {
                const c = text.charCodeAt(i);
                if (inString) {
                    if (escaped) escaped = false;
                    else if (c === 92) escaped = true; // backslash
                    else if (c === 34) inString = false; // double quote
                } else if (c === 34) {
                    inString = true;
                } else if (c === open) {
                    depth++;
                } else if (c === close) {
                    if (depth === 0) { i++; break; }
                    depth--;
                }
            }
            docs.push(text.slice(start, i));
        }
        return docs;
    }

    function parseClients(text) {
        try {
            root.windowList = JSON.parse(text);
            let tempWinByAddress = {};
            for (var i = 0; i < root.windowList.length; ++i) {
                var win = root.windowList[i];
                tempWinByAddress[win.address] = win;
            }
            root.windowByAddress = tempWinByAddress;
            root.addresses = root.windowList.map(win => win.address);
        } catch (e) {
            console.error("[HyprlandData] Error parsing clients:", e);
        }
    }

    function parseMonitors(text) {
        try {
            root.monitors = JSON.parse(text);
        } catch (e) {
            console.error("[HyprlandData] Error parsing monitors:", e);
        }
    }

    function parseLayers(text) {
        try {
            root.layers = JSON.parse(text);
        } catch (e) {
            console.error("[HyprlandData] Error parsing layers:", e);
        }
    }

    function parseWorkspaces(text) {
        try {
            var rawWorkspaces = JSON.parse(text);
            root.workspaces = rawWorkspaces.filter(ws => ws.id >= 1 && ws.id <= 100);
            let tempWorkspaceById = {};
            for (var i = 0; i < root.workspaces.length; ++i) {
                var ws = root.workspaces[i];
                tempWorkspaceById[ws.id] = ws;
            }
            root.workspaceById = tempWorkspaceById;
            root.workspaceIds = root.workspaces.map(ws => ws.id);
        } catch (e) {
            console.error("[HyprlandData] Error parsing workspaces:", e);
        }
    }

    function parseActiveWorkspace(text) {
        try {
            root.activeWorkspace = JSON.parse(text);
        } catch (e) {
            console.error("[HyprlandData] Error parsing active workspace:", e);
        }
    }

    function handleBatchOutput(text) {
        const docs = splitJsonDocuments(text, 5);
        if (docs.length >= 1) parseClients(docs[0]);
        if (docs.length >= 2) parseMonitors(docs[1]);
        if (docs.length >= 3) parseLayers(docs[2]);
        if (docs.length >= 4) parseWorkspaces(docs[3]);
        if (docs.length >= 5) parseActiveWorkspace(docs[4]);
    }

    Component.onCompleted: {
        updateAll();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return;
            updateAll()
        }
    }

    Process {
        id: getAll
        command: ["hyprctl", "--batch", "j/clients; j/monitors; j/layers; j/workspaces; j/activeworkspace"]
        stdout: StdioCollector {
            id: batchCollector
            onStreamFinished: {
                root.handleBatchOutput(batchCollector.text);
            }
        }
    }
}
