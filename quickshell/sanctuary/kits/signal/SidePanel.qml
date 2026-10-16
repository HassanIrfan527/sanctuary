import QtQuick
import ".."

// KIT · SidePanel — a tall panel against the screen's right edge (the
// notification centre), and how it arrives. Children are laid out freely.
// Signal: the panel look; it slides in 32px and fades, 160ms.
Rectangle {
    id: panel
    property bool open: false
    default property alias content: holder.data

    width: 440
    color: Theme.sigFill
    border.width: 1
    border.color: Theme.sigRule

    // Only the slide offset animates — never x itself. The window's width is
    // 0 for a moment when it's shown, then becomes the screen width; if x
    // were animated, the panel would glide across from the left edge.
    property real slide: open ? 0 : 32
    x: parent ? parent.width - width - 8 + slide : 0
    opacity: open ? 1 : 0
    Behavior on slide { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

    MouseArea {   // swallow clicks on the panel's empty parts
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }
    Ticks {
        anchors.fill: parent
        anchors.margins: -3
    }
    Item {
        id: holder
        anchors.fill: parent
    }
}
