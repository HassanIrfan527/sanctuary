import QtQuick
import "kit"

// STUDY · WEEK — the semester as weeks (StudyCard.qml's third tab).
//   left   the picked week, day by day: lectures, lab slots, deadlines (done too)
//   right  the strip: weeks 1–16+, what's due in each, midterms and finals marked
Item {
    id: page

    property int pick: 1             // semester week shown
    readonly property int now: Study.ready ? Study.data.week : 1
    readonly property var events: Study.ready ? Study.eventsOfWeek(pick) : []
    readonly property int leftWidth: 700

    function reset() {
        pick = now;
    }
    function key(event) {
        const k = event.key;
        if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_L || k === Qt.Key_Right)
            pick = Math.min(Study.weeksShown, pick + 1);
        else if (k === Qt.Key_K || k === Qt.Key_Up || k === Qt.Key_H || k === Qt.Key_Left)
            pick = Math.max(1, pick - 1);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
            pick = now;
        else
            return false;
        return true;
    }
    // "Mon Oct 26 – Sun Nov 1"
    function span(n) {
        const a = Study.weekStart(n), b = Study.weekStart(n + 1);
        b.setDate(b.getDate() - 1);
        return Qt.formatDate(a, "MMM d") + " – " + Qt.formatDate(b, "MMM d");
    }
    // What a week holds that matters: deadlines and exams opening or closing in it.
    function dueIn(n) {
        const a = Study.weekStart(n).getTime(), b = Study.weekStart(n + 1).getTime();
        return Study.allAssessments.filter(x => {
            const t = new Date(x.opens || x.due).getTime();
            return x.due && t >= a && t < b;
        });
    }
    function examWord(n) {
        const ex = dueIn(n).map(x => x.kind);
        return ex.indexOf("final") >= 0 ? "FINALS" : ex.indexOf("midterm") >= 0 ? "MIDTERMS" : "";
    }

    Row {
        spacing: 16

        Panel {
            width: page.leftWidth
            title: "WEEK " + page.pick + (page.pick === page.now ? " · THIS WEEK" : "")
            detail: Study.ready ? page.span(page.pick) : ""
            titleTone: page.pick === page.now ? "" : "dim"

            ListView {
                width: parent.width
                height: page.height - 58
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: page.events
                delegate: MenuRow {
                    required property var modelData
                    required property int index
                    readonly property bool firstOfDay: index === 0
                        || page.events[index - 1].date.slice(0, 10) !== modelData.date.slice(0, 10)
                    name: firstOfDay ? Study.day(modelData.date) : ""
                    nameWidth: 70
                    desc: (Study.time(modelData.date) || "     ") + "  " + modelData.course + "  " + modelData.title
                    detail: modelData.state === "live" ? "LIVE"
                          : modelData.conflict ? "CONFLICT"
                          : modelData.status === "submitted" ? "SUBMITTED"
                          : modelData.state === "done" ? "DONE"
                          : modelData.state === "missed" ? "MISSED"
                          : modelData.kind === "lecture" || modelData.kind === "session" ? "" : modelData.kind.toUpperCase()
                    status: modelData.state === "live" ? "warn" : modelData.conflict || modelData.state === "missed" ? "alarm" : ""
                    current: firstOfDay && modelData.date.slice(0, 10) === (Study.ready ? Study.data.today : "")
                }
            }
            Label {
                x: 14
                visible: page.events.length === 0
                role: "empty"
                text: "nothing recorded for this week"
            }
        }

        Panel {
            width: page.width - page.leftWidth - 16
            title: "SEMESTER"
            detail: Study.ready ? "MIDTERMS " + Qt.formatDate(new Date(Study.data.semester.midterm + "T00:00"), "MMM d")
                                  + " · FINALS " + Qt.formatDate(new Date(Study.data.semester.final + "T00:00"), "MMM d") : ""

            Repeater {
                model: Study.ready ? Study.weeksShown : 0
                delegate: MenuRow {
                    required property int index
                    readonly property int n: index + 1
                    readonly property int quizzes: page.dueIn(n).filter(x => Study.isQuizLike(x)).length
                    height: 34
                    number: -1
                    key: n === page.now ? "▸" : " "
                    name: "WK " + n
                    nameWidth: 50
                    desc: page.span(n) + (quizzes > 0 ? "  ·  " + quizzes + " quiz / attendance / gdb" : "")
                    detail: page.examWord(n) || (n === page.now ? "NOW" : "")
                    status: page.examWord(n) !== "" ? "warn" : ""
                    current: n === page.now
                    selected: n === page.pick
                    onClicked: page.pick = n
                }
            }
        }
    }
}
