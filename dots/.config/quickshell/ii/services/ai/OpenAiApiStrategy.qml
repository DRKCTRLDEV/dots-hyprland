import QtQuick
import qs.modules.common.functions as CF

ApiStrategy {
    property bool isReasoning: false
    property var attachTokens: ({}) // token -> file path
    property int attachCount: 0

    function attachTokenFor(filePath) {
        const token = `qsvAttach${attachCount++}`;
        attachTokens[token] = filePath;
        return `{{ ${token} }}`;
    }

    function reset() {
        isReasoning = false;
        attachTokens = {};
        attachCount = 0;
    }

    function buildEndpoint(model: AiModel): string {
        return model.endpoint;
    }

    function buildMessagePayload(model, message, isAnchor) {
        const attachments = Array.isArray(message?.attachments) ? message.attachments : [];
        const text = message?.rawContent ?? "";
        if (attachments.length === 0 || !isAnchor)
            return text;
        const parts = [];
        if (text.length > 0)
            parts.push({ "type": "text", "text": text });
        const vision = model?.imageUploadSupported === true;
        attachments.forEach(att => {
            if (!att) return;
            const isImage = att.kind === "image"
                || (typeof att.mimeType === "string" && att.mimeType.startsWith("image/"));
            if (isImage && vision && att.filePath && att.filePath.length > 0) {
                parts.push({ "type": "image_url", "image_url": { "url": attachTokenFor(att.filePath) } });
            } else if (att.content && att.content.length > 0) {
                const name = att.fileName || "file";
                parts.push({ "type": "text", "text": `[Attachment: ${name}]\n${att.content}` });
            }
        });
        return parts;
    }

    function buildFormattedMessages(model, messages, anchor) {
        return messages.map(message => {
            return {
                "role": message.role,
                "content": buildMessagePayload(model, message, message === anchor),
            }
        });
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, anchor) {
        let baseData = {
            "model": model.model,
            "messages": [
                {role: "system", content: systemPrompt},
                ...buildFormattedMessages(model, messages, anchor),
            ],
            "stream": true,
            "tools": tools,
            "temperature": temperature,
        };
        const effortOptions = model?.reasoningEffortOptions ?? [];
        if (Array.isArray(effortOptions) && effortOptions.length > 0 && effort && effort.length > 0 && effort !== "none")
            baseData.reasoning_effort = effort;
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return `-H "Authorization: Bearer \$\{${apiKeyEnvVarName}\}"`;
    }

    function handleStreamData(dataJson, message) {
        return null;
    }

    function parseResponseLine(line, message) {
        let cleanData = line.trim();
        if (cleanData.startsWith("data:")) {
            cleanData = cleanData.slice(5).trim();
        }

        if (!cleanData || cleanData.startsWith(":")) return {};
        if (cleanData === "[DONE]") {
            return { finished: true };
        }

        try {
            const dataJson = JSON.parse(cleanData);

            if (dataJson.error) {
                const errorMsg = `**Error**: ${dataJson.error.message || JSON.stringify(dataJson.error)}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            const handled = handleStreamData(dataJson, message);
            if (handled) return handled;

            let newContent = "";

            const responseContent = dataJson.choices[0]?.delta?.content || dataJson.message?.content;
            const responseReasoning = dataJson.choices[0]?.delta?.reasoning || dataJson.choices[0]?.delta?.reasoning_content;

            if (responseContent && responseContent.length > 0) {
                if (isReasoning) {
                    isReasoning = false;
                    const endBlock = "\n\n</think>\n\n";
                    message.content += endBlock;
                    message.rawContent += endBlock;
                }
                newContent = responseContent;
            } else if (responseReasoning && responseReasoning.length > 0) {
                if (!isReasoning) {
                    isReasoning = true;
                    const startBlock = "\n\n<think>\n\n";
                    message.rawContent += startBlock;
                    message.content += startBlock;
                }
                newContent = responseReasoning;
            }

            message.content += newContent;
            message.rawContent += newContent;

            if (Array.isArray(dataJson.annotations)) {
                const sources = dataJson.annotations
                    .filter(annotation => annotation && typeof annotation.url === "string")
                    .map(annotation => ({
                        "type": "url_citation",
                        "text": annotation.text || annotation.title || annotation.url,
                        "url": annotation.url,
                    }));
                if (sources.length > 0)
                    message.annotationSources = sources;
            }

            if (dataJson.usage) {
                return {
                    tokenUsage: {
                        input: dataJson.usage.prompt_tokens ?? -1,
                        output: dataJson.usage.completion_tokens ?? -1,
                        total: dataJson.usage.total_tokens ?? -1
                    }
                };
            }

            if (dataJson.done) {
                return { finished: true };
            }

        } catch (e) {
            console.log("[AI] OpenAI: Could not parse line: ", e);
            message.rawContent += line;
            message.content += line;
        }

        return {};
    }

    function onRequestFinished(message) {
        return {};
    }

    function buildScriptFileSetup(filePath) {
        let content = "";
        Object.keys(attachTokens).forEach(token => {
            const path = attachTokens[token];
            if (!path || path.length === 0) return;
            content += `${token}_PATH='${CF.StringUtils.shellSingleQuoteEscape(path)}'\n`;
            content += `${token}_MIME=$(file -b --mime-type "$${token}_PATH" 2>/dev/null || true)\n`;
            content += `${token}_B64=$(base64 -w0 < "$${token}_PATH" 2>/dev/null || true)\n`;
        });
        return content;
    }

    function finalizeScriptContent(scriptContent: string): string {
        let content = scriptContent;
        Object.keys(attachTokens).forEach(token => {
            content = content.split(`{{ ${token} }}`)
                .join(`'"data:$${token}_MIME;base64,$${token}_B64"'`);
        });
        return content;
    }
}
