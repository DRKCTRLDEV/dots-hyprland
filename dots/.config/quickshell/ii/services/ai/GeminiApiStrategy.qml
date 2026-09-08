import QtQuick
import qs.modules.common.functions as CF

ApiStrategy {
    readonly property string apiKeyEnvVarName: "API_KEY"
    readonly property string fileUriVarName: "file_uri"
    readonly property string fileMimeTypeVarName: "MIME_TYPE"
    readonly property string fileUriSubstitutionString: "{{ fileUriVarName }}"
    readonly property string fileMimeTypeSubstitutionString: "{{ fileMimeTypeVarName }}"
    property string buffer: ""
    property string pendingUploadPath: ""

    function buildEndpoint(model: AiModel): string {
        const result = model.endpoint + `?key=\$\{${root.apiKeyEnvVarName}\}`
        return result;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, anchor) {
        let contents = messages.map(message => {
            const geminiApiRoleName = (message.role === "assistant") ? "model" : message.role;
            const usingSearch = tools[0]?.google_search !== undefined
            if (!usingSearch && message.functionCall != undefined && message.functionName.length > 0) {
                return {
                    "role": geminiApiRoleName,
                    "parts": [{
                        functionCall: {
                            "name": message.functionName,
                        }
                    }]
                }
            }
            if (!usingSearch && message.functionResponse != undefined && message.functionName.length > 0) {
                return {
                    "role": geminiApiRoleName,
                    "parts": [{
                        functionResponse: {
                            "name": message.functionName,
                            "response": { "content": message.functionResponse }
                        }
                    }]
                }
            }
            return {
                "role": geminiApiRoleName,
                "parts": [
                    ...(message.rawContent && message.rawContent.length > 0 ? [{ text: message.rawContent }] : []),
                    ...(message.fileUri && message.fileUri.length > 0 ? [{
                        "file_data": {
                            "mime_type": message.fileMimeType,
                            "file_uri": message.fileUri
                        }
                    }] : [])
                ]
            }
        })
        pendingUploadPath = "";
        if (anchor) {
            const attachments = Array.isArray(anchor.attachments) ? anchor.attachments : [];
            const anchorIndex = messages.indexOf(anchor);
            const anchorContent = (anchorIndex !== -1) ? contents[anchorIndex] : null;
            if (anchorContent) {
                attachments.forEach(att => {
                    if (!att) return;
                    const mime = String(att.mimeType ?? "");
                    const kind = String(att.kind ?? "");
                    const isImage = kind === "image" || mime.startsWith("image/");
                    const isNativeRaw = (isImage || mime === "application/pdf"
                        || mime === "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                        && att.filePath && att.filePath.length > 0;
                    if (isNativeRaw && !att.fileUri) {
                        if (pendingUploadPath.length === 0) {
                            pendingUploadPath = att.filePath;
                            anchorContent.parts.unshift({
                                file_data: {
                                    mime_type: fileMimeTypeSubstitutionString,
                                    file_uri: fileUriSubstitutionString
                                }
                            });
                        }
                    } else if (att.content && att.content.length > 0) {
                        anchorContent.parts.push({ text: `[Attachment: ${att.fileName || "file"}]\n${att.content}` });
                    }
                });
            }
        }
        let baseData = {
            "contents": contents,
            "tools": tools,
            "system_instruction": {
                "parts": [{ text: systemPrompt }]
            },
            "generationConfig": {
                "temperature": temperature,
            },
        };
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        return "";
    }

    function parseResponseLine(line, message) {
        if (line.startsWith("[")) {
            buffer += line.slice(1).trim();
        } else if (line === "]") {
            buffer += line.slice(0, -1).trim();
            return parseBuffer(message);
        } else if (line.startsWith(",")) {
            return parseBuffer(message);
        } else {
            buffer += line.trim();
        }
        return {};
    }

    function parseBuffer(message) {
        let finished = false;
        try {
            if (buffer.length === 0) return {};
            const dataJson = JSON.parse(buffer);

            if (dataJson.uploadedFile) {
                message.fileUri = dataJson.uploadedFile.uri;
                message.fileMimeType = dataJson.uploadedFile.mimeType;
                return ({})
            }

            if (dataJson.error) {
                const errorMsg = `**Error ${dataJson.error.code}**: ${dataJson.error.message}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            if (!dataJson.candidates) return {};

            if (dataJson.candidates[0]?.finishReason) {
                finished = true;
            }

            if (dataJson.candidates[0]?.content?.parts[0]?.functionCall) {
                const functionCall = dataJson.candidates[0]?.content?.parts[0]?.functionCall;
                message.functionName = functionCall.name;
                message.functionCall = functionCall.name;
                const newContent = `\n\n[[ Function: ${functionCall.name}(${JSON.stringify(functionCall.args, null, 2)}) ]]\n`
                message.rawContent += newContent;
                message.content += newContent;
                return { functionCall: { name: functionCall.name, args: functionCall.args }, finished: finished };
            }

            const responseContent = dataJson.candidates[0]?.content?.parts[0]?.text
            message.rawContent += responseContent;
            message.content += responseContent;

            const annotationSources = dataJson.candidates[0]?.groundingMetadata?.groundingChunks?.map(chunk => {
                return {
                    "type": "url_citation",
                    "text": chunk?.web?.title,
                    "url": chunk?.web?.uri,
                }
            }) ?? [];

            const annotations = dataJson.candidates[0]?.groundingMetadata?.groundingSupports?.map(citation => {
                return {
                    "type": "url_citation",
                    "start_index": citation.segment?.startIndex,
                    "end_index": citation.segment?.endIndex,
                    "text": citation?.segment.text,
                    "url": annotationSources[citation.groundingChunkIndices[0]]?.url,
                    "sources": citation.groundingChunkIndices
                }
            });
            message.annotationSources = annotationSources;
            message.annotations = annotations;
            message.searchQueries = dataJson.candidates[0]?.groundingMetadata?.webSearchQueries ?? [];

            if (dataJson.usageMetadata) {
                return {
                    tokenUsage: {
                        input: dataJson.usageMetadata.promptTokenCount ?? -1,
                        output: dataJson.usageMetadata.candidatesTokenCount ?? -1,
                        total: dataJson.usageMetadata.totalTokenCount ?? -1
                    },
                    finished: finished
                };
            }

        } catch (e) {
            console.log("[AI] Gemini: Could not parse buffer: ", e);
            message.rawContent += buffer;
            message.content += buffer;
        } finally {
            buffer = "";
        }
        return { finished: finished };
    }

    function onRequestFinished(message) {
        return parseBuffer(message);
    }

    function reset() {
        buffer = "";
        pendingUploadPath = "";
    }

    function buildScriptFileSetup(filePath) {
        if (!pendingUploadPath || pendingUploadPath.length === 0)
            return "";
        const trimmedFilePath = CF.FileUtils.trimFileProtocol(pendingUploadPath);
        let content = ""

        content += `IMAGE_PATH='${CF.StringUtils.shellSingleQuoteEscape(trimmedFilePath)}'\n`;
        content += `${fileMimeTypeVarName}=$(file -b --mime-type "$IMAGE_PATH")\n`;
        content += 'NUM_BYTES=$(wc -c < "${IMAGE_PATH}")\n';
        content += 'tmp_header_file="/tmp/quickshell/ai/upload-header.tmp"\n';
        content += 'tmp_file_info_file="/tmp/quickshell/ai/file-info.json.tmp"\n';

        content += 'curl "https://generativelanguage.googleapis.com/upload/v1beta/files"'
            + ` -H "x-goog-api-key: \${${apiKeyEnvVarName}}"`
            + ' -D $tmp_header_file'
            + ' -H "X-Goog-Upload-Protocol: resumable"'
            + ' -H "X-Goog-Upload-Command: start"'
            + ' -H "X-Goog-Upload-Header-Content-Length: ${NUM_BYTES}"'
            + ` -H "X-Goog-Upload-Header-Content-Type: \${${fileMimeTypeVarName}}"`
            + ' -H "Content-Type: application/json"'
            + ` -d "{'file': {'display_name': 'Attachment'}}" 2> /dev/null`
            + '\n';

        content += 'upload_url=$(grep -i "x-goog-upload-url: " "${tmp_header_file}" | cut -d" " -f2 | tr -d "\r")\n';
        content += 'rm "${tmp_header_file}"\n';

        content += 'curl "${upload_url}"'
            + ` -H "x-goog-api-key: \${${apiKeyEnvVarName}}"`
            + ' -H "Content-Length: ${NUM_BYTES}"'
            + ' -H "X-Goog-Upload-Offset: 0"'
            + ' -H "X-Goog-Upload-Command: upload, finalize"'
            + ' --data-binary "@${IMAGE_PATH}" 2> /dev/null > "${tmp_file_info_file}"'
            + '\n';

        content += `${fileUriVarName}=$(jq -r ".file.uri" "$tmp_file_info_file")\n`
        content += `printf "{\\"uploadedFile\\": {\\"uri\\": \\"$${fileUriVarName}\\", \\"mimeType\\": \\"$${fileMimeTypeVarName}\\"}}\\n,\\n"\n`

        return content
    }

    function finalizeScriptContent(scriptContent: string): string {
        return scriptContent.replace(fileMimeTypeSubstitutionString, `'"\$${fileMimeTypeVarName}"'`)
                            .replace(fileUriSubstitutionString, `'"\$${fileUriVarName}"'`);
    }
}
