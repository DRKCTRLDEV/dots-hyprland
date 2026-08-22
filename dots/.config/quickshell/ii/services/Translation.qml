pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property string sourceLanguage: "en_US"
    property var manifest: root.fallbackManifest()

    readonly property string defaultLanguage: root.manifest.defaultLanguage || root.sourceLanguage
    readonly property string translationsDir: Quickshell.shellPath("translations")
    readonly property string generatedTranslationsDir: FileUtils.trimFileProtocol(`${Directories.shellConfig}/translations`)

    readonly property var languages: root.manifest.languages
    readonly property var availableLanguages: root.manifest.languages.map(lang => lang.code)
    readonly property var languagesByEnglishName: root.languages.slice().sort((a, b) => a.englishName.localeCompare(b.englishName))

    function languageDisplayName(lang) {
        if (!lang) return "";
        if (lang.nativeName === lang.englishName || !lang.englishName) return lang.nativeName;
        return `${lang.nativeName} (${lang.englishName})`;
    }

    property var translations: ({})
    property var generatedTranslations: ({})
    property var effectiveTranslations: ({})

    onTranslationsChanged: root.rebuildEffectiveTranslations()
    onGeneratedTranslationsChanged: root.rebuildEffectiveTranslations()

    function rebuildEffectiveTranslations() {
        var merged = {};
        var k;
        for (k in root.translations)
            if (typeof root.translations[k] === "string" && root.translations[k] !== "")
                merged[k] = root.translations[k];
        for (k in root.generatedTranslations)
            if (typeof root.generatedTranslations[k] === "string" && root.generatedTranslations[k] !== "")
                merged[k] = root.generatedTranslations[k];
        root.effectiveTranslations = merged;
    }

    readonly property string languageCode: root.resolveLanguageCode()

    function normalizeCode(code) {
        if (!code) return "";
        var s = String(code).trim();
        if (s === "" || s === "C" || s === "POSIX") return "";
        s = s.replace(/-/g, "_").split(".")[0].split("@")[0];
        var parts = s.split("_");
        var lang = parts[0].toLowerCase();
        var region = parts.length > 1 ? parts[1].toUpperCase() : "";
        if (!/^[a-z]{2,3}$/.test(lang)) return "";
        return region ? lang + "_" + region : lang;
    }

    function resolveLanguage(preferred, localeName) {
        var supported = {};
        for (var i = 0; i < root.languages.length; i++)
            supported[root.languages[i].code] = true;

        if (preferred && preferred !== "auto") {
            var norm = root.normalizeCode(preferred);
            if (norm && supported[norm]) return norm;
        }

        var locale = root.normalizeCode(localeName);
        if (locale && supported[locale]) return locale;

        if (locale) {
            var family = locale.split("_")[0];
            var famMap = root.manifest.familyFallbacks || {};
            if (famMap[family] && supported[famMap[family]]) return famMap[family];
        }

        return supported[root.defaultLanguage] ? root.defaultLanguage : root.sourceLanguage;
    }

    function resolveLanguageCode() {
        var env = Quickshell.env("II_UI_LANG");
        if (env) return root.resolveLanguage(env, Qt.locale().name);

        var configLang = Config?.options?.language?.ui ?? "auto";
        if (configLang !== "auto") return root.resolveLanguage(configLang, Qt.locale().name);

        return root.resolveLanguage("auto", Qt.locale().name);
    }

    function tr(text) {
        if (text === null || text === undefined) return "";
        const key = String(text);
        if (key === "") return "";
        const value = root.effectiveTranslations[key];
        return (typeof value === "string" && value !== "") ? value : key;
    }

    function hasNoPlurals(code) {
        return ["ja", "zh", "tr", "vi", "id", "ko", "th"].indexOf(code.split("_")[0]) !== -1;
    }

    function trPlural(singular, plural, count) {
        if (singular === null || singular === undefined) return "";
        if (plural === null || plural === undefined) plural = singular;
        const n = Number(count) || 0;
        const useSingular = n === 1 || (root.languageCode.split("_")[0] === "fr" && n === 0);
        const key = (!root.hasNoPlurals(root.languageCode) && useSingular) ? singular : plural;
        const value = root.effectiveTranslations[key];
        return (typeof value === "string" && value !== "") ? value : key;
    }

    property var perf: ({ manifestMs: 0, manifestBytes: 0, languageMs: 0, languageBytes: 0 })

    onLanguageCodeChanged: root.loadLanguage(root.languageCode)
    Component.onCompleted: root.loadLanguage(root.languageCode)

    function loadLanguage(code) {
        if (code !== root.sourceLanguage) {
            const path = `${root.translationsDir}/${code}.json`;
            if (languageFileView.path === path)
                languageFileView.reload();
            else
                languageFileView.path = path;
        } else {
            root.translations = {};
        }
        const overlayPath = `${root.generatedTranslationsDir}/${code}.json`;
        if (generatedFileView.path === overlayPath)
            generatedFileView.reload();
        else
            generatedFileView.path = overlayPath;
    }

    function fallbackManifest() {
        return {
            version: 1,
            sourceLanguage: root.sourceLanguage,
            defaultLanguage: root.sourceLanguage,
            languages: [{ code: root.sourceLanguage, nativeName: "English (US)", englishName: "English (US)" }],
            familyFallbacks: { en: root.sourceLanguage },
        };
    }

    FileView {
        id: manifestFileView
        path: `${root.translationsDir}/manifest.json`

        onLoaded: {
            const start = Date.now();
            try {
                const data = JSON.parse(text());
                if (data && Array.isArray(data.languages) && data.languages.length > 0) {
                    root.manifest = data;
                    root.perf.manifestMs = Date.now() - start;
                    root.perf.manifestBytes = text().length;
                }
            } catch (e) {
                console.log("[Translation] Failed to parse manifest.json:", e);
            }
        }
    }

    FileView {
        id: languageFileView

        onLoaded: {
            const start = Date.now();
            try {
                const data = JSON.parse(text());
                root.translations = (data && typeof data === "object") ? data : {};
                root.perf.languageMs = Date.now() - start;
                root.perf.languageBytes = text().length;
            } catch (e) {
                console.log("[Translation] Failed to parse language file:", e);
                root.translations = {};
            }
        }
        onLoadFailed: {
            console.log("[Translation] No translation file for", root.languageCode, "— falling back to English.");
            root.translations = {};
        }
    }

    FileView {
        id: generatedFileView

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.generatedTranslations = (data && typeof data === "object") ? data : {};
            } catch (e) {
                console.log("[Translation] Failed to parse overlay file:", e);
                root.generatedTranslations = {};
            }
        }
        onLoadFailed: {
            root.generatedTranslations = {};
        }
    }
}
