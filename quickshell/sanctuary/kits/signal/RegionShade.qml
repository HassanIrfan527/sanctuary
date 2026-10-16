import QtQuick
import ".."

// KIT · RegionShade — the screen around a chosen region: dimmed, the region
// clear, a frame just outside it, and (while choosing) its size.
//   strong     dim harder (still choosing)
//   tone       the frame: "" choosing | "alarm" recording | "warn" paused
//   showSize   print "W × H" outside the top-left corner
// Signal: black at 50% / 42%, a 2px frame one pixel clear of the region.
Item {
    id: shade
    property int rx: 0
    property int ry: 0
    property int rw: 0
    property int rh: 0
    property bool strong: false
    property string tone: ""
    property bool showSize: false

    readonly property bool hasRegion: rw > 0 && rh > 0
    readonly property color dim: Qt.rgba(0, 0, 0, strong ? 0.5 : 0.42)

    Rectangle {   // whole screen, until a region exists
        anchors.fill: parent
        visible: !shade.hasRegion
        color: shade.dim
    }
    Rectangle {   // above
        visible: shade.hasRegion
        width: parent.width
        height: shade.ry
        color: shade.dim
    }
    Rectangle {   // below
        visible: shade.hasRegion
        y: shade.ry + shade.rh
        width: parent.width
        height: parent.height - y
        color: shade.dim
    }
    Rectangle {   // left
        visible: shade.hasRegion
        y: shade.ry
        width: shade.rx
        height: shade.rh
        color: shade.dim
    }
    Rectangle {   // right
        visible: shade.hasRegion
        x: shade.rx + shade.rw
        y: shade.ry
        width: parent.width - x
        height: shade.rh
        color: shade.dim
    }
    // The frame: 2px, one pixel clear of the region on every side.
    Rectangle {
        visible: shade.hasRegion
        x: shade.rx - 3
        y: shade.ry - 3
        width: shade.rw + 6
        height: shade.rh + 6
        color: "transparent"
        border.width: 2
        border.color: shade.tone === "warn" ? Theme.yellow : shade.tone === "alarm" ? Theme.red : Theme.sigHot
    }
    // Size readout, outside the top-left corner.
    Text {
        visible: shade.showSize && shade.hasRegion
        x: Math.max(4, shade.rx - 3)
        y: shade.ry - 3 - height - 4 >= 0 ? shade.ry - 3 - height - 4 : shade.ry + shade.rh + 6
        text: shade.rw + " × " + shade.rh
        font.family: Theme.mono
        font.pixelSize: 10
        color: "#ffffff"
    }
}
