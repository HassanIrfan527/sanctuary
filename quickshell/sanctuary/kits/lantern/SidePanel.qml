import QtQuick

// KIT · SidePanel — a tall panel against the screen's right edge (the
// notification centre). Children are laid out freely on its paper.
// Lantern: a wooden board with a hard shadow; it is there or it isn't.
Item {
    id: panel
    property bool open: false
    default property alias content: holder.data

    width: 440
    x: parent ? parent.width - width - 12 : 0
    visible: open

    MouseArea {   // swallow clicks on the panel's empty parts
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }
    Wood {
        id: wood
        anchors.fill: parent
        thick: 6
        shadow: true
    }
    Item {
        id: holder
        x: wood.edge
        y: wood.edge
        width: parent.width - 2 * wood.edge
        height: parent.height - 2 * wood.edge
    }
}
