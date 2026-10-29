import QtQuick

// KIT · Reading — a load (CPU, memory) by how full it is. Lantern: eight
// stepped pips, green, orange from 65%, red from 85%; the number itself is
// kept (`text`) but not printed — the bar shows things, not figures.
Item {
    property real level: 0          // 0..1
    property string text: ""

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: pips.width
    height: pips.height
    Pips {
        id: pips
        level: parent.level
    }
}
