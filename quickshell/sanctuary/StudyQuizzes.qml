import QtQuick
import "kit"

// STUDY · QUIZZES — every quiz, attendance quiz, GDB, assignment and exam of
// the semester, by date (StudyCard.qml's second tab).
//   left   the list: tick box, readiness bar, dates, readiness %
//   right  the one under the cursor: schedule, readiness, notes, its syllabus
//          item by item (tickable), and the quiz rules
Item {
    id: page

    property int cursor: 0
    property bool inSyllabus: false
    readonly property var rows: Study.allAssessments
    readonly property var a: rows.length > 0 ? rows[Math.min(cursor, rows.length - 1)] : null
    readonly property bool announced: a !== null && a.display !== "Not announced"
    readonly property int leftWidth: 560

    function reset() {
        cursor = Study.firstOpenAssessment;
        inSyllabus = false;
        list.positionViewAtIndex(cursor, ListView.Beginning);
        syl.home();
    }
    onCursorChanged: {
        list.positionViewAtIndex(cursor, ListView.Contain);
        Qt.callLater(() => syl.home());
    }
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
            cursor = Math.min(n - 1, cursor + 1);
        else if (n > 0 && (k === Qt.Key_K || k === Qt.Key_Up))
            cursor = Math.max(0, cursor - 1);
        else if ((k === Qt.Key_L || k === Qt.Key_Right) && syl.count > 0)
            inSyllabus = true;
        else if (a && (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space))
            Study.tick(a);
        else
            return false;
        return true;
    }
    function days(iso) {
        const d = (new Date(iso).getTime() - Date.now()) / 86400000;
        return d < 1 ? Math.max(0, Math.round(d * 24)) + " h" : Math.ceil(d) + " days";
    }

    Row {
        spacing: 16

        Panel {
            width: page.leftWidth
            title: "QUIZZES"
            detail: Study.allAssessments.filter(x => Study.isQuizLike(x) && (x.state === "live" || x.state === "upcoming")).length + " AHEAD"

            ListView {
                id: list
                width: parent.width
                height: page.height - 58
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: page.rows
                delegate: StudyQuizRow {
                    dates: true
                    selected: index === page.cursor
                    litWhenSelected: true
                    onHovered: if (!page.inSyllabus) page.cursor = index
                    onClicked: {
                        page.cursor = index;
                        Study.tick(modelData);
                    }
                }
            }
        }

        Panel {
            width: page.width - page.leftWidth - 16
            title: page.a ? page.a.course + " · " + page.a.kind.toUpperCase() : ""
            detail: !page.a ? ""
                  : Study.submitted(page.a) ? "SUBMITTED"
                  : page.a.state === "live" ? "OPEN NOW" : page.a.state.toUpperCase()
            detailTone: page.a && page.a.state === "live" && !Study.submitted(page.a) ? "warn" : ""
            tone: page.inSyllabus ? "live" : ""

            Label {
                x: 14
                width: parent.width - 28
                role: "headline"
                text: page.a ? page.a.title : ""
            }
            Label {   // the schedule
                x: 14
                width: parent.width - 28
                role: "sub"
                text: !page.a ? ""
                    : (page.a.opens ? "opens " + Qt.formatDateTime(new Date(page.a.opens), "ddd MMM d HH:mm") + " · " : "")
                      + (page.a.kind === "midterm" || page.a.kind === "final" ? "from " : "closes ")
                      + (page.a.due ? Qt.formatDateTime(new Date(page.a.due), "ddd MMM d HH:mm") : "no date yet")
                      + (page.a.tentative ? " · tentative" : "")
            }
            Label {
                x: 14
                width: parent.width - 28
                role: "note"
                tone: page.a && page.a.state === "live" && !Study.submitted(page.a) ? "warn" : ""
                text: !page.a || !page.a.due ? ""
                    : Study.submitted(page.a) ? "submitted — ticked; enter again to undo"
                    : page.a.state === "live" ? "open now · " + page.days(page.a.due) + " left · enter once you've attempted it"
                    : page.a.state === "upcoming" ? (page.a.opens ? "opens in " + page.days(page.a.opens) : "in " + page.days(page.a.due))
                    : page.a.state
            }

            Rule {}
            Item {   // readiness, big
                x: 14
                width: parent.width - 28
                height: 30
                visible: page.announced
                Meter {
                    id: big
                    anchors.verticalCenter: parent.verticalCenter
                    value: page.a && page.a.readiness || 0
                    segments: 20
                    quiet: page.a !== null && page.a.state !== "live"
                }
                Label {
                    anchors.left: big.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - big.width - 14
                    role: "readout"
                    text: !page.a || !page.announced ? ""
                        : Study.pct(page.a.readiness) + "  ·  " + page.a.items_done + " of " + page.a.items_total + " done"
                          + (page.a.minutes_left ? "  ·  " + Study.hm(page.a.minutes_left) + " left" : "")
                          + (page.a.pace_min_per_day ? "  ·  " + Math.round(page.a.pace_min_per_day) + " m/day" : "")
                }
            }
            Label {
                x: 14
                width: parent.width - 28
                visible: page.a !== null && !page.announced
                role: "empty"
                text: "Not announced — VU hasn't said what it covers yet. No range, no readiness, not in the plan."
            }
            Label {
                x: 14
                width: parent.width - 28
                visible: text !== ""
                role: "note"
                text: page.a && page.a.notes ? "note: " + page.a.notes : ""
            }

            Heading {
                x: 14
                visible: page.announced
                lit: page.inSyllabus
                text: "SYLLABUS · " + (page.a && page.a.display ? page.a.display.toUpperCase() : "")
                      + (page.a && page.a.items_total ? " · " + (page.a.items_total - page.a.items_done) + " TO GO" : "")
            }
            StudySyllabus {
                id: syl
                visible: page.announced
                width: parent.width
                height: page.announced ? Math.min(contentHeight, page.height - 330) : 0
                model: page.a && page.a.covers ? Study.items(page.a.course, page.a.covers[0], page.a.covers[1]) : []
                active: page.inSyllabus
            }

            Rule {}
            Heading {
                x: 14
                visible: rules.text !== ""
                text: "RULES"
            }
            Label {
                id: rules
                x: 14
                width: parent.width - 28
                visible: text !== ""
                role: "note"
                maximumLineCount: 9
                elide: Text.ElideRight
                text: page.a && Study.isQuizLike(page.a) ? Study.rulesFor(page.a) : ""
            }
        }
    }
}
