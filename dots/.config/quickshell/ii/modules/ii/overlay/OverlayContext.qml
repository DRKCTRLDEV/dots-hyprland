pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import qs.modules.common

Singleton {
    id: root
    
    signal requestCenter(string identifier)

    readonly property list<var> availableWidgets: [
        { identifier: "crosshair", materialSymbol: "point_scan" },
        { identifier: "fpsLimiter", materialSymbol: "animation" },
        { identifier: "floatingImage", materialSymbol: "imagesmode" },
        { identifier: "recorder", materialSymbol: "screen_record" },
        { identifier: "resources", materialSymbol: "browse_activity" },
        { identifier: "notes", materialSymbol: "note_stack" },
        { identifier: "volumeMixer", materialSymbol: "volume_up" },
    ]
    
    readonly property bool hasPinnedWidgets: root.pinnedWidgetIdentifiers.length > 0

    property list<string> pinnedWidgetIdentifiers: []
    property list<var> clickableWidgets: []
    property list<var> openWidgetInstances: []
    property bool lastArrangeStartRight: false
    property real canvasWidth: 0
    property real canvasHeight: 0

    // Bar-aware edge margins
    readonly property real barEdgeSize: Config.options.bar.vertical
        ? Appearance.sizes.verticalBarWidth
        : Appearance.sizes.barHeight
    readonly property bool barAtTop:    !Config.options.bar.vertical && !Config.options.bar.bottom
    readonly property bool barAtBottom: !Config.options.bar.vertical &&  Config.options.bar.bottom
    readonly property bool barAtLeft:    Config.options.bar.vertical && !Config.options.bar.bottom
    readonly property bool barAtRight:   Config.options.bar.vertical &&  Config.options.bar.bottom

    readonly property real edgeTop:    (barAtTop    ? barEdgeSize : 0) + Config.options.overlay.gapsOut
    readonly property real edgeBottom: (barAtBottom ? barEdgeSize : 0) + Config.options.overlay.gapsOut
    readonly property real edgeLeft:   (barAtLeft   ? barEdgeSize : 0) + Config.options.overlay.gapsOut
    readonly property real edgeRight:  (barAtRight  ? barEdgeSize : 0) + Config.options.overlay.gapsOut

    function registerWidgetInstance(widget) {
        if (!openWidgetInstances.includes(widget)) {
            openWidgetInstances.push(widget)
        }
    }

    function unregisterWidgetInstance(widget) {
        openWidgetInstances = openWidgetInstances.filter(w => w !== widget)
    }

    function rearrange(canvasWidth, canvasHeight) {
        arrange(root.lastArrangeStartRight, canvasWidth, canvasHeight);
    }

    function arrange(startRight, canvasWidth, canvasHeight) {
        root.lastArrangeStartRight = startRight;
        const marginTop    = root.edgeTop;
        const marginBottom = root.edgeBottom;
        const marginLeft   = root.edgeLeft;
        const marginRight  = root.edgeRight;
        const gap = Config.options.overlay.gapsIn;
        const availableHeight = canvasHeight - marginTop - marginBottom;

        // Center-only widgets (e.g. crosshair) are handled separately
        const centerOnly = openWidgetInstances.filter(w => w.identifier === "crosshair");
        centerOnly.forEach(w => w.center());

        // Sort largest-area first (width × height) so bigger widgets go to the top of each column
        const widgets = openWidgetInstances.filter(w => w.identifier !== "crosshair").sort((a, b) => {
            const rm_a = a.resizeMargin ?? 8;
            const rm_b = b.resizeMargin ?? 8;
            const aArea = (a.width - 2 * rm_a) * (a.height - 2 * rm_a);
            const bArea = (b.width - 2 * rm_b) * (b.height - 2 * rm_b);
            return bArea - aArea;
        });
        let firstCol = [];
        let secondCol = [];
        let usedHeight = 0;
        for (let i = 0; i < widgets.length; i++) {
            const w = widgets[i];
            const rm = w.resizeMargin ?? 8;
            const wh = w.height - 2 * rm;
            const addition = (firstCol.length > 0 ? gap : 0) + wh;
            if (usedHeight + addition <= availableHeight) {
                firstCol.push(w);
                usedHeight += addition;
            } else {
                secondCol.push(w);
            }
        }

        function placeColumn(col, onRight) {
            let y = marginTop;
            for (let i = 0; i < col.length; i++) {
                const w = col[i];
                const rm = w.resizeMargin ?? 8;
                const ww = w.width - 2 * rm;
                const wx = onRight ? (canvasWidth - marginRight - ww - rm) : (marginLeft - rm);
                const wy = y - rm;
                w.x = wx;
                w.y = wy;
                w.savePosition(wx, wy);
                y += w.height - 2 * rm + gap;
            }
        }

        placeColumn(firstCol, startRight);
        placeColumn(secondCol, !startRight);
    }

    // Place a newly opened widget into a non-overlapping slot.
    // If its saved position doesn't conflict with other open widgets it is left untouched.
    function placeNewWidget(widget) {
        if (widget.identifier === "crosshair") {
            widget.center();
            return;
        }
        const cw = root.canvasWidth;
        const ch = root.canvasHeight;
        if (cw <= 0 || ch <= 0) return;

        const rm  = widget.resizeMargin ?? 12;
        const ww  = widget.width  - 2 * rm;
        const wh  = widget.height - 2 * rm;
        const gap = Config.options.overlay.gapsIn;
        const mTop    = root.edgeTop;
        const mBottom = root.edgeBottom;
        const mLeft   = root.edgeLeft;
        const mRight  = root.edgeRight;

        const others = root.openWidgetInstances.filter(w => w !== widget && w.identifier !== "crosshair");

        function overlaps(testX, testY) {
            const x1 = testX + rm,         y1 = testY + rm;
            const x2 = x1 + ww,            y2 = y1 + wh;
            for (let i = 0; i < others.length; i++) {
                const o   = others[i];
                const orm = o.resizeMargin ?? 12;
                const ox1 = o.x + orm,           oy1 = o.y + orm;
                const ox2 = o.x + o.width - orm, oy2 = o.y + o.height - orm;
                if (x1 < ox2 + gap && x2 > ox1 - gap && y1 < oy2 + gap && y2 > oy1 - gap)
                    return true;
            }
            return false;
        }

        // No other widgets, or saved position is already clear — keep it
        if (others.length === 0 || !overlaps(widget.x, widget.y)) return;

        // Scan two columns for the first free slot
        const startRight = root.lastArrangeStartRight;
        const colXA = startRight ? (cw - mRight - ww - rm) : (mLeft - rm);
        const colXB = startRight ? (mLeft - rm) : (cw - mRight - ww - rm);

        for (const cx of [colXA, colXB]) {
            let cy = mTop - rm;
            while (cy + rm + wh <= ch - mBottom) {
                if (!overlaps(cx, cy)) {
                    widget.x = cx;
                    widget.y = cy;
                    widget.savePosition(cx, cy);
                    return;
                }
                cy += wh + gap;
            }
        }
        widget.center();
    }

    function pin(identifier: string, pin = true) {
        if (pin) {
            if (!root.pinnedWidgetIdentifiers.includes(identifier)) {
                root.pinnedWidgetIdentifiers.push(identifier)
            }
        } else {
            root.pinnedWidgetIdentifiers = root.pinnedWidgetIdentifiers.filter(id => id !== identifier)
        }
    }

    function registerClickableWidget(widget: var, clickable = true) {
        if (clickable) {
            if (!root.clickableWidgets.includes(widget)) {
                root.clickableWidgets.push(widget)
            }
        } else {
            root.clickableWidgets = root.clickableWidgets.filter(w => w !== widget)
        }
    }
}
