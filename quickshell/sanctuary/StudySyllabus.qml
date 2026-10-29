import QtQuick
import "kit"

// A syllabus as a scrolling list (STUDY's QUIZZES and COURSES tabs):
//   ■ Topic 23   Number Systems                 WATCHED
//   □ Topic 24   …                                       ← out, not watched yet
//   · Topic 31                                 out Nov 2
// "VU ✓" = VULMS's green tick (CS101, VU001 track it).
// `active`: the cursor is here (l / → from the list beside it). enter / space
// = one step up the ladder, backspace = one step down — through `study mark`.
ListView {
    id: list

    property bool active: false
    property int cursor: 0

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    currentIndex: cursor
    highlightFollowsCurrentItem: false
    onCursorChanged: positionViewAtIndex(cursor, ListView.Contain)
    onModelChanged: if (cursor >= count) cursor = Math.max(0, count - 1)

    function key(event) {
        const k = event.key, n = count;
        if (n === 0)
            return false;
        if (k === Qt.Key_J || k === Qt.Key_Down)
            cursor = Math.min(n - 1, cursor + 1);
        else if (k === Qt.Key_K || k === Qt.Key_Up)
            cursor = Math.max(0, cursor - 1);
        else if (k === Qt.Key_PageDown)
            cursor = Math.min(n - 1, cursor + 10);
        else if (k === Qt.Key_PageUp)
            cursor = Math.max(0, cursor - 10);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            Study.step(model[cursor], 1);
        else if (k === Qt.Key_Backspace)
            Study.step(model[cursor], -1);
        else
            return false;
        return true;
    }
    // Start on the first item not watched yet — where you are in it.
    function home() {
        const i = (model || []).findIndex(l => l.status === "todo");
        cursor = i < 0 ? 0 : i;
        positionViewAtIndex(cursor, ListView.Center);
    }

    delegate: MenuRow {
        required property var modelData
        required property int index
        readonly property bool out: modelData.is_released
        key: modelData.status !== "todo" ? "■" : out ? "□" : "·"
        name: modelData.label
        nameWidth: 100
        desc: (modelData.title || "") + (modelData.partial ? " (partly)" : "") + (modelData.vu_done ? "  · VU ✓" : "")
        detail: modelData.status !== "todo" ? modelData.status.toUpperCase()
              : !out ? (modelData.released ? "out " + Qt.formatDate(new Date(modelData.released + "T00:00"), "MMM d") : "not out")
              : ""
        selected: list.active && index === list.cursor
        litWhenSelected: true
        onHovered: list.cursor = index
        onClicked: {
            list.cursor = index;
            Study.step(modelData, 1);
        }
    }
}
