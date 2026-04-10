import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createState, For } from "ags"
import { timeout } from "ags/time"
import AstalNotifd from "gi://AstalNotifd"

const { TOP, RIGHT } = Astal.WindowAnchor
const POPUP_TIMEOUT_MS = 5000

export default function NotificationPopups(gdkmonitor: Gdk.Monitor) {
  const notifd = AstalNotifd.get_default()

  let list: AstalNotifd.Notification[] = []
  const [popups, setPopups] = createState<AstalNotifd.Notification[]>([])

  function update(next: AstalNotifd.Notification[]) {
    list = next
    setPopups(next)
  }

  function remove(id: number) {
    update(list.filter((n) => n.id !== id))
  }

  notifd.connect("notified", (_, id: number) => {
    if (notifd.dontDisturb) return
    const n = notifd.get_notification(id)
    if (!n) return

    update([...list.filter((x) => x.id !== n.id), n])
    timeout(POPUP_TIMEOUT_MS, () => remove(n.id))
  })

  notifd.connect("resolved", (_, id: number) => {
    remove(id)
  })

  return (
    <window
      visible
      namespace="notification-popups"
      name="notification-popups"
      class="NotificationPopups"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      application={app}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
        cssClasses={["popups-stack"]}
      >
        <For each={popups}>
          {(n) => (
            <box cssClasses={["notif-card"]} spacing={10}>
              <box
                orientation={Gtk.Orientation.VERTICAL}
                spacing={4}
                hexpand
              >
                <label
                  cssClasses={["notif-card-title"]}
                  label={n.summary}
                  xalign={0}
                  halign={Gtk.Align.START}
                />
                <label
                  visible={!!n.body}
                  cssClasses={["notif-card-body"]}
                  label={n.body}
                  wrap
                  xalign={0}
                  halign={Gtk.Align.START}
                  maxWidthChars={36}
                />
              </box>
              <button
                cssClasses={["notif-card-close"]}
                valign={Gtk.Align.START}
                onClicked={() => remove(n.id)}
              >
                <label label="✕" />
              </button>
            </box>
          )}
        </For>
      </box>
    </window>
  )
}
