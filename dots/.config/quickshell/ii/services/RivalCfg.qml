pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service for interfacing with rivalcfg to configure SteelSeries mice.
 * Uses Python API via wrapper script for more reliable operation.
 * Handles device detection, sensitivity presets, polling rate, and button bindings.
 */
Singleton {
    id: root

    // Active state - when false, no processes run (saves resources when sidebar closed)
    property bool active: false
    
    // State properties
    property bool loading: true
    property bool available: false
    property string errorMessage: ""

    // Device info
    property string deviceName: ""
    property string devicePid: "" // e.g., "1038_1852"
    property string connectionType: "" // "wired", "wireless", "bluetooth"

    // Battery info
    property bool hasBattery: false
    property int batteryLevel: 100
    property bool isCharging: false

    // Configuration
    property var sensitivityPresets: [800, 1600, 3200]
    property int pollingRate: 1000
    property var buttonBindings: ({})
    property var availableButtons: []

    // Capabilities from device profile
    property bool hasSensitivity: false
    property bool hasPollingRate: false
    property bool hasButtons: false
    property var sensitivityRange: ({ "min": 100, "max": 18000 })
    property var pollingRates: [125, 250, 500, 1000]

    // Python wrapper script path
    readonly property string scriptDir: Qt.resolvedUrl("../scripts/rivalcfg").toString().replace("file://", "")
    readonly property string wrapperScript: scriptDir + "/rivalcfg_wrapper.py"

    // Signals for UI feedback
    signal settingsApplied()
    signal settingsError(string error)

    // Only refresh when activated, not on Component.onCompleted
    onActiveChanged: {
        if (active) {
            refresh()
        } else {
            batteryTimer.running = false
        }
    }

    function refresh() {
        if (!root.active) return; // Don't refresh if not active
        root.loading = true
        root.errorMessage = ""
        detectProc.running = true
    }

    function setSensitivity(presets: var) {
        root.sensitivityPresets = presets
        sensitivityProc.presetArg = presets.join(",")
        sensitivityProc.running = true
    }

    function setPollingRate(rate: int) {
        root.pollingRate = rate
        pollingRateProc.running = true
    }

    function setButtonBinding(button: string, action: string) {
        let newBindings = Object.assign({}, root.buttonBindings)
        newBindings[button] = action
        root.buttonBindings = newBindings
        applyButtonBindings()
    }

    function applyButtonBindings() {
        let mappedBindings = {}
        for (let button in root.buttonBindings) {
            const action = root.buttonBindings[button]
            mappedBindings[button] = mapKeyToRivalcfgAlias(action)
        }
        buttonsProc.mappingsArg = JSON.stringify(mappedBindings)
        buttonsProc.running = true
    }

    function mapKeyToRivalcfgAlias(key: string): string {
        // Map special characters that conflict with rivalcfg syntax to their aliases
        // Also map generic modifier names to rivalcfg format
        const keyAliases = {
            // Characters that conflict with syntax
            ";": "semicolon",
            "'": "quote",
            ",": "comma",
            ".": "dot",
            "/": "slash",
            "\\": "backslash",
            "[": "leftbracket",
            "]": "rightbracket",
            "`": "backtick",
            "-": "dash",
            "=": "equal",
            "#": "hash",
            
            // Generic modifier names to rivalcfg format
            "Shift": "LeftShift",
            "Ctrl": "LeftCtrl",
            "Alt": "LeftAlt",
            
            // Already correct format (pass through)
            "LeftShift": "LeftShift",
            "RightShift": "RightShift",
            "LeftCtrl": "LeftCtrl",
            "RightCtrl": "RightCtrl",
            "LeftAlt": "LeftAlt",
            "RightAlt": "RightAlt",
            "LeftSuper": "LeftSuper",
            "RightSuper": "RightSuper",
            
            // Lowercase variants (legacy support)
            "lalt": "LeftAlt",
            "ralt": "RightAlt",
            "lctrl": "LeftCtrl",
            "rctrl": "RightCtrl",
            "lshift": "LeftShift",
            "rshift": "RightShift",
            "lmeta": "LeftMeta",
            "rmeta": "RightMeta"
        }
        
        return keyAliases[key] || key
    }

    function resetToDefaults() {
        resetProc.running = true
    }

    // Detect mouse using Python wrapper
    Process {
        id: detectProc
        command: [root.wrapperScript, "detect"]
        stdout: SplitParser {
            onRead: data => detectProc.output += data
        }
        stderr: SplitParser {
            onRead: data => { if (data.trim()) console.warn("[RivalCfg]", data) }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(detectProc.output)
                
                if (result.available) {
                    root.available = true
                    root.deviceName = result.device.name || ""
                    root.devicePid = result.device.pid || ""
                    root.connectionType = result.device.connection_type || "unknown"
                    
                    // Battery info
                    root.hasBattery = result.battery.supported || false
                    root.batteryLevel = result.battery.level || 100
                    root.isCharging = result.battery.is_charging || false
                    
                    // Capabilities
                    root.hasSensitivity = result.capabilities.has_sensitivity || false
                    root.hasPollingRate = result.capabilities.has_polling_rate || false
                    root.hasButtons = result.capabilities.has_buttons || false
                    root.availableButtons = result.capabilities.buttons || []
                    root.sensitivityRange = result.capabilities.sensitivity_range || { "min": 100, "max": 18000 }
                    root.pollingRates = result.capabilities.polling_rates || [125, 250, 500, 1000]
                    
                    // Ensure we have default buttons if none detected
                    if (root.availableButtons.length === 0) {
                        root.availableButtons = ["Button1", "Button2", "Button3", "Button4", "Button5", "Button6", "Button7", "Button8", "Button9"]
                    }
                    
                    // Load saved settings
                    settingsProc.running = true
                } else {
                    root.available = false
                    root.errorMessage = result.error || Translation.tr("No SteelSeries mouse detected.\nMake sure your mouse is connected.")
                    root.loading = false
                }
            } catch (e) {
                console.error("[RivalCfg] Failed to parse detect output:", e)
                root.available = false
                root.errorMessage = Translation.tr("Failed to detect mouse. Check if rivalcfg is installed in the Python environment.")
                root.loading = false
            }
            
            detectProc.output = ""
        }
    }

    // Get current settings
    Process {
        id: settingsProc
        command: [root.wrapperScript, "settings"]
        stdout: SplitParser {
            onRead: data => settingsProc.output += data
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(settingsProc.output)
                if (result.success && result.settings) {
                    if (result.settings.sensitivity && result.settings.sensitivity.length > 0) {
                        root.sensitivityPresets = result.settings.sensitivity
                    }
                    if (result.settings.polling_rate) {
                        root.pollingRate = result.settings.polling_rate
                    }
                    if (result.settings.buttons) {
                        root.buttonBindings = result.settings.buttons
                    }
                }
            } catch (e) {
                console.error("[RivalCfg] Failed to parse settings:", e)
            }
            
            settingsProc.output = ""
            root.loading = false
            
            // Start battery monitoring if supported
            if (root.hasBattery) {
                batteryProc.running = true
            }
        }
    }

    // Battery check
    Process {
        id: batteryProc
        command: [root.wrapperScript, "battery"]
        stdout: SplitParser {
            onRead: data => batteryProc.output += data
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(batteryProc.output)
                if (result.supported) {
                    root.hasBattery = true
                    root.batteryLevel = result.level || 100
                    root.isCharging = result.is_charging || false
                }
            } catch (e) {
                console.error("[RivalCfg] Failed to parse battery:", e)
            }
            batteryProc.output = ""
        }
    }

    // Set sensitivity
    Process {
        id: sensitivityProc
        property string presetArg: ""
        command: [root.wrapperScript, "sensitivity", presetArg]
        stdout: SplitParser {
            onRead: data => sensitivityProc.output += data
        }
        stderr: SplitParser {
            onRead: data => { if (data.trim()) console.warn("[RivalCfg]", data) }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(sensitivityProc.output)
                if (result.success) {
                    root.settingsApplied()
                } else {
                    root.settingsError(result.error || Translation.tr("Failed to apply sensitivity settings"))
                }
            } catch (e) {
                root.settingsError(Translation.tr("Failed to apply sensitivity settings"))
            }
            sensitivityProc.output = ""
        }
    }

    // Set polling rate
    Process {
        id: pollingRateProc
        command: [root.wrapperScript, "polling-rate", root.pollingRate.toString()]
        stdout: SplitParser {
            onRead: data => pollingRateProc.output += data
        }
        stderr: SplitParser {
            onRead: data => { if (data.trim()) console.warn("[RivalCfg]", data) }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(pollingRateProc.output)
                if (result.success) {
                    root.settingsApplied()
                } else {
                    root.settingsError(result.error || Translation.tr("Failed to apply polling rate"))
                }
            } catch (e) {
                root.settingsError(Translation.tr("Failed to apply polling rate"))
            }
            pollingRateProc.output = ""
        }
    }

    // Set button mappings
    Process {
        id: buttonsProc
        property string mappingsArg: "{}"
        command: [root.wrapperScript, "buttons", mappingsArg]
        stdout: SplitParser {
            onRead: data => buttonsProc.output += data
        }
        stderr: SplitParser {
            onRead: data => { if (data.trim()) console.warn("[RivalCfg]", data) }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(buttonsProc.output)
                if (result.success) {
                    root.settingsApplied()
                } else {
                    root.settingsError(result.error || Translation.tr("Failed to apply button binding"))
                }
            } catch (e) {
                root.settingsError(Translation.tr("Failed to apply button binding"))
            }
            buttonsProc.output = ""
        }
    }

    // Reset to defaults
    Process {
        id: resetProc
        command: [root.wrapperScript, "reset"]
        stdout: SplitParser {
            onRead: data => resetProc.output += data
        }
        stderr: SplitParser {
            onRead: data => { if (data.trim()) console.warn("[RivalCfg]", data) }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const result = JSON.parse(resetProc.output)
                if (result.success) {
                    // Reload settings after reset
                    root.buttonBindings = {}
                    root.sensitivityPresets = [800, 1600, 3200]
                    root.pollingRate = 1000
                    root.settingsApplied()
                } else {
                    root.settingsError(result.error || Translation.tr("Failed to reset settings"))
                }
            } catch (e) {
                root.settingsError(Translation.tr("Failed to reset settings"))
            }
            resetProc.output = ""
        }
    }

    // Periodic battery check timer (if battery supported)
    // Checks more frequently since service only runs when sidebar is open
    Timer {
        id: batteryTimer
        interval: 10000 // Check every 10 seconds
        running: root.active && root.available && root.hasBattery
        repeat: true
        onTriggered: batteryProc.running = true
    }
}
