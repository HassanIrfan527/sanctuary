import QtQuick
import "Glyphs.js" as G
import ".."

// KIT · FooterBar — the bottom line of a card: something at the left, something
// at the right, each a Label role ("fine" keys, "small" position, "caption"
// the name under the cursor). leftWidth > 0 caps the left (it elides).
// Lantern: a groove above it, like the mock's menu foot.
Item {
    id: bar
    property string leftText: ""
    property string rightText: ""
    property string leftRole: "fine"
    property string rightRole: "small"
    property real leftWidth: 0

    width: parent ? parent.width : 0
    height: 32
    Rectangle {
        x: 8
        width: parent.width - 16
        height: 2
        color: Theme.lanSunk
    }
    Label {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        width: bar.leftWidth > 0 ? bar.leftWidth : Math.min(implicitWidth, bar.width - right.implicitWidth - 40)
        oneLine: true
        role: bar.leftRole
        text: G.plain(bar.leftText)
    }
    Label {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        width: implicitWidth
        role: bar.rightRole
        text: G.plain(bar.rightText)
    }
}
