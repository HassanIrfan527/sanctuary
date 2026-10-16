import QtQuick
import ".."

// KIT · Rule — a separator between groups of entries. Signal: a hairline,
// inset from the edges, centred in its band (9px in menus; set height: 1 for
// a bare line; inset: 0 runs it edge to edge).
Item {
    property int inset: 14
    width: parent ? parent.width : 0
    height: 9
    Rectangle {
        x: parent.inset
        width: parent.width - 2 * parent.inset
        height: 1
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.sigRule
    }
}
