pragma Singleton
import Quickshell
import qs.modules.common

Singleton {
    id: root

    function getValue(path, fallback) {
        if (!path) return fallback;
        const keys = path.split(".");
        let obj = Config.options;
        for (let i = 0; i < keys.length; ++i) {
            if (obj === undefined || obj === null) return fallback;
            obj = obj[keys[i]];
        }
        return obj === undefined ? fallback : obj;
    }

    function setValue(path, value) {
        if (!path) return;
        const keys = path.split(".");
        let obj = Config.options;
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj || typeof obj !== "object") return;
            obj = obj[keys[i]];
        }
        if (!obj || typeof obj !== "object") return;
        obj[keys[keys.length - 1]] = value;
    }
}
