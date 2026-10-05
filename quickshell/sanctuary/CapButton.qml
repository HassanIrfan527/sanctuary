import QtQuick

// One button on the capture strip, in the current style. `lit` = this toggle
// is on, or this is the button that matters right now; `hot` is its colour.
//   Signal  a cell: mono caps, lit text in the hot colour, hairline after it
//   Ink     a small panel: ink outline, the shadow turns `hot` when lit
Item {
    id: btn

    property string text: ""
    property bool lit: false
    property color hot: Theme.signal ? Theme.sigHot : Theme.peach
    property bool rule: true          // Signal: hairline on the right

    signal clicked()

    implicitWidth: label.implicitWidth + (Theme.signal ? 22 : 24)
    implicitHeight: Theme.signal ? 32 : 30

    // ── Signal ──
    Rectangle {
        visible: Theme.signal
        anchors.fill: parent
        color: area.containsMouse ? Theme.sigCell : "transparent"
    }
    Rectangle {
        visible: Theme.signal && btn.rule
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 12
        color: Theme.sigRule
    }

    // ── Ink ──
    Rectangle {
        visible: Theme.ink
        x: area.pressed ? 1 : 3
        y: area.pressed ? 1 : 3
        width: parent.width
        height: parent.height
        color: btn.lit ? btn.hot : Theme.paperShade
    }
    Rectangle {
        visible: Theme.ink
        anchors.fill: parent
        color: area.containsMouse ? Theme.paperHover : Theme.paper
        border.width: 2
        border.color: Theme.inkLine
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        font.family: Theme.signal ? Theme.mono : Theme.sans
        font.pixelSize: 11
        font.weight: Theme.signal ? Font.Bold : Font.Black
        font.letterSpacing: Theme.signal ? 1 : 0.4
        color: Theme.signal ? (btn.lit ? btn.hot : Theme.sigLabel) : Theme.inkLine
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
