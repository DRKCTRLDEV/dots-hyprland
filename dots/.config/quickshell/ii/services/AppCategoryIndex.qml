pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var appsByCategory: ({})

    function rebuild() {
        const map = ({});
        const apps = Array.from(DesktopEntries.applications.values);
        for (const app of apps) {
            const cats = Array.from(app.categories ?? []);
            for (const cat of cats) {
                if (!map[cat]) map[cat] = [];
                map[cat].push(app);
            }
        }
        for (const key in map) {
            map[key].sort((a, b) => a.name.localeCompare(b.name));
        }
        root.appsByCategory = map;
    }

    function appsForCategories(categories) {
        const map = root.appsByCategory;
        const seen = ({});
        const result = [];
        for (const cat of (categories ?? [])) {
            const entries = map[cat];
            if (!entries) continue;
            for (const app of entries) {
                if (seen[app.id]) continue;
                seen[app.id] = true;
                result.push(app);
            }
        }
        result.sort((a, b) => a.name.localeCompare(b.name));
        return result;
    }

    Component.onCompleted: root.rebuild()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.rebuild();
        }
    }
}
