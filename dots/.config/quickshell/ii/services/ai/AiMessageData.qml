import QtQuick;

/**
 * Represents a message in an AI conversation. (Kind of) follows the OpenAI API message structure.
 */
QtObject {
    property string role
    property string content
    property string rawContent
    property string fileMimeType
    property string fileUri
    property string localFilePath
    property string model
    property bool thinking: true
    property bool done: false
    property var annotations: []
    property var annotationSources: []
    property list<string> searchQueries: []
    property string functionName
    property var functionCall
    property string functionResponse
    property bool functionPending: false
    property bool visibleToUser: true
    property var attachments: []
    function attachmentToJSON(att) {
        if (!att)
            return null;
        const copy = {};
        for (const key of Object.keys(att)) {
            if (key === "content")
                continue;
            copy[key] = att[key];
        }
        return copy;
    }

    function toJSON() {
        return {
            "role": role,
            "rawContent": rawContent,
            "fileMimeType": fileMimeType,
            "fileUri": fileUri,
            "localFilePath": localFilePath,
            "model": model,
            "thinking": false,
            "done": true,
            "annotations": annotations,
            "annotationSources": annotationSources,
            "functionName": functionName,
            "functionCall": functionCall,
            "functionResponse": functionResponse,
            "visibleToUser": visibleToUser,
            "attachments": Array.isArray(attachments) ? attachments.map(att => attachmentToJSON(att)) : attachments
        };
    }
}
