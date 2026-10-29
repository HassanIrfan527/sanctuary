import QtQuick
import ".."

// KIT · RegionShade — the screen around a chosen region: dimmed, the region
// clear, a frame just outside it, and (while choosing) its size.
//   strong     dim harder (still choosing)
//   tone       the frame: "" choosing (pink: yours) | "alarm" recording | "warn" paused
//   showSize   print "W × H" outside the top-left corner
// Lantern: a 2px frame two pixels clear of the region, with the selected-tool
// marks at its corners.
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
    readonly property color dim: Qt.rgba(0.04, 0.02, 0.05, strong ? 0.5 : 0.42)
    readonly property color frame: tone === "warn" ? Theme.lanWarn : tone === "alarm" ? Theme.lanAlarm : Theme.lanPink

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
    Rectangle {   // the frame: 2px, two pixels clear of the region
        visible: shade.hasRegion
        x: shade.rx - 4
        y: shade.ry - 4
        width: shade.rw + 8
        height: shade.rh + 8
        color: "transparent"
        border.width: 2
        border.color: shade.frame
        Corners {
            anchors.fill: parent
            anchors.margins: -4
            color: shade.frame
        }
    }
    Rectangle {   // size readout, outside the top-left corner
        visible: shade.showSize && shade.hasRegion
        x: Math.max(4, shade.rx - 4)
        y: shade.ry - 8 - height >= 0 ? shade.ry - 8 - height : shade.ry + shade.rh + 10
        width: size.implicitWidth + 12
        height: 24
        color: Theme.lanSunk
        LText {
            id: size
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: shade.rw + " × " + shade.rh
            color: Theme.lanBright
        }
    }
}
