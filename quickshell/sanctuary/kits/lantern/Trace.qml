import QtQuick

// KIT · Trace — the recent history of a load. Lantern draws none: the pips
// (Reading) say how full it is now, and a calm bar doesn't scroll.
Item {
    property var values: []
    property real level: 0
    property real max: 1

    width: 0
    height: 0
    visible: false
}
