import QtQuick

// KIT · Ticks — corner marks. Lantern's are the selected-tool marks (Corners):
// 6px Ls, 2px thick, pink unless told otherwise. (No module draws Ticks
// itself; kept so every kit has the same parts.)
Corners {
    property int len: 6
    property int w: 2
}
