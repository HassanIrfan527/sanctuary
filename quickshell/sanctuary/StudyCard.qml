import QtQuick
import "kit"

// STUDY — the VU portal, Mod+S (or Launcher :DESK "Study"). Reads Study.qml
// (portal.json); every tick goes through the `study` CLI, never the markdown.
// Four tabs, one question each:
//
//   TODAY     what do I do now: Next + load, the plan, "I have N min", courses,
//             the rest of this week, quiz readiness           (StudyToday.qml)
//   QUIZZES   every quiz / attendance / GDB / exam: schedule, readiness,
//             notes, rules, its syllabus item by item         (StudyQuizzes.qml)
//   WEEK      any semester week, day by day, and the 16-week strip (StudyWeek.qml)
//   COURSES   each course: progress, what's coming, its whole syllabus (StudyCourses.qml)
//
//   tab shift+tab  switch     j k ↑ ↓  move     l → / h ←  into / out of a syllabus
//   enter space  tick: plan row → watched · open quiz → submitted · syllabus item → one step up
//   backspace  syllabus item one step down     0-9  "I have N min" (TODAY)
//   r  refresh     esc q  close
Popup {
    id: win

    name: "study"
    open: Ui.studyOpen
    onDismissed: Ui.studyOpen = false
    cardWidth: 1240
    numberKeys: false   // digits type the "I have" minutes
    // No list keys here: each tab moves its own cursor (key(event) → handled?).
    onKeyPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
            tab = (tab + (event.key === Qt.Key_Tab ? 1 : tabs.length - 1)) % tabs.length;
        else if (event.key === Qt.Key_R)
            Study.refresh();
        else if (!pages[tab].key(event))
            return;
        event.accepted = true;
    }

    readonly property var tabs: ["TODAY", "QUIZZES", "WEEK", "COURSES"]
    property int tab: 0
    readonly property var pages: [today, quizzes, week, courses]

    onVisibleChanged: {
        if (visible) {
            Study.refresh();          // a new day, or a write from elsewhere
            for (const p of pages)
                p.reset();
            Qt.callLater(() => sink.forceActiveFocus());
        }
    }

    // Holds the keyboard while no field is being typed in; keys bubble up to
    // the Popup, which hands them to the tab on show.
    Item {
        id: sink
    }

    Column {
        width: parent.width
        spacing: 12

        Panel {
            width: parent.width
            title: "STUDY"
            detail: Study.ready ? "WEEK " + Study.data.week + " · LOAD " + Study.hm(Study.data.load_min_per_day) + "/day"
                                  + (Study.busy ? " · SAVING" : "") : ""
            detailTone: Study.busy ? "live" : ""
            hint: win.tab === 0 ? "tab switch · j k move · enter tick · 0-9 I have N min · r refresh · esc close"
                : win.tab === 2 ? "tab switch · j k pick a week · enter back to this week · esc close"
                : win.tab === 1 ? "tab switch · j k move · enter tick an open quiz · l into its syllabus · h back · enter step up · backspace step down · esc close"
                : "tab switch · j k move · l into the syllabus · h back · enter step up · backspace step down · esc close"

            ModeTabs {
                labels: win.tabs
                current: win.tab
                detail: Study.ready && Study.data.next ? "NEXT  " + Study.data.next.course + " " + Study.data.next.item : ""
                onPicked: i => win.tab = i
            }
            Label {
                x: 14
                width: parent.width - 28
                visible: text !== ""
                role: "note"
                tone: "alarm"
                text: Study.error
            }
        }

        // The tabs share one fixed height, so the card doesn't jump when you switch.
        Item {
            width: parent.width
            height: 700

            StudyToday {
                id: today
                visible: win.tab === 0
                width: parent.width
                sink: sink
            }
            StudyQuizzes {
                id: quizzes
                visible: win.tab === 1
                width: parent.width
                height: parent.height
            }
            StudyWeek {
                id: week
                visible: win.tab === 2
                width: parent.width
                height: parent.height
            }
            StudyCourses {
                id: courses
                visible: win.tab === 3
                width: parent.width
                height: parent.height
            }
        }
    }
}
