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
 * Handles device detection, sensitivity presets, polling rate, and button bindings.
 */
Singleton {
    id: root

    // State properties
    property bool loading: true
    property bool available: false
    property string errorMessage: ""

    // Device info
    property string deviceName: ""
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

    // Config file path - use home directory to avoid file:// prefix issues
    readonly property string configDir: FileUtils.trimFileProtocol(Directories.config) + "/rivalcfg"
    readonly property string configFile: configDir + "/current_settings.json"

    // Signals for UI feedback
    signal settingsApplied()
    signal settingsError(string error)

    Component.onCompleted: {
        refresh()
    }

    function refresh() {
        root.loading = true
        root.errorMessage = ""
        ensureConfigDirProc.running = true
    }

    function setSensitivity(presets: var) {
        root.sensitivityPresets = presets
        applySensitivityProc.running = true
    }

    function setPollingRate(rate: int) {
        root.pollingRate = rate
        applyPollingRateProc.running = true
    }

    function setButtonBinding(button: string, action: string) {
        let newBindings = Object.assign({}, root.buttonBindings)
        newBindings[button] = action
        root.buttonBindings = newBindings
        applyButtonBindings()
    }

    function applyButtonBindings() {
        // Build the full buttons mapping string for rivalcfg
        // Format: buttons(button1=action1; button2=action2; ...)
        let mappings = []
        for (let button in root.buttonBindings) {
            mappings.push(`${button}=${root.buttonBindings[button]}`)
        }
        if (mappings.length > 0) {
            applyButtonBindingProc.buttonArg = `buttons(${mappings.join("; ")})`
            applyButtonBindingProc.running = true
        }
    }

    function resetToDefaults() {
        resetProc.running = true
    }

    // Ensure config directory exists
    Process {
        id: ensureConfigDirProc
        command: ["bash", "-c", `mkdir -p "${root.configDir}" && echo "ok"`]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                detectMouseProc.running = true
            } else {
                root.loading = false
                root.available = false
                root.errorMessage = Translation.tr("Failed to create config directory")
            }
        }
    }

    // Detect connected SteelSeries mouse using rivalcfg
    Process {
        id: detectMouseProc
        command: ["rivalcfg", "--print-debug"]
        stdout: SplitParser {
            onRead: data => {
                detectMouseProc.debugOutput += data + "\n"
            }
        }
        stderr: SplitParser {
            onRead: data => {
                detectMouseProc.debugOutput += data + "\n"
            }
        }
        property string debugOutput: ""
        onExited: (exitCode, exitStatus) => {
            // Check for device in PLUGGED STEELSERIES DEVICES ENDPOINTS section
            // Format: "1038:1852| 00 | SteelSeries Aerox 5 Wireless (firmware"
            const hasSteelSeriesSection = detectMouseProc.debugOutput.includes("PLUGGED STEELSERIES DEVICES")
            const hasDeviceLine = /\b1038:[0-9a-f]{4}\b.*SteelSeries/i.test(detectMouseProc.debugOutput)
            const hasDevice = (hasSteelSeriesSection && /\b1038:[0-9a-f]{4}\b/i.test(detectMouseProc.debugOutput)) || hasDeviceLine

            if (hasDevice) {
                // Parse device info from debug output
                parseDeviceInfo(detectMouseProc.debugOutput)
                root.available = true
                // Query help to get available buttons
                queryHelpProc.running = true
            } else {
                root.loading = false
                root.available = false
                if (detectMouseProc.debugOutput.includes("PLUGGED STEELSERIES DEVICES ENDPOINTS") && 
                    !hasDevice) {
                    root.errorMessage = Translation.tr("No SteelSeries mouse detected.\nMake sure your mouse is connected.")
                } else if (detectMouseProc.debugOutput.includes("rivalcfg: command not found") || 
                           detectMouseProc.debugOutput.includes("rivalcfg: not found") ||
                           detectMouseProc.debugOutput.includes("No module named")) {
                    root.errorMessage = Translation.tr("rivalcfg is not installed.\\nInstall with: paru -S rivalcfg")
                } else {
                    root.errorMessage = Translation.tr("Failed to detect mouse.\n") + detectMouseProc.debugOutput.substring(0, 500)
                }
            }
            detectMouseProc.debugOutput = ""
        }
    }

    function parseDeviceInfo(output: string) {
        // Parse device name from PLUGGED STEELSERIES DEVICES ENDPOINTS section
        // Format: "1038:1852| 00 | SteelSeries Aerox 5 Wireless (firmware"
        const deviceMatch = output.match(/\d{4}:\d{4}\|[^|]+\|\s*([^(\n]+)/)
        if (deviceMatch) {
            root.deviceName = deviceMatch[1].trim()
        }

        // Determine connection type based on device name or USB info
        if (output.toLowerCase().includes("wireless") || output.toLowerCase().includes("2.4ghz")) {
            root.connectionType = "wireless"
        } else if (output.toLowerCase().includes("bluetooth")) {
            root.connectionType = "bluetooth"
        } else {
            root.connectionType = "wired"
        }

        // Check for battery support
        root.hasBattery = output.toLowerCase().includes("battery")
    }

    // Query rivalcfg --help to get available buttons for this device
    Process {
        id: queryHelpProc
        command: ["rivalcfg", "--help"]
        stdout: SplitParser {
            onRead: data => {
                queryHelpProc.helpOutput += data + "\n"
            }
        }
        property string helpOutput: ""
        onExited: (exitCode, exitStatus) => {
            // Parse buttons from --buttons help text
            // Format: "buttons(button1=button1; button2=button2; ...)"
            const buttonsMatch = queryHelpProc.helpOutput.match(/buttons\(([^)]+)\)/i)
            if (buttonsMatch) {
                const buttonsPart = buttonsMatch[1]
                // Extract button names (keys before =)
                const buttonPairs = buttonsPart.split(";")
                let buttons = []
                buttonPairs.forEach(pair => {
                    const trimmed = pair.trim()
                    const eqIdx = trimmed.indexOf("=")
                    if (eqIdx > 0) {
                        const btnName = trimmed.substring(0, eqIdx).trim()
                        // Filter out non-button entries like scrollup, scrolldown, layout
                        if (btnName.startsWith("button") && !buttons.includes(btnName)) {
                            buttons.push(btnName)
                        }
                    }
                })
                if (buttons.length > 0) {
                    root.availableButtons = buttons
                }
            }
            
            // If no buttons found, provide sensible defaults
            if (root.availableButtons.length === 0) {
                root.availableButtons = ["button1", "button2", "button3", "button4", "button5", "button6"]
            }
            
            queryHelpProc.helpOutput = ""
            // Now read saved settings
            readCurrentSettingsProc.running = true
        }
    }

    // Read current settings from rivalcfg or saved config
    Process {
        id: readCurrentSettingsProc
        command: ["bash", "-c", `cat "${root.configFile}" 2>/dev/null || echo "{}"`]
        stdout: SplitParser {
            onRead: data => {
                readCurrentSettingsProc.configData += data
            }
        }
        property string configData: ""
        onExited: (exitCode, exitStatus) => {
            try {
                const config = JSON.parse(readCurrentSettingsProc.configData || "{}")
                if (config.sensitivityPresets && Array.isArray(config.sensitivityPresets)) {
                    root.sensitivityPresets = config.sensitivityPresets
                }
                if (config.pollingRate) {
                    root.pollingRate = config.pollingRate
                }
                if (config.buttonBindings) {
                    root.buttonBindings = config.buttonBindings
                }
            } catch (e) {
                console.warn("RivalCfg: Failed to parse config:", e)
            }
            readCurrentSettingsProc.configData = ""
            root.loading = false

            // If we have battery support, check battery level
            if (root.hasBattery) {
                checkBatteryProc.running = true
            }
        }
    }

    // Check battery level
    Process {
        id: checkBatteryProc
        command: ["rivalcfg", "--battery-level"]
        stdout: SplitParser {
            onRead: data => {
                checkBatteryProc.batteryOutput += data
            }
        }
        property string batteryOutput: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                const match = checkBatteryProc.batteryOutput.match(/(\d+)/)
                if (match) {
                    root.batteryLevel = parseInt(match[1])
                }
                root.isCharging = checkBatteryProc.batteryOutput.toLowerCase().includes("charging")
            }
            checkBatteryProc.batteryOutput = ""
        }
    }

    // Apply sensitivity settings
    Process {
        id: applySensitivityProc
        property string dpiArgs: root.sensitivityPresets.join(",")
        command: ["rivalcfg", "--sensitivity", dpiArgs]
        stdout: SplitParser {
            onRead: data => {
                applySensitivityProc.output += data + "\n"
            }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                saveCurrentSettings()
                root.settingsApplied()
            } else {
                root.settingsError(Translation.tr("Failed to apply sensitivity settings"))
            }
            applySensitivityProc.output = ""
        }
    }

    // Apply polling rate
    Process {
        id: applyPollingRateProc
        command: ["rivalcfg", "--polling-rate", root.pollingRate.toString()]
        stdout: SplitParser {
            onRead: data => {
                applyPollingRateProc.output += data + "\n"
            }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                saveCurrentSettings()
                root.settingsApplied()
            } else {
                root.settingsError(Translation.tr("Failed to apply polling rate"))
            }
            applyPollingRateProc.output = ""
        }
    }

    // Apply button binding
    Process {
        id: applyButtonBindingProc
        property string buttonArg: ""
        command: ["rivalcfg", "--buttons", buttonArg]
        stdout: SplitParser {
            onRead: data => {
                applyButtonBindingProc.output += data + "\n"
            }
        }
        stderr: SplitParser {
            onRead: data => {
                applyButtonBindingProc.output += data + "\n"
            }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && !applyButtonBindingProc.output.toLowerCase().includes("error")) {
                saveCurrentSettings()
                root.settingsApplied()
            } else {
                root.settingsError(Translation.tr("Failed to apply button binding: ") + applyButtonBindingProc.output)
            }
            applyButtonBindingProc.output = ""
        }
    }

    // Reset to defaults
    Process {
        id: resetProc
        command: ["rivalcfg", "--reset"]
        stdout: SplitParser {
            onRead: data => {
                resetProc.output += data + "\n"
            }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Clear saved config and reload defaults from device
                root.buttonBindings = {}
                clearConfigProc.running = true
            } else {
                root.settingsError(Translation.tr("Failed to reset settings"))
            }
            resetProc.output = ""
        }
    }

    // Clear config file after reset, then reload device defaults
    Process {
        id: clearConfigProc
        command: ["bash", "-c", `rm -f "${root.configFile}"`]
        onExited: (exitCode, exitStatus) => {
            // Query device for actual default values after reset
            queryDefaultsProc.running = true
        }
    }

    // Query device defaults after reset
    Process {
        id: queryDefaultsProc
        command: ["rivalcfg", "--print-debug"]
        stdout: SplitParser {
            onRead: data => {
                queryDefaultsProc.output += data + "\n"
            }
        }
        property string output: ""
        onExited: (exitCode, exitStatus) => {
            // Parse default sensitivity and polling rate from debug output
            const sensMatch = queryDefaultsProc.output.match(/sensitivity\d*.*?default:\s*([\d,]+)/i)
            if (sensMatch) {
                const defaultSens = sensMatch[1].split(",").map(s => parseInt(s.trim())).filter(n => !isNaN(n))
                if (defaultSens.length > 0) {
                    root.sensitivityPresets = defaultSens
                } else {
                    root.sensitivityPresets = [800, 1600, 3200]
                }
            } else {
                root.sensitivityPresets = [800, 1600, 3200]
            }

            const pollMatch = queryDefaultsProc.output.match(/polling[_-]?rate.*?default:\s*(\d+)/i)
            if (pollMatch) {
                root.pollingRate = parseInt(pollMatch[1])
            } else {
                root.pollingRate = 1000
            }

            queryDefaultsProc.output = ""
            saveCurrentSettings()
            root.settingsApplied()
        }
    }

    // Save current settings to file
    Process {
        id: saveSettingsProc
        property string configJson: ""
        command: ["bash", "-c", `echo '${configJson}' > "${root.configFile}"`]
    }

    function saveCurrentSettings() {
        const config = {
            sensitivityPresets: root.sensitivityPresets,
            pollingRate: root.pollingRate,
            buttonBindings: root.buttonBindings
        }
        saveSettingsProc.configJson = JSON.stringify(config, null, 2)
        saveSettingsProc.running = true
    }

    // Periodic battery check timer (if battery supported)
    Timer {
        interval: 60000 // Check every minute
        running: root.available && root.hasBattery
        repeat: true
        onTriggered: checkBatteryProc.running = true
    }
}
