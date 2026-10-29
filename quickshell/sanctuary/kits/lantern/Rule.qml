import QtQuick
import ".."

// KIT · Rule — a separator between groups. Lantern: a 2px groove sunk into
// the paper, centred in its band (9px in menus; height: 1 or 2 = the bare
// groove; inset: 0 runs it edge to edge).
Item {
    property int inset: 8
    width: parent ? parent.width : 0
    height: 10
    Rectangle {
        x: parent.inset
        width: parent.width - 2 * parent.inset
        height: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.lanSunk
    }
}
