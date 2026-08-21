import QtQuick

OpenAiApiStrategy {
    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let baseData = {
            "model": model.model,
            "messages": [
                {role: "system", content: systemPrompt},
                ...messages.map(message => {
                    const hasFunctionCall = message.functionCall != undefined && message.functionName.length > 0
                    let messageData = {
                        "role": message.role,
                        "content": message.rawContent,
                    }
                    if (hasFunctionCall) {
                        if (message.functionResponse?.length > 0) {
                            messageData.name = message.functionName;
                            messageData.role = "tool";
                            messageData.content = message.functionResponse;
                            messageData.tool_call_id = message.functionCall.id
                        }
                    }
                    return messageData
                }),
            ],
            "stream": true,
            "temperature": temperature,
            "tools": tools,
        };
        // console.log("[AI] Request data: ", JSON.stringify(baseData, null, 2));
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function handleStreamData(dataJson, message) {
        if (dataJson.choices[0]?.delta?.tool_calls) {
            const functionCall = dataJson.choices[0].delta.tool_calls[0];
            const functionName = functionCall.function.name;
            let functionArgs = {};
            try {
                functionArgs = JSON.parse(functionCall.function.arguments) || {};
            } catch (e) {
                functionArgs = {};
            }
            const functionId = functionCall.id;
            const callText = `\n\n[[ Function: ${functionName}(${JSON.stringify(functionArgs, null, 2)}) ]]\n`;
            message.rawContent += callText;
            message.content += callText;
            message.functionName = functionName;
            message.functionCall = functionName;
            return { functionCall: { name: functionName, args: functionArgs, id: functionId } };
        }
        return null;
    }

}
