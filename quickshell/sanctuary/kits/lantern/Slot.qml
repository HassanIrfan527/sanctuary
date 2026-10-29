import QtQuick
import ".."

// KIT (Lantern only) · Slot — a well sunk into the paper that holds one thing
// (an icon, a workspace, a portrait). `on` = it's yours now: a pink frame
// inside and the selected-tool marks outside. `tone` "alarm" / "warn" frame
// it in that colour instead (urgent, critical).
Rectangle {
    id: slot
    property bool on: false
    property string tone: ""
    default property alias content: inner.data

    readonly property color frame: tone === "alarm" ? Theme.lanAlarm : tone === "warn" ? Theme.lanWarn : Theme.lanPink

    width: 32
    height: 32
    color: Theme.lanSunk
    Rectangle { width: parent.width; height: 2; color: Qt.rgba(0, 0, 0, 0.28) }
    Item {
        id: inner
        anchors.fill: parent
    }
    Rectangle {
        anchors.fill: parent
        visible: slot.on || slot.tone !== ""
        color: "transparent"
        border.width: 2
        border.color: slot.frame
    }
    Corners {
        anchors.fill: parent
        anchors.margins: -4
        visible: slot.on
        color: slot.frame
    }
}
