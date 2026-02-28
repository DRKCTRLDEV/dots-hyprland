pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick

QtObject {
    property var actions: [
        {value:"disabled",displayText:"Disabled"},
        {value:"button1",displayText:"Left Click (Button 1)"},
        {value:"button2",displayText:"Right Click (Button 2)"},
        {value:"button3",displayText:"Middle Click"},
        {value:"button4",displayText:"Back (Button 4)"},
        {value:"button5",displayText:"Forward (Button 5)"},
        {value:"button6",displayText:"Button 6"},
        {value:"button7",displayText:"Button 7"},
        {value:"button8",displayText:"Button 8"},
        {value:"button9",displayText:"Button 9"},
        {value:"dpi",displayText:"DPI Cycle"},
        {value:"scrollup",displayText:"Scroll Up"},
        {value:"scrolldown",displayText:"Scroll Down"},
        {value:"LeftSuper",displayText:"Super/Win Key"},
        {value:"Ctrl",displayText:"Ctrl"},
        {value:"Shift",displayText:"Shift"},
        {value:"Alt",displayText:"Alt"},
        {value:"ContextMenu",displayText:"Context Menu"},
        {value:"PlayPause",displayText:"Play/Pause"},
        {value:"VolumeUp",displayText:"Volume Up"},
        {value:"VolumeDown",displayText:"Volume Down"},
        {value:"Mute",displayText:"Mute"},
        {value:"Next",displayText:"Next Track"},
        {value:"Previous",displayText:"Previous Track"}
    ]
    property var mod: {
        "Shift":"Shift","LeftShift":"Shift","RightShift":"Shift",
        "Ctrl":"Ctrl","LeftCtrl":"Ctrl","RightCtrl":"Ctrl",
        "Alt":"Alt","LeftAlt":"Alt","RightAlt":"Alt (Right)",
        "LeftSuper":"Super/Win","RightSuper":"Super/Win"
    }
    property var special: {
        "Escape":"Escape","Space":"Space","Enter":"Enter","Tab":"Tab","BackSpace":"Backspace","Delete":"Delete","Insert":"Insert",
        "Home":"Home","End":"End","PageUp":"Page Up","PageDown":"Page Down","Up":"Arrow Up","Down":"Arrow Down","Left":"Arrow Left",
        "Right":"Arrow Right","ContextMenu":"Context Menu","PrintScreen":"Print Screen","PauseBreak":"Pause/Break","ScrollLock":"Scroll Lock",
        "NumLock":"Num Lock","quote":"'","comma":",","dash":"-","dot":".","slash":"/","semicolon":";","equal":"=",
        "leftbracket":"[","backslash":"\\","rightbracket":"]","backtick":"`","hash":"#","PlayPause":"Play/Pause","VolumeUp":"Volume Up",
        "VolumeDown":"Volume Down","Mute":"Mute","Next":"Next Track","Previous":"Previous Track","scrollup":"Scroll Up","scrolldown":"Scroll Down"
    }
    property var btnNames: {
        "button1":"Left Click (Button 1)","button2":"Right Click (Button 2)","button3":"Middle Click (Button 3)",
        "button4":"Back (Button 4)","button5":"Forward (Button 5)","button6":"DPI (Button 6)","button7":"Button 7",
        "button8":"Button 8","button9":"Button 9"
    }
    property var defaults: {
        "button1":"button1","button2":"button2","button3":"button3","button4":"button4","button5":"button5","button6":"dpi"
    }

    function keyToRivalcfg(k) {
        var m = {}
        m[Qt.Key_Shift]="Shift"; m[Qt.Key_Control]="Ctrl"; m[Qt.Key_Alt]="Alt"; m[Qt.Key_Meta]="LeftSuper"; m[Qt.Key_AltGr]="RightAlt"
        m[Qt.Key_Super_L]="LeftSuper"; m[Qt.Key_Super_R]="RightSuper"; m[Qt.Key_Menu]="ContextMenu"; m[Qt.Key_Escape]="Escape"; m[Qt.Key_Space]="Space"
        m[Qt.Key_Return]=m[Qt.Key_Enter]="Enter"; m[Qt.Key_Tab]="Tab"; m[Qt.Key_Backspace]="BackSpace"; m[Qt.Key_Delete]="Delete"; m[Qt.Key_Insert]="Insert"
        m[Qt.Key_Home]="Home"; m[Qt.Key_End]="End"; m[Qt.Key_PageUp]="PageUp"; m[Qt.Key_PageDown]="PageDown"; m[Qt.Key_CapsLock]="CapsLock"; m[Qt.Key_NumLock]="NumLock"
        m[Qt.Key_ScrollLock]="ScrollLock"; m[Qt.Key_Pause]="PauseBreak"; m[Qt.Key_Print]="PrintScreen"; m[Qt.Key_Left]="Left"; m[Qt.Key_Right]="Right"
        m[Qt.Key_Up]="Up"; m[Qt.Key_Down]="Down"
        for (var i=1; i<=12; i++) m[Qt["Key_F"+i]] = "F"+i
        m[Qt.Key_Apostrophe]="quote"; m[Qt.Key_Comma]="comma"; m[Qt.Key_Minus]="dash"; m[Qt.Key_Period]="dot"; m[Qt.Key_Slash]="slash"
        m[Qt.Key_Semicolon]="semicolon"; m[Qt.Key_Equal]="equal"; m[Qt.Key_BracketLeft]="leftbracket"; m[Qt.Key_Backslash]="backslash"
        m[Qt.Key_BracketRight]="rightbracket"; m[Qt.Key_QuoteLeft]="backtick"; m[Qt.Key_NumberSign]="hash"
        if (m[k]) return m[k]
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
        return null
    }

    function getActionDisplay(a) {
        var act = actions.find(function(x) { return x.value === a })
        if (act) return act.displayText
        if (a.length === 1 && /^[A-Z0-9]$/.test(a)) return a.toUpperCase() + " key"
        if (mod[a]) return mod[a]
        if (special[a]) return special[a] + (special[a].length === 1 ? " key" : "")
        if (/^F\d+$/.test(a)) return a + " key"
        return a || "Unknown"
    }

    function getButtonDisplayName(b) { return btnNames[b.toLowerCase()] || b }
    function getDefaultAction(b) { return defaults[b.toLowerCase()] || b }

    function getAvailableActionsForButton(b, cur) {
        var list = actions.slice()
        var id = b.toLowerCase()
        if (!list.some(function(x) { return x.value === id }) && id !== "button6") {
            list.push({value:id, displayText:"Default (Button " + id.replace("button","") + ")"})
        }
        if (!list.some(function(x) { return x.value === cur }) && cur && cur !== "disabled") {
            list.push({value:cur, displayText:getActionDisplay(cur)})
        }
        return list
    }
}
