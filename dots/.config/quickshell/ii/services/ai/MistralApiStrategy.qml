import QtQuick

OpenAiApiStrategy {
    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, anchor) {
        const formattedMessages = buildFormattedMessages(model, messages, anchor);
        const finalMessages = formattedMessages.map((messageData, index) => {
            const message = messages[index];
            if (message?.functionResponse && message.functionResponse.length > 0
                && message.functionName && message.functionName.length > 0) {
                return {
                    "role": "tool",
                    "name": message.functionName,
                    "content": message.functionResponse,
                    "tool_call_id": (message.functionCall && message.functionCall.id) || ""
                };
            }
            return messageData;
        });
        let baseData = {
            "model": model.model,
            "messages": [
                {role: "system", content: systemPrompt},
                ...finalMessages,
            ],
            "stream": true,
            "temperature": temperature,
            "tools": tools,
        };
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
