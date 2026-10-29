import QtQuick
import ".."

// KIT (Lantern only) · Wood — the frame every card, rail and plaque wears:
// a 2px outline with notched corners, a wood band lit on top and shadowed
// below, and (unless `paper` is off) the paper inside, ringed in the outline
// colour with a sunk line along its top. Children sit on the paper.
//   thick    the wood band, outline excluded (4 = a rail, 6 = a menu)
//   outline  the frame's colour: a critical toast turns it alarm red
//   fill     the inside (paper; the clock plaque is raised paper)
//   shadow   a hard 4px drop shadow, down-right
Item {
    id: w
    property int thick: 6
    property color outline: Theme.lanOutline
    property bool paper: true
    property color fill: Theme.lanPaper
    property bool shadow: false
    default property alias content: inner.data
    readonly property int edge: 2 + thick

    Rectangle {   // the drop shadow
        visible: w.shadow
        x: 4
        y: 4
        width: w.width
        height: w.height
        color: Qt.rgba(0.04, 0.02, 0.05, 0.55)
    }
    // the outline: two rectangles crossed, so each corner pixel is missing
    Rectangle { x: 2; width: w.width - 4; height: w.height; color: w.outline }
    Rectangle { y: 2; width: w.width; height: w.height - 4; color: w.outline }
    Rectangle {   // the wood
        x: 2
        y: 2
        width: w.width - 4
        height: w.height - 4
        color: Theme.lanWood
        Rectangle { width: parent.width; height: 2; color: Theme.lanWoodLit }
        Rectangle { y: parent.height - 2; width: parent.width; height: 2; color: Theme.lanWoodDark }
        Rectangle { y: 2; width: 2; height: parent.height - 4; color: Theme.lanWoodSide }
        Rectangle { x: parent.width - 2; y: 2; width: 2; height: parent.height - 4; color: Theme.lanWoodDark }
    }
    Rectangle {   // the paper's ring
        visible: w.paper
        x: w.edge - 2
        y: w.edge - 2
        width: Math.max(0, w.width - 2 * w.edge + 4)
        height: Math.max(0, w.height - 2 * w.edge + 4)
        color: Theme.lanOutline
    }
    Rectangle {   // the paper
        visible: w.paper
        x: w.edge
        y: w.edge
        width: Math.max(0, w.width - 2 * w.edge)
        height: Math.max(0, w.height - 2 * w.edge)
        color: w.fill
        Rectangle { width: parent.width; height: 2; color: Theme.lanSunk }
    }
    Item {
        id: inner
        x: w.edge
        y: w.edge
        width: Math.max(0, w.width - 2 * w.edge)
        height: Math.max(0, w.height - 2 * w.edge)
    }
}
