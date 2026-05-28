import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createState, For } from "ags"
import { timeout } from "ags/time"
import AstalNotifd from "gi://AstalNotifd"

const { TOP, RIGHT } = Astal.WindowAnchor
const POPUP_TIMEOUT_MS = 5000

export default function Sys24Notifications(gdkmonitor: Gdk.Monitor) {
  const notifd = AstalNotifd.get_default()
  const [popups, setPopups] = createState<AstalNotifd.Notification[]>([])

  const enqueue = (n: AstalNotifd.Notification) => {
    setPopups((cur) => [...cur.filter((x) => x.id !== n.id), n])
    timeout(POPUP_TIMEOUT_MS, () => {
      setPopups((cur) => cur.filter((x) => x.id !== n.id))
    })
  }

  notifd.connect("notified", (_, id: number) => {
    if (notifd.dontDisturb) return
    const n = notifd.get_notification(id)
    if (!n) return
    enqueue(n)
  })

  notifd.connect("resolved", (_, id: number) => {
    setPopups((cur) => cur.filter((x) => x.id !== id))
  })

  return (
    <window
      visible
      namespace="notification-popups"
      name="notification-popups"
      cssClasses={["sys24-root", "Sys24Notifications"]}
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
            <Gtk.Frame
              label={`  ${n.appName || "system"}  `}
              cssClasses={["notif-card"]}
            >
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
                <label
                  cssClasses={["notif-card-title"]}
                  label={n.summary}
                  xalign={0}
                  halign={Gtk.Align.START}
                  wrap
                  maxWidthChars={36}
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
            </Gtk.Frame>
          )}
        </For>
      </box>
    </window>
  )
}
