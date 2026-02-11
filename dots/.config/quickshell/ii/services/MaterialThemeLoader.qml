pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    function generateDefaultTheme() {
        // Generate theme files using default wallpaper if they don't exist
        const defaultWallpaper = FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)
        console.log("Generating default theme files...")
        Quickshell.exec([Directories.wallpaperSwitchScriptPath, "--noswitch", defaultWallpaper])
        // Reload after generation
        Qt.callLater(() => themeFileView.reload())
    }

    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to CamelCase
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

	FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                console.warn("Theme file not found, generating defaults...")
                root.generateDefaultTheme()
            } else {
                root.resetFilePathNextTime()
            }
        }
    }
}
