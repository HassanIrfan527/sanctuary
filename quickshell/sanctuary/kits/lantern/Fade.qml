import QtQuick

// KIT · Fade — how a card arrives and leaves. Lantern: it doesn't move. It is
// there, or it isn't (Harry, 2026-10-16: no motion in the pixel style).
Item {
    property bool shown: true
    width: parent ? parent.width : childrenRect.width
    height: childrenRect.height
    opacity: shown ? 1 : 0
}
