pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Master Caution — the one lamp that means "something needs you".
//
// A cockpit has dozens of gauges and ONE light you are trained to look at:
// when anything goes wrong it comes on, and the gauges tell you what. Here the
// gauges are the bar's cells; this is the light. Every QS style shows it its own
// way (Signal: red registration marks + red seconds + a lamp; Ink/Paper: the
// clock's shadow goes red + a "!!" panel).
//
// Pressing the lamp ACKNOWLEDGES it: it goes dark while the same reasons
// persist, and comes back the moment a NEW reason appears. A reason that clears
// is forgotten, so if it recurs later it alarms again.
Singleton {
    id: root

    readonly property bool criticalMsg: Notifs.history.some(n => n && n.urgency === NotificationUrgency.Critical)

    readonly property var reasons: Sys.alarms.concat(criticalMsg ? ["MSG"] : [])
    property var acked: []

    readonly property var unacked: reasons.filter(r => acked.indexOf(r) < 0)
    readonly property bool active: unacked.length > 0
    readonly property string text: unacked.join(" · ")

    function acknowledge() {
        acked = reasons.slice();
    }

    // Forget acknowledgements for reasons that have cleared.
    onReasonsChanged: acked = acked.filter(r => reasons.indexOf(r) >= 0)
}
