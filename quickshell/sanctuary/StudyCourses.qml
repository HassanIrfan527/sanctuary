import QtQuick
import "kit"

// STUDY · COURSES — each course and its syllabus (StudyCard.qml's fourth tab).
//   left   the courses: progress through the whole course, behind or on track
//   right  the one under the cursor: numbers, its next assessments, and every
//          item of its syllabus (l / → to walk it, enter = one step up)
Item {
    id: page

    property int cursor: 0
    property bool inSyllabus: false
    readonly property var rows: Study.courses
    readonly property var c: rows.length > 0 ? rows[Math.min(cursor, rows.length - 1)] : null
    readonly property var ahead: c ? Study.assessmentsOf(c.code).filter(a => a.state === "live" || a.state === "upcoming") : []
    readonly property int leftWidth: 480

    function reset() {
        inSyllabus = false;
        Qt.callLater(() => syl.home());
    }
    onCursorChanged: Qt.callLater(() => syl.home())
    function key(event) {
        const k = event.key, n = rows.length;
        if (inSyllabus) {
            if (k === Qt.Key_H || k === Qt.Key_Left)
                inSyllabus = false;
            else
                return syl.key(event);
            return true;
        }
        if (n > 0 && (k === Qt.Key_J || k === Qt.Key_Down))
            cursor = (cursor + 1) % n;
        else if (n > 0 && (k === Qt.Key_K || k === Qt.Key_Up))
            cursor = (cursor + n - 1) % n;
        else if ((k === Qt.Key_L || k === Qt.Key_Right || k === Qt.Key_Return || k === Qt.Key_Enter) && syl.count > 0)
            inSyllabus = true;
        else
            return false;
        return true;
    }
    function watchedAll(code) {
        return Study.items(code).filter(l => l.status !== "todo").length;
    }

    Row {
        spacing: 16

        Panel {
            width: page.leftWidth
            title: "COURSES"
            detail: page.rows.length + " WITH LECTURES"

            Repeater {
                model: page.rows
                delegate: MenuRow {
                    required property var modelData
                    required property int index
                    readonly property int seen: page.watchedAll(modelData.code)
                    height: 44
                    centred: true
                    name: modelData.code
                    nameWidth: 70
                    desc: seen + " / " + modelData.total + " " + modelData.unit + "s"
                    detail: modelData.behind > 0 ? "BEHIND " + modelData.behind : "ON TRACK"
                    status: modelData.behind_level === "red" ? "alarm" : modelData.behind_level === "week" ? "warn" : ""
                    selected: index === page.cursor
                    litWhenSelected: true
                    onHovered: if (!page.inSyllabus) page.cursor = index
                    onClicked: page.cursor = index
                    lead: Meter {
                        value: modelData.total ? seen / modelData.total : 0
                        segments: 12
                        quiet: true
                    }
                }
            }
        }

        Panel {
            width: page.width - page.leftWidth - 16
            title: page.c ? page.c.code : ""
            detail: page.c ? (page.c.cr !== null ? page.c.cr + " CR · " : "") + page.c.unit.toUpperCase() + "S ≈ " + page.c.unit_minutes + " M EACH" : ""
            tone: page.inSyllabus ? "live" : ""

            Label {
                x: 14
                width: parent.width - 28
                role: "headline"
                text: page.c ? page.c.title : ""
            }
            Label {
                x: 14
                width: parent.width - 28
                role: "sub"
                text: !page.c ? ""
                    : page.watchedAll(page.c.code) + " watched · " + page.c.released + " out · " + page.c.total + " in the syllabus so far"
                      + (page.c.behind > 0 ? " · behind " + page.c.behind + " (" + Study.hm(page.c.behind * page.c.unit_minutes) + ")" : " · on track")
            }
            Label {
                x: 14
                width: parent.width - 28
                visible: text !== ""
                role: "note"
                text: !page.c ? ""
                    : [page.c.vu_attendance ? "VU attendance " + Math.round(page.c.vu_attendance.present_pct) + "%" : "",
                       page.c.vu_progress && page.c.vu_progress.quizzes ? "VU quizzes attempted " + page.c.vu_progress.quizzes.attempted : "",
                       page.c.new_announcements > 0 ? "● " + page.c.new_announcements + " new announcement(s)" : ""]
                      .filter(s => s !== "").join(" · ")
            }

            Rule {}
            Heading {
                x: 14
                text: "COMING UP" + (page.ahead.length > 4 ? " · NEXT 4 OF " + page.ahead.length + " (ALL IN QUIZZES)" : "")
            }
            Repeater {
                model: page.ahead.slice(0, 4)
                delegate: StudyQuizRow {
                    dates: true
                }
            }
            Label {
                x: 14
                visible: page.ahead.length === 0
                role: "empty"
                text: "nothing announced ahead"
            }

            Rule {}
            Heading {
                x: 14
                lit: page.inSyllabus
                text: "SYLLABUS · " + (page.c ? page.c.total : 0) + " " + (page.c ? page.c.unit.toUpperCase() : "") + "S"
            }
            StudySyllabus {
                id: syl
                width: parent.width
                height: page.height - 312 - 30 * Math.max(1, Math.min(4, page.ahead.length))
                model: page.c ? Study.items(page.c.code) : []
                active: page.inSyllabus
            }
        }
    }
}
