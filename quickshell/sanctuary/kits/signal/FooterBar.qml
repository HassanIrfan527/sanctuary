import QtQuick

// KIT · FooterBar — the bottom line of a card: something at the left, something
// at the right, each a Label role ("fine" keys, "small" position, "caption"
// the name under the cursor). leftWidth > 0 caps the left (it elides).
Item {
    id: bar
    property string leftText: ""
    property string rightText: ""
    property string leftRole: "fine"
    property string rightRole: "small"
    property real leftWidth: 0

    width: parent ? parent.width : 0
    height: 28
    Label {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: bar.leftWidth > 0 ? bar.leftWidth : implicitWidth
        role: bar.leftRole
        text: bar.leftText
    }
    Label {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: implicitWidth
        role: bar.rightRole
        text: bar.rightText
    }
}
