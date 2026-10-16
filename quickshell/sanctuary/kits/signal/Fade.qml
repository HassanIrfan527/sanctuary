import QtQuick
import ".."

// KIT · Fade — how a card arrives and leaves. Signal: a 160ms ease-out fade.
// Wrap what should move: `Fade { shown: … ; Panel { … } }`.
Item {
    property bool shown: true
    width: parent ? parent.width : childrenRect.width
    height: childrenRect.height
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
}
