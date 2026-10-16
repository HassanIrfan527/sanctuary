import QtQuick
import Quickshell.Services.Notifications
import "kit"

// One notification while it's a toast (the toast column's delegate): which
// notification, how urgent, how long it stays — the look and the motion are
// the kit's ToastCard.
//
// The time left drains as the toast's timeout runs out and stops while you
// hover. An update (same id, new summary / body) starts it over. Left click
// opens the app (Notifs.activate), right click dismisses.
ToastCard {
    id: toast
    required property var modelData
    readonly property var n: modelData
    readonly property var m: Notifs.meta(n)

    urgency: n?.urgency === NotificationUrgency.Critical ? "critical"
           : n?.urgency === NotificationUrgency.Low ? "low" : "normal"
    seq: m.seq
    app: (n?.appName ?? "") || ""
    time: m.time
    image: (n?.image ?? "") || ""
    summary: n?.summary ?? ""
    body: n?.body ?? ""
    actions: Notifs.extraActions(n)
    timed: Notifs.timeoutFor(n) > 0

    NumberAnimation on life {
        id: lifeAnim
        running: Notifs.timeoutFor(toast.n) > 0
        paused: running && toast.hovered
        from: 1
        to: 0
        duration: Math.max(1, Notifs.timeoutFor(toast.n))
        onFinished: toast.vanish()
    }
    Connections {
        target: toast.n
        function onSummaryChanged() { toast.restart(); }
        function onBodyChanged() { toast.restart(); }
    }
    function restart() {
        if (Notifs.timeoutFor(n) > 0)
            lifeAnim.restart();
        appear();
    }

    Component.onCompleted: appear()
    onVanished: Notifs.unpop(n)
    onActivated: Notifs.activate(n)
    onDismissed: n.dismiss()
}
