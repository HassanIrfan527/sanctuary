import QtQuick
import "kit"

// STUDY · TODAY — what do I do now (StudyCard.qml's first tab).
//   left   urgent, today's plan (□ / ■), "I have N min", courses
//   right  the rest of this week, quiz readiness for the next two weeks
Item {
    id: page

    required property Item sink      // StudyCard's keyboard holder, to hand focus back
    property int cursor: 0

    // What the cursor walks: today's blocks, the "I have" plan's, then the quizzes.
    readonly property var nowBlocks: Study.planNow ? Study.planNow.blocks : []
    readonly property var rows: Study.today.concat(nowBlocks).concat(Study.quizzes)
    readonly property int leftWidth: 600

    height: childrenRect.height

    function reset() {
        cursor = 0;
    }
    function key(event) {
        const k = event.key, n = rows.length;
        if (n > 0 && (k === Qt.Key_J || k === Qt.Key_Down))
            cursor = (cursor + 1) % n;
        else if (n > 0 && (k === Qt.Key_K || k === Qt.Key_Up))
            cursor = (cursor + n - 1) % n;
        else if (n > 0 && (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space))
            Study.tick(rows[cursor]);
        else if (event.text.length === 1 && event.text >= "0" && event.text <= "9") {
            have.text = event.text;
            have.focusInput();
        } else
            return false;
        return true;
    }

    // One plan block as a row: □ / ■ tick, course, items · why, minutes.
    component BlockRow: MenuRow {
        required property var modelData
        required property int index
        key: modelData.done ? "■" : "□"
        name: modelData.course
        nameWidth: 70
        desc: Study.blockItems(modelData) + " · " + modelData.reason
        detail: modelData.done ? "DONE" : modelData.minutes + " M"
        status: modelData.kind === "attempt" && !modelData.done ? "warn" : ""
        onClicked: Study.tick(modelData)
    }

    Row {
        spacing: 16

        Panel {
            width: page.leftWidth
            title: "TODAY"
            detail: Study.plan ? Study.hm(Study.plan.done_minutes) + " of " + Study.hm(Study.plan.planned) + " done"
                                 + (Study.plan.saved ? "" : " · draft") : ""

            Label {
                x: 14
                width: parent.width - 28
                role: "headline"
                text: Study.ready && Study.data.next ? "Next: " + Study.data.next.course + " " + Study.data.next.item : "Next: nothing open"
            }
            Label {
                x: 14
                width: parent.width - 28
                role: "sub"
                visible: text !== ""
                text: Study.ready && Study.data.next ? Study.data.next.why : ""
            }
            Repeater {
                model: Study.urgent
                delegate: Label {
                    required property var modelData
                    x: 14
                    width: parent.width - 28
                    role: "note"
                    oneLine: true
                    tone: modelData.state === "live" || modelData.hours_left < 24 ? "alarm" : "warn"
                    text: modelData.course + " " + modelData.title.split(" — ")[0] + " · due "
                          + Study.day(modelData.due) + " " + Study.time(modelData.due) + " · " + modelData.hours_left + " h left"
                }
            }

            Rule {}
            Repeater {
                model: Study.today
                delegate: BlockRow {
                    selected: index === page.cursor
                    onHovered: page.cursor = index
                }
            }
            Label {
                x: 14
                visible: Study.today.length === 0
                role: "empty"
                text: "nothing planned"
            }

            Item {
                width: parent.width
                height: 44
                Field {
                    id: have
                    x: 14
                    y: 6
                    width: parent.width - 28
                    label: "I HAVE (MIN)"
                    onAccepted: {
                        const n = parseInt(text);
                        if (n > 0)
                            Study.budget(n);
                        page.sink.forceActiveFocus();
                    }
                    onEscaped: page.sink.forceActiveFocus()
                }
            }
            Heading {
                x: 14
                visible: page.nowBlocks.length > 0
                text: Study.planNow ? "NOW · " + Study.hm(Study.planNow.planned) + " of " + Study.planNow.budget + " min" : ""
            }
            Repeater {
                model: page.nowBlocks
                delegate: BlockRow {
                    selected: index + Study.today.length === page.cursor
                    onHovered: page.cursor = index + Study.today.length
                }
            }

            Rule {}
            Heading {
                x: 14
                text: "COURSES"
            }
            Repeater {
                model: Study.courses
                delegate: MenuRow {
                    required property var modelData
                    name: modelData.code
                    nameWidth: 70
                    desc: (modelData.behind > 0 ? "behind " + modelData.behind : "on track")
                          + " · " + modelData.done + " of " + modelData.released + " " + modelData.unit + "s"
                          + (modelData.vu_attendance ? " · VU attendance " + Math.round(modelData.vu_attendance.present_pct) + "%" : "")
                    detail: modelData.new_announcements > 0 ? "● " + modelData.new_announcements + " NEW" : ""
                    status: modelData.behind_level === "red" ? "alarm" : modelData.behind_level === "week" ? "warn" : ""
                }
            }
        }

        Panel {
            width: page.width - page.leftWidth - 16
            title: "THIS WEEK"
            detail: Study.ready ? "WK " + Study.data.week + " / " + Study.data.semester.teaching_weeks
                                  + " · MIDTERM WK " + Study.data.semester.midterm_week : ""
            hint: !Study.ready || !Study.data.vulms_last_sync ? "vulms not synced yet"
                  : (Study.data.vulms_last_sync.ok ? "vulms synced " : "vulms sync FAILED ")
                    + Study.day(Study.data.vulms_last_sync.ts) + " " + Study.time(Study.data.vulms_last_sync.ts)

            Repeater {
                model: Study.week.slice(0, 12)
                delegate: MenuRow {
                    required property var modelData
                    name: Study.day(modelData.date)
                    nameWidth: 60
                    desc: (Study.time(modelData.date) || "--:--") + "  " + modelData.course + " " + modelData.title.split(" — ")[0]
                    detail: modelData.state === "live" ? "LIVE"
                          : modelData.conflict ? "CONFLICT"
                          : modelData.kind === "lecture" || modelData.kind === "session" ? "" : modelData.kind.toUpperCase()
                    status: modelData.state === "live" ? "warn" : modelData.conflict ? "alarm" : ""
                }
            }
            Label {
                x: 14
                visible: Study.week.length === 0 || Study.week.length > 12
                role: "empty"
                text: Study.week.length === 0 ? "nothing left this week" : "+ " + (Study.week.length - 12) + " more this week · WEEK tab"
            }

            Rule {}
            Heading {
                x: 14
                text: "QUIZ READINESS · NEXT 2 WEEKS"
            }
            Repeater {
                model: Study.quizzes
                delegate: StudyQuizRow {
                    readonly property int at: index + Study.today.length + page.nowBlocks.length
                    selected: at === page.cursor
                    onHovered: page.cursor = at
                }
            }
        }
    }
}
