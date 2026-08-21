import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import QtQuick

QuickToggleButton {
    id: root

    property QuickToggleModel toggleModel
    property string tooltipText: toggleModel?.tooltipText ?? ""

    visible: toggleModel?.available ?? true
    toggled: toggleModel?.toggled ?? false
    buttonIcon: toggleModel?.icon ?? "close"
    altAction: toggleModel?.altAction ?? null

    onClicked: {
        if (toggleModel?.mainAction) toggleModel.mainAction()
    }

    StyledToolTip {
        text: root.tooltipText
    }
}
