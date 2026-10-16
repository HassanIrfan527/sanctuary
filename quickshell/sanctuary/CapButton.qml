import QtQuick

// One button on the capture strip, in the current style. `lit` = this toggle
// is on, or this is the button that matters right now; `hot` is its colour.
//   a cell: mono caps, lit text in the hot colour, hairline after it
Item {
    id: btn

    property string text: ""
    property bool lit: false
    property color hot: Theme.sigHot
    property bool rule: true          // Signal: hairline on the right

    signal clicked()

    implicitWidth: label.implicitWidth + 22
    implicitHeight: 32

    // ── Signal ──
    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Theme.sigCell : "transparent"
    }
    Rectangle {
        visible: btn.rule
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 12
        color: Theme.sigRule
    }


    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.mono
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1
        color: (btn.lit ? btn.hot : Theme.sigLabel)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
