import QtQuick
import "kit"

// One assessment as a row (STUDY's TODAY and QUIZZES tabs):
//   □ ▮▮▮▮▯▯▯▯▯▯ CS101   Quiz 1 · on Topics 1–38 · opens Tue 3        61%
// □ open now (tick when attempted) · ■ submitted · · not open yet.
// Not announced: no bar, no range, no readiness (spec).
MenuRow {
    id: row

    required property var modelData
    required property int index
    property bool dates: false          // "Nov 2–4" instead of "opens Mon 2"
    readonly property bool announced: modelData.display !== "Not announced"
    readonly property bool done: Study.submitted(modelData) || modelData.state === "done"
    readonly property bool closed: !done && modelData.state !== "live" && modelData.state !== "upcoming"

    centred: true
    key: done ? "■" : modelData.state === "live" ? "□" : "·"
    name: modelData.course
    nameWidth: 70
    desc: modelData.title.split(" — ")[0] + " · "
          + (announced ? "on " + modelData.display + " · " : "")
          + (done ? "submitted"
             : closed ? modelData.state
             : row.dates ? Study.range(modelData)
             : modelData.state === "live" ? "open, due " + Study.day(modelData.due)
             : modelData.opens ? "opens " + Study.day(modelData.opens) : Study.range(modelData))
    detail: done ? "DONE" : closed ? modelData.state.toUpperCase()
          : announced ? Study.pct(modelData.readiness || 0) : "NOT ANNOUNCED"
    status: modelData.state === "live" && !done ? "warn" : modelData.state === "missed" ? "alarm" : ""
    onClicked: Study.tick(modelData)

    lead: Item {   // the bar, or the same gap when there's no range to be ready for
        width: bar.implicitWidth
        height: bar.implicitHeight
        Meter {
            id: bar
            visible: row.announced
            value: row.modelData.readiness || 0
            segments: 10
            quiet: row.modelData.state !== "live"
        }
    }
}
