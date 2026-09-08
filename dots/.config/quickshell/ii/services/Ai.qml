pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions as CF
import qs.modules.common
import qs.modules.common.utils
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.services.ai

Singleton {
    id: root

    property Component aiMessageComponent: AiMessageData {}
    property Component aiModelComponent: AiModel {}
    property Component geminiApiStrategy: GeminiApiStrategy {}
    property Component openaiApiStrategy: OpenAiApiStrategy {}
    property Component mistralApiStrategy: MistralApiStrategy {}
    readonly property string interfaceRole: "interface"
    readonly property string apiKeyEnvVarName: "API_KEY"

    signal responseFinished

    property string systemPrompt: {
        let prompt = Config.options?.ai?.systemPrompt ?? "";
        for (let key in root.promptSubstitutions) {
            prompt = prompt.split(key).join(root.promptSubstitutions[key]);
        }
        return prompt;
    }
    property var messageIDs: []
    property var messageByID: ({})
    readonly property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}
    readonly property var apiKeysLoaded: KeyringStorage.loaded
    readonly property bool currentModelHasApiKey: {
        const model = models[currentModelId];
        if (!model || !model.requires_key)
            return true;
        if (!apiKeysLoaded)
            return false;
        const key = apiKeys[model.key_id];
        return (key?.length > 0);
    }
    property var postResponseHook
    property real temperature: Persistent.states?.ai?.temperature ?? 0.5
    property QtObject tokenCount: QtObject {
        property int input: -1
        property int output: -1
        property int total: -1
    }

    function idForMessage(message) {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 8);
    }

    function safeModelName(modelName) {
        return modelName.replace(/:/g, "_").replace(/ /g, "-").replace(/\//g, "-");
    }

    function registerMessage(msg) {
        const id = idForMessage(msg);
        root.messageIDs = [...root.messageIDs, id];
        root.messageByID[id] = msg;
        return id;
    }

    property list<var> defaultPrompts: []
    property list<var> userPrompts: []
    property list<var> savedChats: []

    function getPromptFiles() {
        return root.promptFiles;
    }

    property var promptSubstitutions: {
        "{DISTRO}": SystemInfo.distroName,
        "{DATETIME}": `${DateTime.time}, ${DateTime.collapsedCalendarFormat}`,
        "{WINDOWCLASS}": ToplevelManager.activeToplevel?.appId ?? "Unknown",
        "{DE}": `${SystemInfo.desktopEnvironment} (${SystemInfo.windowingSystem})`
    }


    property string currentTool: "functions"
    property string currentEffort: "none" // Reasoning effort for duck.ai models (ai.duckAi.effort)
    property var _apiFunctions: [
        {
            "type": "function",
            "function": {
                "name": "get_shell_config",
                "description": "Get the desktop shell config file contents",
                "parameters": {
                    "type": "object",
                    "properties": {}
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "set_shell_config",
                "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "key": {
                            "type": "string",
                            "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting."
                        },
                        "value": {
                            "type": "string",
                            "description": "The value to set, e.g. `true`"
                        }
                    },
                    "required": ["key", "value"]
                }
            }
        },
        {
            "type": "function",
            "function": {
                "name": "run_shell_command",
                "description": "Run a shell command in bash and get its output. Use this only for quick commands that don't require user interaction. For commands that require interaction, ask the user to run manually instead.",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "command": {
                            "type": "string",
                            "description": "The bash command to run"
                        }
                    },
                    "required": ["command"]
                }
            }
        },
    ]
    property var tools: {
        "gemini": {
            "functions": [
                {
                    "functionDeclarations": [
                        {
                            "name": "switch_to_search_mode",
                            "description": "Search the web"
                        },
                        {
                            "name": "get_shell_config",
                            "description": "Get the desktop shell config file contents"
                        },
                        {
                            "name": "set_shell_config",
                            "description": "Set a field in the desktop graphical shell config file. Must only be used after `get_shell_config`.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "key": {
                                        "type": "string",
                                        "description": "The key to set, e.g. `bar.borderless`. MUST NOT BE GUESSED, use `get_shell_config` to see what keys are available before setting."
                                    },
                                    "value": {
                                        "type": "string",
                                        "description": "The value to set, e.g. `true`"
                                    }
                                },
                                "required": ["key", "value"]
                            }
                        },
                        {
                            "name": "run_shell_command",
                            "description": "Run a shell command in bash and get its output. Use this only for quick commands that don't require user interaction. For commands that require interaction, ask the user to run manually instead.",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "command": {
                                        "type": "string",
                                        "description": "The bash command to run"
                                    }
                                },
                                "required": ["command"]
                            }
                        },
                    ]
                }
            ],
            "search": [
                {
                    "google_search": {}
                }
            ],
            "none": []
        },
        "openai": {
            "functions": root._apiFunctions,
            "search": [],
            "none": []
        },
        "mistral": {
            "functions": root._apiFunctions,
            "search": [],
            "none": []
        },
        "duckai": {
            "search": [
                {
                    "type": "web_search",
                    "web_search": {}
                }
            ],
            "none": []
        }
    }
    function allowedTools(model) {
        const format = model?.api_format;
        if (!format || !root.tools[format]) return [];
        const list = [];
        const functionsList = root.tools[format]?.functions;
        if (Array.isArray(functionsList) && functionsList.length > 0) list.push("functions");
        list.push("search");
        list.push("none");
        return list;
    }
    function getAvailableTools() {
        return root.allowedTools(root.models[root.currentModelId]);
    }

    function nativeSearchPayload(model) {
        if (!model) return null;
        if (model.api_format === "gemini") {
            const list = root.tools?.gemini?.search;
            return (Array.isArray(list) && list.length > 0) ? list : null;
        }
        if (model.api_format === "duckai") {
            if (model.webSearchSupported !== true) return null;
            const list = root.tools?.duckai?.search;
            return (Array.isArray(list) && list.length > 0) ? list : null;
        }
        return null;
    }
    property var toolDescriptions: {
        "functions": Translation.tr("Commands, edit configs, search"),
        "search": Translation.tr("Search the web"),
        "none": Translation.tr("Disable tools")
    }

    property var models: Config.options.policies.ai === 2 ? {} : {
        "gemini-2.5-flash": aiModelComponent.createObject(this, {
            "name": "Gemini 2.5 Flash",
            "icon": "google-gemini-symbolic",
            "description": Translation.tr("Online | Google's model\nNewer model that's slower than its predecessor but should deliver higher quality answers"),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent",
            "model": "gemini-2.5-flash",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": Translation.tr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "gemini-3-flash": aiModelComponent.createObject(this, {
            "name": "Gemini 3 Flash",
            "icon": "google-gemini-symbolic",
            "description": Translation.tr("Online | Google's model\nPro-level intelligence at the speed and pricing of Flash."),
            "homepage": "https://aistudio.google.com",
            "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:streamGenerateContent",
            "model": "gemini-3-flash-preview",
            "requires_key": true,
            "key_id": "gemini",
            "key_get_link": "https://aistudio.google.com/app/apikey",
            "key_get_description": Translation.tr("**Pricing**: free. Data used for training.\n\n**Instructions**: Log into Google account, allow AI Studio to create Google Cloud project or whatever it asks, go back and click Get API key"),
            "api_format": "gemini"
        }),
        "mistral-medium-3": aiModelComponent.createObject(this, {
            "name": "Mistral Medium 3",
            "icon": "mistral-symbolic",
            "description": Translation.tr("Online | %1's model | Delivers fast, responsive and well-formatted answers. Disadvantages: not very eager to do stuff; might make up unknown function calls").arg("Mistral"),
            "homepage": "https://mistral.ai/news/mistral-medium-3",
            "endpoint": "https://api.mistral.ai/v1/chat/completions",
            "model": "mistral-medium-2505",
            "requires_key": true,
            "imageUploadSupported": true, // Mistral Medium 3 is multimodal (text + vision)
            "key_id": "mistral",
            "key_get_link": "https://console.mistral.ai/api-keys",
            "key_get_description": Translation.tr("**Instructions**: Log into Mistral account, go to Keys on the sidebar, click Create new key"),
            "api_format": "mistral"
        })
    }
    property var modelList: Object.keys(root.models).filter(id => !root.isModelDisabled(id))

    function isModelDisabled(modelId) {
        return (Config?.options?.ai?.disabledModels ?? []).indexOf(modelId) !== -1;
    }

    property var currentModelId: {
        const remembered = Persistent.states?.ai?.model;
        if (remembered && root.models[remembered] && !root.isModelDisabled(remembered))
            return remembered;
        return root.modelList[0] ?? "";
    }

    property var apiStrategies: {
        "openai": openaiApiStrategy.createObject(this),
        "gemini": geminiApiStrategy.createObject(this),
        "mistral": mistralApiStrategy.createObject(this),
        "duckai": openaiApiStrategy.createObject(this)
    }
    property ApiStrategy currentApiStrategy: apiStrategies[models[currentModelId]?.api_format || "openai"]

    function isLocalEndpoint(endpoint) {
        const url = String(endpoint ?? "");
        return url.includes("localhost") || url.includes("127.0.0.1");
    }

    function addUserModels() {
        (Config?.options.ai?.extraModels ?? []).forEach(model => {
            if (Config.options.policies.ai === 2 && !root.isLocalEndpoint(model["endpoint"]))
                return;
            const safeModelName = root.safeModelName(model["model"]);
            root.addModel(safeModelName, model);
        });
    }

    property bool noModelsNoticeShown: false

    function warnNoModels() {
        if (root.noModelsNoticeShown || root.modelList.length > 0)
            return;
        root.noModelsNoticeShown = true;
        if (Config.options.policies.ai === 2) {
            root.addMessage(Translation.tr("Local-only mode: no local models found.\n\nStart Ollama, or add a custom model with a localhost endpoint. Online models stay hidden while this policy is active."), root.interfaceRole);
        } else {
            root.addMessage(Translation.tr("No models available — start Ollama or add a custom model to your config."), root.interfaceRole);
        }
    }

    Timer {
        id: noModelsFallbackTimer
        interval: 2000
        repeat: false
        onTriggered: root.warnNoModels()
    }

    function maybeWarnNoModelsLater() {
        if (getOllamaModels.running || duckAiDiscovery.running)
            return;
        noModelsFallbackTimer.start();
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready)
                return;
            root.currentTool = Config?.options?.ai?.tool ?? "functions";
            root.currentEffort = Config?.options?.ai?.duckAi?.effort ?? "none";
            root.addUserModels();
            root.maybeStartOllamaDiscovery();
            root.maybeStartDuckAiDiscovery();
            root.maybeWarnNoModelsLater();
        }
    }

    property string requestScriptFilePath: "/tmp/quickshell/ai/request.sh"
    property string pendingFilePath: ""
    property var requestAnchorMessage: null
    property bool attachConverting: false

    Component.onCompleted: {
        setModel(currentModelId, false, false);
        root.addUserModels();
        root.currentTool = Config?.options?.ai?.tool ?? "functions";
        root.currentEffort = Config?.options?.ai?.duckAi?.effort ?? "none";
        if (root.temperature < 0 || root.temperature > 1) {
            root.temperature = Math.max(0, Math.min(1, root.temperature));
            Persistent.states.ai.temperature = root.temperature;
        }
        root.maybeStartOllamaDiscovery();
        root.maybeStartDuckAiDiscovery();
    }

    function guessModelLogo(model) {
        if (model.includes("llama"))
            return "ollama-symbolic";
        if (model.includes("gemma"))
            return "google-gemini-symbolic";
        if (model.includes("deepseek"))
            return "deepseek-symbolic";
        if (/^phi\d*:/i.test(model))
            return "microsoft-symbolic";
        return "ollama-symbolic";
    }

    function guessModelName(model) {
        const replaced = model.replace(/-/g, ' ').replace(/:/g, ' ');
        let words = replaced.split(' ');
        words[words.length - 1] = words[words.length - 1].replace(/(\d+)b$/, (_, num) => `${num}B`);
        words = words.map(word => {
            return (word.charAt(0).toUpperCase() + word.slice(1));
        });
        const lastWord = words[words.length - 1];
        if (/^\d+(\.\d+)?[a-zA-Z]?$/.test(lastWord) || /^v?\d+(\.\d+)+$/.test(lastWord)) {
            words[words.length - 1] = `(${lastWord})`;
        } else if (lastWord !== "Latest") {
            words[words.length - 1] = `(${lastWord})`;
        }
        const result = words.join(' ');
        return result;
    }

    function addModel(modelName, data) {
        root.models = Object.assign({}, root.models, {
            [modelName]: aiModelComponent.createObject(this, data)
        });
    }

    property bool ollamaLoaded: false

    function maybeStartOllamaDiscovery() {
        if (root.ollamaLoaded || !Config.ready)
            return;
        if (!(Config.options?.ai?.autoDiscoverOllama ?? true))
            return;
        root.ollamaLoaded = true;
        getOllamaModels.running = true;
    }

    Process {
        id: getOllamaModels
        running: false
        command: [`${Directories.scriptPath}/ai/ii/ii`, `ollama-list`]
        stdout: SplitParser {
            onRead: data => {
                try {
                    if (data.length === 0)
                        return;
                    const dataJson = JSON.parse(data);
                    dataJson.forEach(model => {
                        const safeModelName = root.safeModelName(model);
                        root.addModel(safeModelName, {
                            "name": guessModelName(model),
                            "icon": guessModelLogo(model),
                            "description": Translation.tr("Local Ollama model | %1").arg(model),
                            "homepage": `https://ollama.com/library/${model}`,
                            "endpoint": "http://localhost:11434/v1/chat/completions",
                            "model": model,
                            "requires_key": false
                        });
                    });
                } catch (e) {
                    console.log("Could not fetch Ollama models:", e);
                }
            }
        }
        onExited: root.warnNoModels()
    }

    property bool duckAiLoaded: false

    function duckAiOptions() {
        return Config?.options?.ai?.duckAi ?? ({});
    }

    function maybeStartDuckAiDiscovery() {
        if (root.duckAiLoaded || !Config.ready)
            return;
        if (!(Config.options?.ai?.duckAi?.autoDiscoverDuckAI ?? true))
            return;
        root.duckAiLoaded = true;
        duckAiDiscovery.baseUrl = String(Config.options?.ai?.duckAi?.proxyBaseUrl || "http://127.0.0.1:8787").replace(/\/+$/, "");
        duckAiDiscovery.attemptsLeft = 2;
        duckAiDiscovery.outputBuffer = "";
        duckAiDiscovery.command = ["bash", "-c", `curl --silent --show-error --location --max-time 10 ${duckAiDiscovery.baseUrl}/v1/models`];
        duckAiDiscovery.running = true;
    }

    Timer {
        id: duckAiRetryTimer
        interval: 5000
        repeat: false
        onTriggered: {
            duckAiDiscovery.outputBuffer = "";
            duckAiDiscovery.running = true;
        }
    }

    Process {
        id: duckAiDiscovery
        property string baseUrl: "http://127.0.0.1:8787"
        property string outputBuffer: ""
        property int attemptsLeft: 2
        stdout: SplitParser {
            onRead: data => {
                if (data && data.length > 0)
                    duckAiDiscovery.outputBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (duckAiDiscovery.attemptsLeft-- > 0)
                    duckAiRetryTimer.start();
                else
                    root.warnNoModels();
                return;
            }
            try {
                const parsed = JSON.parse(duckAiDiscovery.outputBuffer);
                const list = (parsed && Array.isArray(parsed.data)) ? parsed.data : [];
                list.forEach(item => root.registerDuckAiModel(item));
            } catch (e) {
                console.log("[AI] Could not parse duck.ai model catalog: ", e);
            }
            root.warnNoModels();
        }
    }

    function duckAiIcon(provider) {
        switch (provider) {
            case "mistral": return "mistral-symbolic";
            default: return "spark-symbolic";
        }
    }

    function prettyDuckAiName(modelId, provider) {
        const raw = (modelId.split("/").pop() || modelId).split("-");
        const merged = [];
        for (let i = 0; i < raw.length; ++i) {
            const token = raw[i];
            const previous = merged.length > 0 ? merged[merged.length - 1] : "";
            if (/^\d+$/.test(token) && /^\d+$/.test(previous)) {
                merged[merged.length - 1] = previous + "." + token;
                continue;
            }
            merged.push(token);
        }
        let name = merged.map(word => {
            return word.charAt(0).toUpperCase() + word.slice(1);
        }).join(" ");
        name = name.replace(/\bGpt\b/g, "GPT").replace(/\bOss\b/g, "OSS").replace(/\b(\d+)b\b/gi, "$1B");
        return provider === "tinfoil" ? `${name} (Tinfoil)` : name;
    }

    function duckAiDescription(modelId, provider, meta) {
        const supportedTools = Array.isArray(meta.supportedTools) ? meta.supportedTools : [];
        const tags = [];
        if (supportedTools.indexOf("WebSearch") !== -1) tags.push(Translation.tr("web search"));
        if (meta.supportsImageUpload === true) tags.push(Translation.tr("image upload"));
        if (supportedTools.indexOf("GenerateImage") !== -1) tags.push(Translation.tr("image generation"));
        const effortOptions = Array.isArray(meta.supportedReasoningEffort) ? meta.supportedReasoningEffort : [];
        if (effortOptions.length > 0) tags.push(`${Translation.tr("reasoning")}: ${effortOptions.join("/")}`);
        const providerName = provider.charAt(0).toUpperCase() + provider.slice(1);
        const tagLine = tags.length > 0 ? ` | ${tags.join(" • ")}` : "";
        return `${providerName}${tagLine}`;
    }

    function registerDuckAiModel(item) {
        if (!item || typeof item.id !== "string" || item.id.length === 0) return;
        const safeId = root.safeModelName(item.id);
        if (!safeId || root.models[safeId]) return; // never clobber built-in or custom models
        const meta = (item.duckai && typeof item.duckai === "object") ? item.duckai : {};
        const provider = typeof meta.provider === "string" ? meta.provider : (typeof item.owned_by === "string" ? item.owned_by : "duck.ai");
        const supportedTools = Array.isArray(meta.supportedTools) ? meta.supportedTools : [];
        const effortOptions = Array.isArray(meta.supportedReasoningEffort) ? meta.supportedReasoningEffort : [];
        const duckAi = root.duckAiOptions();
        const baseUrl = String(duckAi.proxyBaseUrl || "http://127.0.0.1:8787").replace(/\/+$/, "");
        root.addModel(safeId, {
            "name": root.prettyDuckAiName(item.id, provider),
            "icon": root.duckAiIcon(provider),
            "description": root.duckAiDescription(item.id, provider, meta),
            "endpoint": `${baseUrl}/v1/chat/completions`,
            "model": item.id,
            "requires_key": true,
            "key_id": "duckai",
            "key_get_description": Translation.tr("**Instructions**: set the API key for this model's endpoint once with `/key set YOUR_KEY`; models of the same provider share it."),
            "api_format": "duckai",
            "duckai": true,
            "webSearchSupported": supportedTools.indexOf("WebSearch") !== -1,
            "imageUploadSupported": meta.supportsImageUpload === true,
            "imageGenSupported": supportedTools.indexOf("GenerateImage") !== -1,
            "reasoningEffortOptions": effortOptions
        });
    }

    property bool pendingSearchContext: false
    property bool webSearchFailed: false
    property var pendingSearchSources: null
    property string webSearchBuffer: ""
    property string webSearchQuery: ""

    function latestUserQuestionText() {
        for (let i = root.messageIDs.length - 1; i >= 0; --i) {
            const message = root.messageByID[root.messageIDs[i]];
            const content = message?.rawContent ?? "";
            if (message?.role === "user" && content.length > 0
                && !content.startsWith("[[ Output of ") && !content.startsWith("[[ Web search results"))
                return content;
        }
        return "";
    }

    function startGenericSearch(query) {
        root.webSearchBuffer = "";
        root.webSearchQuery = query;
        const scriptPath = `${CF.FileUtils.trimFileProtocol(Directories.scriptPath)}/ai/ii/ii`;
        webSearchProc.command = [scriptPath, `search-web`, query];
        webSearchProc.running = true;
    }

    function webSearchContextText(query, results) {
        let text = `[[ Web search results for "${query}" ]]\n\n`;
        text += results.map((result, index) => {
            const title = (result && result.title) ? result.title : `Result ${index + 1}`;
            const url = (result && result.url) ? result.url : "";
            const snippet = (result && result.snippet) ? result.snippet : "";
            return `${index + 1}. [${title}](${url})\n   ${snippet}`;
        }).join("\n");
        text += "\n\nUse these results to answer the user's latest question when relevant.";
        return text;
    }

    Process {
        id: webSearchProc
        stdout: SplitParser {
            onRead: data => {
                if (data && data.length > 0)
                    root.webSearchBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            let queuedContext = false;
            if (exitCode === 0 && root.webSearchBuffer.length > 0) {
                try {
                    const parsed = JSON.parse(root.webSearchBuffer);
                    const results = (parsed && Array.isArray(parsed.results)) ? parsed.results : [];
                    if (results.length > 0) {
                        queuedContext = true;
                        root.pendingSearchContext = true;
                        root.pendingSearchSources = results.map(result => ({
                            "type": "url_citation",
                            "text": (result && result.title) ? result.title : ((result && result.url) ? result.url : ""),
                            "url": (result && result.url) ? result.url : ""
                        }));
                        const context = root.webSearchContextText(root.webSearchQuery, results);
                        root.registerMessage(root.aiMessageComponent.createObject(root, {
                            "role": "user",
                            "content": context,
                            "rawContent": context,
                            "thinking": false,
                            "done": true
                        }));
                    }
                } catch (e) {
                    console.log("[AI] Could not parse web search results: ", e);
                }
            }
            if (!queuedContext)
                root.webSearchFailed = true;
            requester.makeRequest();
        }
    }

    function modelSupportsImages(model) {
        if (!model) return false;
        if (model.api_format === "gemini") return true;
        return model.imageUploadSupported === true;
    }

    function attachConvertMode(model) {
        if (!model) return "text";
        if (model.api_format === "gemini") return "native";
        if (model.imageUploadSupported === true) return "vision";
        return "text";
    }

    function maxAttachmentBytes(model) {
        if (!model) return 0;
        const explicit = model.maxAttachmentBytes ?? 0;
        if (explicit > 0) return explicit;
        if (model.api_format === "gemini")
            return 50 * 1024 * 1024;
        if (model.api_format === "duckai")
            return 5 * 1024 * 1024;
        return 20 * 1024 * 1024;
    }

    function humanFileSize(bytes) {
        if (isNaN(bytes) || bytes < 0)
            return "";
        if (bytes < 1024)
            return `${bytes} B`;
        if (bytes < 1024 * 1024)
            return `${(bytes / 1024).toFixed(0)} KB`;
        if (bytes < 1024 * 1024 * 1024) {
            const value = (bytes / (1024 * 1024)).toFixed(1);
            return value.endsWith(".0") ? value.slice(0, -2) : `${value} MB`;
        }
        return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }

    Process {
        id: attachConverter
        property string srcPath: ""
        property string mode: "text"
        property string outputBuffer: ""
        property var callback: null
        stdout: SplitParser {
            onRead: data => {
                if (data && data.length > 0)
                    attachConverter.outputBuffer += data;
            }
        }
        onExited: (exitCode, exitStatus) => {
            const callback = attachConverter.callback;
            attachConverter.callback = null;
            root.attachConverting = false;
            let result = null;
            if (exitCode === 0) {
                try {
                    result = JSON.parse(attachConverter.outputBuffer);
                } catch (e) {
                    console.log("[AI] Could not parse attachment conversion output: ", e);
                }
            }
            if (callback)
                callback(result && typeof result === "object" ? result : null);
        }
    }

    function probeAttachment(filePath, callback) {
        const mode = root.attachConvertMode(root.models[root.currentModelId]);
        root.convertAttachment(filePath, mode, callback, "probe");
    }

    function convertAttachment(filePath, mode, callback, phase) {
        if (!phase || phase.length === 0)
            phase = "convert";
        root.attachConverting = true;
        attachConverter.outputBuffer = "";
        attachConverter.srcPath = filePath;
        attachConverter.mode = mode;
        attachConverter.callback = callback;
        const scriptPath = `${CF.FileUtils.trimFileProtocol(Directories.scriptPath)}/ai/ii/ii`;
        attachConverter.command = [scriptPath, `convert-attachment`, filePath, mode, phase];
        attachConverter.running = true;
    }

    DirectoryLister {
        id: getDefaultPrompts
        directory: Directories.defaultAiPrompts
        extensions: [".md", ".txt"]
        onFilesListed: (files) => root.defaultPrompts = files
        running: true
    }

    DirectoryLister {
        id: getUserPrompts
        directory: Directories.userAiPrompts
        extensions: [".md", ".txt"]
        onFilesListed: (files) => root.userPrompts = files
        running: true
    }

    property var promptFiles: []
    onDefaultPromptsChanged: root.refreshPromptFiles()
    onUserPromptsChanged: root.refreshPromptFiles()

    function refreshPromptFiles() {
        const files = [];
        for (let i = 0; i < root.defaultPrompts.length; ++i)
            files.push(root.defaultPrompts[i]);
        for (let i = 0; i < root.userPrompts.length; ++i)
            files.push(root.userPrompts[i]);
        root.promptFiles = files;
    }

    function refreshUserPrompts() {
        getUserPrompts.directory = "";
        getUserPrompts.directory = Directories.userAiPrompts;
    }

    FileView {
        id: promptWriter
        watchChanges: false
    }

    Process {
        id: promptDeleteProc
        onExited: (exitCode, exitStatus) => root.refreshUserPrompts()
    }

    function savePrompt(name, text) {
        const trimmed = String(name ?? "").trim();
        const content = String(text ?? "");
        if (trimmed.length === 0 || content.length === 0)
            return false;
        const safeName = trimmed.replace(/[^a-zA-Z0-9_.-]/g, "_");
        const path = `${Directories.userAiPrompts}/${safeName}.md`;
        promptWriter.path = "";
        promptWriter.path = path;
        promptWriter.setText(content);
        root.refreshUserPrompts();
        return true;
    }

    function deletePrompt(path) {
        const dir = `${Directories.userAiPrompts}/`;
        if (!path || !String(path).startsWith(dir))
            return;
        promptDeleteProc.command = ["bash", "-c", `rm -f '${CF.StringUtils.shellSingleQuoteEscape(path)}'`];
        promptDeleteProc.running = true;
    }

    DirectoryLister {
        id: getSavedChats
        directory: Directories.aiChats
        extensions: [".json"]
        onFilesListed: (files) => root.savedChats = files
        running: true
    }

    FileView {
        id: promptLoader
        watchChanges: false
        onLoadedChanged: {
            if (!promptLoader.loaded)
                return;
            Config.options.ai.systemPrompt = promptLoader.text();
            root.addMessage(Translation.tr("Loaded the following system prompt\n\n---\n\n%1").arg(Config.options.ai.systemPrompt), root.interfaceRole);
        }
    }

    function printPrompt() {
        root.addMessage(Translation.tr("The current system prompt is\n\n---\n\n%1").arg(Config.options.ai.systemPrompt), root.interfaceRole);
    }

    function loadPrompt(filePath) {
        promptLoader.path = "";
        promptLoader.path = filePath;
        promptLoader.reload();
    }

    function addMessage(message, role) {
        if (message.length === 0)
            return;
        root.registerMessage(aiMessageComponent.createObject(root, {
            "role": role,
            "content": message,
            "rawContent": message,
            "thinking": false,
            "done": true
        }));
    }

    function removeMessage(index) {
        if (index < 0 || index >= messageIDs.length)
            return;
        const id = root.messageIDs[index];
        root.messageIDs.splice(index, 1);
        root.messageIDs = [...root.messageIDs];
        delete root.messageByID[id];
    }

    function addApiKeyAdvice(model) {
        root.addMessage(Translation.tr('To set an API key, pass it with the %4 command\n\nTo view the key, pass "get" with the command<br/>\n\n### For %1:\n\n**Link**: %2\n\n%3').arg(model.name).arg(model.key_get_link).arg(model.key_get_description ?? Translation.tr("<i>No further instruction provided</i>")).arg("/key"), Ai.interfaceRole);
    }

    function getModel() {
        return models[currentModelId];
    }

    function setModel(modelId, feedback = true, setPersistentState = true) {
        if (!modelId)
            modelId = "";
        modelId = modelId.toLowerCase();
        if (modelList.indexOf(modelId) !== -1) {
            const model = models[modelId];
            if (Config.options.policies.ai === 2 && !root.isLocalEndpoint(model.endpoint)) {
                root.addMessage(Translation.tr("Online models disallowed\n\nControlled by `policies.ai` config option"), root.interfaceRole);
                return;
            }
            if (setPersistentState)
                Persistent.states.ai.model = modelId;
            if (feedback)
                root.addMessage(Translation.tr("Model set to %1").arg(model.name), root.interfaceRole);
            if (root.allowedTools(model).indexOf(root.currentTool) === -1) {
                Config.options.ai.tool = "none";
                root.currentTool = "none";
            }
            if (model.requires_key) {
                if (root.apiKeysLoaded && (!root.apiKeys[model.key_id] || root.apiKeys[model.key_id].length === 0)) {
                    root.addApiKeyAdvice(model);
                }
            }
        } else {
            if (feedback)
                root.addMessage(Translation.tr("Invalid model. Supported: \n```\n") + modelList.join("\n```\n```\n") + "\n```", Ai.interfaceRole);
        }
    }

    function setTool(tool) {
        const model = root.models[root.currentModelId];
        if (!model || root.allowedTools(model).indexOf(tool) === -1) {
            root.addMessage(Translation.tr("Invalid tool. Supported tools:\n- %1").arg(root.getAvailableTools().join("\n- ")), root.interfaceRole);
            return false;
        }
        Config.options.ai.tool = tool;
        root.currentTool = tool;
        return true;
    }

    function getTemperature() {
        return root.temperature;
    }

    function setTemperature(value) {
        if (value == NaN || value < 0 || value > 1) {
            root.addMessage(Translation.tr("Temperature must be between 0 and 1"), Ai.interfaceRole);
            return;
        }
        Persistent.states.ai.temperature = value;
        root.temperature = value;
        root.addMessage(Translation.tr("Temperature set to %1").arg(value), Ai.interfaceRole);
    }

    function modelNativeTemperature(model, normalized) {
        if (!model || normalized == NaN)
            return normalized;
        if (model.api_format === "gemini")
            return normalized * 2;
        return normalized;
    }

    function printEffort() {
        const model = root.models[root.currentModelId];
        if (!model || (model.reasoningEffortOptions ?? []).length === 0) {
            root.addMessage(Translation.tr("The current model does not expose a reasoning effort setting"), root.interfaceRole);
            return;
        }
        const options = model.reasoningEffortOptions ?? [];
        root.addMessage(Translation.tr("Reasoning effort for %1: %2 (supported: %3)").arg(model.name).arg(root.currentEffort || "none").arg(["none"].concat(options).join(", ")), root.interfaceRole);
    }

    function setEffort(effort) {
        const model = root.models[root.currentModelId];
        if (!model || (model.reasoningEffortOptions ?? []).length === 0) {
            root.addMessage(Translation.tr("The current model does not expose a reasoning effort setting"), root.interfaceRole);
            return false;
        }
        const options = model.reasoningEffortOptions ?? [];
        if (effort !== "none" && options.indexOf(effort) === -1) {
            root.addMessage(Translation.tr("Invalid reasoning effort. Supported for %1: %2").arg(model.name).arg(["none"].concat(options).join(", ")), root.interfaceRole);
            return false;
        }
        Config.setNestedValue("ai.duckAi.effort", effort);
        root.currentEffort = effort;
        return true;
    }

    function setApiKey(key) {
        const model = models[currentModelId];
        if (!model.requires_key) {
            root.addMessage(Translation.tr("%1 does not require an API key").arg(model.name), Ai.interfaceRole);
            return;
        }
        if (!key || key.length === 0) {
            const model = models[currentModelId];
            root.addApiKeyAdvice(model);
            return;
        }
        if (key.trim().toLowerCase() === "unset") {
            KeyringStorage.setNestedField(["apiKeys", model.key_id], "");
            root.addMessage(Translation.tr("API key cleared for %1").arg(model.name), Ai.interfaceRole);
            return;
        }
        KeyringStorage.setNestedField(["apiKeys", model.key_id], key.trim());
        root.addMessage(Translation.tr("API key set for %1").arg(model.name), Ai.interfaceRole);
    }

    function printApiKey() {
        const model = models[currentModelId];
        if (model.requires_key) {
            const key = root.apiKeys[model.key_id];
            if (key) {
                root.addMessage(Translation.tr("API key:\n\n```txt\n%1\n```").arg(key), Ai.interfaceRole);
            } else {
                root.addMessage(Translation.tr("No API key set for %1").arg(model.name), Ai.interfaceRole);
            }
        } else {
            root.addMessage(Translation.tr("%1 does not require an API key").arg(model.name), Ai.interfaceRole);
        }
    }

    function printTemperature() {
        root.addMessage(Translation.tr("Temperature: %1").arg(root.temperature), Ai.interfaceRole);
    }

    function clearMessages() {
        root.messageIDs = [];
        root.messageByID = ({});
        root.requestAnchorMessage = null;
        root.tokenCount.input = -1;
        root.tokenCount.output = -1;
        root.tokenCount.total = -1;
    }

    FileView {
        id: requesterScriptFile
    }

    Process {
        id: requester
        property list<string> baseCommand: ["bash"]
        property AiMessageData message
        property ApiStrategy currentStrategy

        function markDone() {
            requester.message.done = true;
            root.requestAnchorMessage = null;
            if (root.postResponseHook) {
                root.postResponseHook();
                root.postResponseHook = null;
            }
            root.saveChat("lastSession");
            root.responseFinished();
        }

        function makeRequest() {
            const model = models[currentModelId];

            if (!model) {
                root.addMessage(root.modelList.length === 0
                    ? Translation.tr("No model available — start Ollama or add a custom model to your config")
                    : Translation.tr("No model selected — use /model to pick one"), root.interfaceRole);
                return;
            }

            if (model?.requires_key && !KeyringStorage.loaded)
                KeyringStorage.fetchKeyringData();

            requester.currentStrategy = root.currentApiStrategy;
            requester.currentStrategy.reset();

            const effortOptions = model?.reasoningEffortOptions ?? [];
            requester.currentStrategy.effort = (Array.isArray(effortOptions) && effortOptions.length > 0) ? root.currentEffort : "";

            if (root.currentTool === "search" && !root.nativeSearchPayload(model)) {
                if (!root.pendingSearchContext) {
                    const question = root.latestUserQuestionText();
                    if (question && !root.webSearchFailed) {
                        root.startGenericSearch(question);
                        return;
                    }
                    root.webSearchFailed = false;
                } else {
                    root.pendingSearchContext = false;
                }
            }
            let toolsPayload = [];
            if (root.currentTool === "search") {
                const nativePayload = root.nativeSearchPayload(model);
                toolsPayload = (root.pendingSearchContext || !nativePayload) ? [] : nativePayload;
            } else {
                const modeTools = root.tools[model.api_format]?.[root.currentTool];
                toolsPayload = Array.isArray(modeTools) ? modeTools : [];
            }
            if (root.pendingSearchContext)
                root.pendingSearchContext = false;

            if (model.requires_key)
                requester.environment[`${root.apiKeyEnvVarName}`] = root.apiKeys ? (root.apiKeys[model.key_id] ?? "") : "";

            const endpoint = root.currentApiStrategy.buildEndpoint(model);
            const messageArray = root.messageIDs.map(id => root.messageByID[id]);
            const filteredMessageArray = messageArray.filter(message => message.role !== Ai.interfaceRole);
            const data = root.currentApiStrategy.buildRequestData(model, filteredMessageArray, root.systemPrompt, root.modelNativeTemperature(model, root.temperature), toolsPayload, root.requestAnchorMessage);

            let requestHeaders = {
                "Content-Type": "application/json"
            };

            requester.message = root.aiMessageComponent.createObject(root, {
                "role": "assistant",
                "model": currentModelId,
                "content": "",
                "rawContent": "",
                "thinking": true,
                "done": false
            });
            root.registerMessage(requester.message);

            if (root.pendingSearchSources && root.pendingSearchSources.length > 0) {
                requester.message.annotationSources = root.pendingSearchSources;
                if (root.webSearchQuery && root.webSearchQuery.length > 0)
                    requester.message.searchQueries = [root.webSearchQuery];
                root.pendingSearchSources = null;
            }

            let headerString = Object.entries(requestHeaders).filter(([k, v]) => v && v.length > 0).map(([k, v]) => `-H '${k}: ${v}'`).join(' ');

            const authHeader = requester.currentStrategy.buildAuthorizationHeader(root.apiKeyEnvVarName);

            const scriptShebang = "#!/usr/bin/env bash\n";

            let scriptFileSetupContent = requester.currentStrategy.buildScriptFileSetup("");

            let scriptRequestContent = "";
            scriptRequestContent += `curl --no-buffer "${endpoint}"` + ` ${headerString}` + (authHeader ? ` ${authHeader}` : "") + ` --data '${CF.StringUtils.shellSingleQuoteEscape(JSON.stringify(data))}'` + "\n";

            const scriptContent = requester.currentStrategy.finalizeScriptContent(scriptShebang + scriptFileSetupContent + scriptRequestContent);
            const shellScriptPath = CF.FileUtils.trimFileProtocol(root.requestScriptFilePath);
            requesterScriptFile.path = Qt.resolvedUrl(shellScriptPath);
            requesterScriptFile.setText(scriptContent);
            requester.command = baseCommand.concat([shellScriptPath]);
            requester.running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                if (data.length === 0)
                    return;
                if (requester.message.thinking)
                    requester.message.thinking = false;

                try {
                    const result = requester.currentStrategy.parseResponseLine(data, requester.message);

                    if (result.functionCall) {
                        requester.message.functionCall = result.functionCall;
                        root.handleFunctionCall(result.functionCall.name, result.functionCall.args, requester.message);
                    }
                    if (result.tokenUsage) {
                        root.tokenCount.input = result.tokenUsage.input;
                        root.tokenCount.output = result.tokenUsage.output;
                        root.tokenCount.total = result.tokenUsage.total;
                    }
                    if (result.finished) {
                        requester.markDone();
                    }
                } catch (e) {
                    console.log("[AI] Could not parse response: ", e);
                    requester.message.rawContent += data;
                    requester.message.content += data;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            const result = requester.currentStrategy.onRequestFinished(requester.message);

            if (result.finished) {
                requester.markDone();
            } else if (!requester.message.done) {
                requester.markDone();
            }

            if (requester.message.content.includes("API key not valid")) {
                root.addApiKeyAdvice(models[requester.message.model]);
            }
        }
    }

    function createUserMessage(text) {
        return root.aiMessageComponent.createObject(root, {
            "role": "user",
            "content": text,
            "rawContent": text,
            "thinking": false,
            "done": true
        });
    }

    function sendUserMessage(message) {
        if (!message)
            message = "";
        const pendingPath = String(root.pendingFilePath || "");
        root.pendingFilePath = "";
        if (message.length === 0 && pendingPath.length === 0)
            return;
        if (root.attachConverting) {
            if (message.length > 0)
                root.sendPreparedMessage(message, null);
            return;
        }
        if (pendingPath.length === 0) {
            root.sendPreparedMessage(message, null);
            return;
        }
        const mode = root.attachConvertMode(root.models[root.currentModelId]);
        root.convertAttachment(pendingPath, mode, result => {
            if (!result || result.ok !== true) {
                const fileName = String(pendingPath).split("/").pop();
                const reason = (result && result.error) ? result.error : Translation.tr("unreadable file");
                root.addMessage(Translation.tr("Couldn't attach %1: %2").arg(fileName).arg(reason), root.interfaceRole);
                if (message.length > 0)
                    root.sendPreparedMessage(message, null);
                return;
            }
            result.filePath = pendingPath;
            root.sendPreparedMessage(message, result);
        });
    }

    function sendPreparedMessage(text, attachmentDescriptor) {
        const userMessage = root.createUserMessage(text);
        if (attachmentDescriptor)
            userMessage.attachments = [attachmentDescriptor];
        root.registerMessage(userMessage);
        root.requestAnchorMessage = userMessage;
        requester.makeRequest();
    }

    function attachFile(filePath: string) {
        if (!filePath || filePath.length === 0) {
            root.pendingFilePath = "";
            return;
        }
        root.pendingFilePath = CF.FileUtils.trimFileProtocol(filePath);
    }

    function regenerate(messageIndex) {
        if (messageIndex < 0 || messageIndex >= messageIDs.length)
            return;
        const id = root.messageIDs[messageIndex];
        const message = root.messageByID[id];
        if (message.role !== "assistant")
            return;
        for (let i = root.messageIDs.length - 1; i >= messageIndex; i--) {
            root.removeMessage(i);
        }
        const anchorIndex = root.messageIDs.length - 1;
        if (anchorIndex >= 0) {
            const anchor = root.messageByID[root.messageIDs[anchorIndex]];
            if (anchor && anchor.role === "user")
                root.requestAnchorMessage = anchor;
        }
        root.materializeAnchorAttachments(() => requester.makeRequest());
    }

    function materializeAnchorAttachments(callback) {
        const anchor = root.requestAnchorMessage;
        if (!anchor) {
            callback();
            return;
        }
        const attachments = Array.isArray(anchor.attachments) ? anchor.attachments : [];
        const toExtract = attachments.filter(att => att && att.filePath && att.filePath.length > 0 && !att.content);
        if (toExtract.length === 0) {
            callback();
            return;
        }
        const mode = root.attachConvertMode(root.models[root.currentModelId]);
        const queue = toExtract.slice();
        const extractNext = () => {
            if (queue.length === 0) {
                callback();
                return;
            }
            const att = queue.shift();
            root.convertAttachment(att.filePath, mode, result => {
                if (result && result.ok) {
                    att.content = result.content ?? "";
                    if (result.kind)
                        att.kind = result.kind;
                    if (result.mimeType)
                        att.mimeType = result.mimeType;
                    if (result.width > 0)
                        att.width = result.width;
                    if (result.height > 0)
                        att.height = result.height;
                    if (result.sizeBytes > 0)
                        att.sizeBytes = result.sizeBytes;
                }
                extractNext();
            }, "convert");
        };
        extractNext();
    }

    function createFunctionOutputMessage(name, output, includeOutputInChat = true) {
        return aiMessageComponent.createObject(root, {
            "role": "user",
            "content": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "rawContent": `[[ Output of ${name} ]]${includeOutputInChat ? ("\n\n<think>\n" + output + "\n</think>") : ""}`,
            "functionName": name,
            "functionResponse": output,
            "thinking": false,
            "done": true
        });
    }

    function addFunctionOutputMessage(name, output) {
        root.registerMessage(createFunctionOutputMessage(name, output));
    }

    function rejectCommand(message: AiMessageData) {
        if (!message.functionPending)
            return;
        message.functionPending = false;
        addFunctionOutputMessage(message.functionName, Translation.tr("Command rejected by user"));
    }

    function approveCommand(message: AiMessageData) {
        if (!message.functionPending)
            return;
        message.functionPending = false;

        const responseMessage = createFunctionOutputMessage(message.functionName, "", false);
        root.registerMessage(responseMessage);

        commandExecutionProc.message = responseMessage;
        commandExecutionProc.baseMessageContent = responseMessage.content;
        commandExecutionProc.shellCommand = message.functionCall.args.command;
        commandExecutionProc.running = true;
    }

    Process {
        id: commandExecutionProc
        property string shellCommand: ""
        property AiMessageData message
        property string baseMessageContent: ""
        command: ["bash", "-c", shellCommand]
        stdout: SplitParser {
            onRead: output => {
                commandExecutionProc.message.functionResponse += output + "\n\n";
                const updatedContent = commandExecutionProc.baseMessageContent + `\n\n<think>\n<tt>${commandExecutionProc.message.functionResponse}</tt>\n</think>`;
                commandExecutionProc.message.rawContent = updatedContent;
                commandExecutionProc.message.content = updatedContent;
            }
        }
        onExited: (exitCode, exitStatus) => {
            commandExecutionProc.message.functionResponse += `[[ Command exited with code ${exitCode} (${exitStatus}) ]]\n`;
            requester.makeRequest();
        }
    }

    function handleFunctionCall(name, args: var, message: AiMessageData) {
        if (name === "switch_to_search_mode") {
            const modelId = root.currentModelId;
            root.currentTool = "search";
            root.postResponseHook = () => {
                root.currentTool = "functions";
            };
            addFunctionOutputMessage(name, Translation.tr("Switched to search mode. Continue with the user's request."));
            requester.makeRequest();
        } else if (name === "get_shell_config") {
            const configJson = CF.ObjectUtils.toPlainObject(Config.options);
            addFunctionOutputMessage(name, JSON.stringify(configJson));
            requester.makeRequest();
        } else if (name === "set_shell_config") {
            if (!args.key || !args.value) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `key` and `value`."));
                return;
            }
            const key = args.key;
            const value = args.value;
            Config.setNestedValue(key, value);
        } else if (name === "run_shell_command") {
            if (!args.command || args.command.length === 0) {
                addFunctionOutputMessage(name, Translation.tr("Invalid arguments. Must provide `command`."));
                return;
            }
            const contentToAppend = `\n\n**Command execution request**\n\n\`\`\`command\n${args.command}\n\`\`\``;
            message.rawContent += contentToAppend;
            message.content += contentToAppend;
            message.functionPending = true;
        } else
            root.addMessage(Translation.tr("Unknown function call: %1").arg(name), "assistant");
    }

    function chatToJson() {
        return root.messageIDs.map(id => root.messageByID[id].toJSON());
    }

    FileView {
        id: chatSaveFile
        property string chatName: ""
        path: chatName.length > 0 ? `${Directories.aiChats}/${chatName}.json` : ""
        blockLoading: true
    }

    function saveChat(chatName) {
        chatSaveFile.chatName = chatName.trim();
        const saveContent = JSON.stringify(root.chatToJson());
        chatSaveFile.setText(saveContent);
        getSavedChats.running = true;
    }

    function loadChat(chatName) {
        try {
            chatSaveFile.chatName = chatName.trim();
            chatSaveFile.reload();
            const saveContent = chatSaveFile.text();
            const saveData = JSON.parse(saveContent);
            root.clearMessages();
            root.messageIDs = saveData.map((_, i) => {
                return i;
            });
            for (let i = 0; i < saveData.length; i++) {
                const saveItem = saveData[i];
                saveItem.content = saveItem.rawContent;
                root.messageByID[i] = root.aiMessageComponent.createObject(root, saveItem);
            }
        } catch (e) {
            console.log("[AI] Could not load chat: ", e);
        } finally {
            getSavedChats.running = true;
        }
    }
}
