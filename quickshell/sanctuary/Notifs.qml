pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon for the QS modes. This process owns
// org.freedesktop.Notifications while it runs, and swaync must be stopped BEFORE
// Quickshell starts: only one process can hold that
// D-Bus name, and whoever asks first wins. (shell.sh keeps swaync down whenever
// Quickshell is up; swaync only runs in the fallback.)
//
// Two lists:
//   history  every notification not yet dismissed (the centre, the count)
//   popups   the ones on screen as toasts right now (a subset of history)
// A toast timing out leaves history alone, the same as swaync.
Singleton {
    id: root

    property bool dnd: false
    property var popups: []
    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length

    // Arrival time + a running number, keyed by notification id. Quickshell's
    // Notification carries neither, and Signal prints both.
    property var _meta: ({})
    property int _seq: 0

    // Every helper below tolerates null: on clear-all a notification object is
    // destroyed a beat before the delegate showing it goes away.
    function meta(n) {
        return (n && _meta[n.id]) || { time: new Date(), seq: 0 };
    }

    function pop(n) {
        // Critical always gets through DND: DND is for chatter, not alarms.
        if (dnd && n.urgency !== NotificationUrgency.Critical)
            return;
        if (popups.indexOf(n) >= 0)
            return;
        popups = [n].concat(popups).slice(0, 5);
    }

    function unpop(n) {
        popups = popups.filter(p => p !== n);
    }

    // How long a toast stays. 0 = until dismissed.
    function timeoutFor(n) {
        if (!n)
            return 0;
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        // Senders pass -t in ms; Quickshell exposes it as seconds. Accept either,
        // so a unit mix-up costs a slightly wrong duration and not a stuck toast.
        const t = Number(n.expireTimeout || 0);
        if (t > 0)
            return t < 100 ? Math.round(t * 1000) : t;
        return n.urgency === NotificationUrgency.Low ? 3000 : 5000;
    }

    // Click: run the notification's default action if it has one (that is what
    // focuses the sender, with niri's honor-xdg-activation debug flag), else
    // just dismiss it.
    function activate(n) {
        if (!n)
            return;
        const def = (n.actions || []).find(a => a.identifier === "default");
        if (def)
            def.invoke();
        else
            n.dismiss();
    }

    function extraActions(n) {
        if (!n)
            return [];
        return (n.actions || []).filter(a => a.identifier !== "default" && a.text !== "");
    }

    function clearAll() {
        popups = [];
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function stamp(d) {
        return Qt.formatDateTime(d, "hh:mm");
    }

    onDndChanged: {
        if (dnd)
            popups = popups.filter(p => p.urgency === NotificationUrgency.Critical);
    }

    NotificationServer {
        id: server
        keepOnReload: true          // a hot reload of the QML must not drop history
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root._seq++;
            const m = Object.assign({}, root._meta);
            m[n.id] = { time: new Date(), seq: root._seq };
            root._meta = m;

            // A sender reusing an id (notify-send -r: the nightlight and mode
            // toasts do) updates THIS object in place. Re-show it when that
            // happens, or the second "[ mode ▸ … ]" toast would never appear.
            n.summaryChanged.connect(() => root.pop(n));
            n.bodyChanged.connect(() => root.pop(n));
            n.closed.connect(() => root.unpop(n));

            root.pop(n);
        }
    }
}
