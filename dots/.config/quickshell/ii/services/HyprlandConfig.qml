pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    signal reloaded()

    readonly property string configuratorScriptPath: Quickshell.shellPath("scripts/hyprland/hyprconfigurator.py")
    readonly property string shellOverridesPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/shellOverrides/main.lua`)

    function set(key: string, value: var, reload) {
        let cmd = `'${StringUtils.shellSingleQuoteEscape(root.configuratorScriptPath)}' --file '${StringUtils.shellSingleQuoteEscape(root.shellOverridesPath)}' --set '${StringUtils.shellSingleQuoteEscape(key)}' '${StringUtils.shellSingleQuoteEscape(value)}'`;
        if (reload) cmd += " && hyprctl reload";
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function setMany(entries: var, reload) {
        let args = ""
        for (let key in entries) {
            args += `--set '${StringUtils.shellSingleQuoteEscape(key)}' '${StringUtils.shellSingleQuoteEscape(entries[key])}' `
        }
        let cmd = `'${StringUtils.shellSingleQuoteEscape(root.configuratorScriptPath)}' --file '${StringUtils.shellSingleQuoteEscape(root.shellOverridesPath)}' ${args}`;
        if (reload) cmd += " && hyprctl reload";
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function reset(key: string, reload) {
        let cmd = `'${StringUtils.shellSingleQuoteEscape(root.configuratorScriptPath)}' --file '${StringUtils.shellSingleQuoteEscape(root.shellOverridesPath)}' --reset '${StringUtils.shellSingleQuoteEscape(key)}'`;
        if (reload) cmd += " && hyprctl reload";
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function resetMany(keys: list<string>, reload) {
        let args = ""
        for (let i = 0; i < keys.length; i++) {
            args += `--reset '${StringUtils.shellSingleQuoteEscape(keys[i])}' `
        }
        let cmd = `'${StringUtils.shellSingleQuoteEscape(root.configuratorScriptPath)}' --file '${StringUtils.shellSingleQuoteEscape(root.shellOverridesPath)}' ${args}`;
        if (reload) cmd += " && hyprctl reload";
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded()
            }
        }
    }
}
