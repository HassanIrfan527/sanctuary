import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createBinding, createState, For, With } from "ags"
import AstalNotifd from "gi://AstalNotifd"

const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor

function fmtTime(epochMs: number) {
  if (!epochMs) return ""
  const d = new Date(epochMs * 1000)
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false })
}

export default function Sys24NotifCenter() {
  const notifd = AstalNotifd.get_default()
  const [visible, setVisible] = createState(false)
  const notifications = createBinding(notifd, "notifications")
  const dnd = createBinding(notifd, "dontDisturb")

  app.connect("window-toggled", (_, win) => {
    if (win.name === "sys24-notif-center") setVisible(win.visible)
  })

  function clearAll() {
    notifd.notifications.forEach((n) => n.dismiss())
  }
  function toggleDnd() {
    notifd.dontDisturb = !notifd.dontDisturb
  }

  return (
    <window
      visible={visible}
      name="sys24-notif-center"
      namespace="sys24-notif-center"
      cssClasses={["sys24-root", "Sys24NotifCenter"]}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      anchor={TOP | RIGHT | BOTTOM}
      application={app}
    >
      <box cssClasses={["nc-wrap"]} orientation={Gtk.Orientation.VERTICAL}>
        <Gtk.Frame label="  notifications  " cssClasses={["sys24-fieldset", "nc-frame"]}>
          <box orientation={Gtk.Orientation.VERTICAL} spacing={8} cssClasses={["nc-inner"]}>

            <box cssClasses={["nc-header"]} spacing={8}>
              <button
                cssClasses={dnd((d) => (d ? ["nc-btn", "nc-dnd", "lit"] : ["nc-btn", "nc-dnd"]))}
                onClicked={toggleDnd}
              >
                <label label={dnd((d) => (d ? "● dnd on" : "○ dnd off"))} />
              </button>
              <box hexpand />
              <button cssClasses={["nc-btn", "nc-clear"]} onClicked={clearAll}>
                <label label="✕ clear" />
              </button>
            </box>

            <box cssClasses={["nc-rule"]}>
              <label hexpand label="──────────────────────────────────────────────" />
            </box>

            <With value={notifications}>
              {(list) => {
                if (!list || list.length === 0) {
                  return (
                    <box cssClasses={["nc-empty"]} valign={Gtk.Align.CENTER} hexpand vexpand>
                      <label hexpand label="◌ no notifications" />
                    </box>
                  )
                }
                return (
                  <Gtk.ScrolledWindow
                    cssClasses={["nc-scroll"]}
                    vexpand
                    hexpand
                    hscrollbarPolicy={Gtk.PolicyType.NEVER}
                  >
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                      <For each={notifications}>
                        {(n) => (
                          <Gtk.Frame
                            label={`  ${n.appName || "system"}  `}
                            cssClasses={["sys24-fieldset", "nc-card"]}
                          >
                            <box orientation={Gtk.Orientation.VERTICAL} spacing={3}>
                              <box spacing={6}>
                                <label
                                  cssClasses={["nc-card-title"]}
                                  label={n.summary || "(no title)"}
                                  xalign={0}
                                  halign={Gtk.Align.START}
                                  hexpand
                                  wrap
                                  maxWidthChars={36}
                                />
                                <button
                                  cssClasses={["nc-btn", "nc-x"]}
                                  valign={Gtk.Align.START}
                                  onClicked={() => n.dismiss()}
                                >
                                  <label label="✕" />
                                </button>
                              </box>
                              <label
                                visible={!!n.body}
                                cssClasses={["nc-card-body"]}
                                label={n.body || ""}
                                wrap
                                xalign={0}
                                halign={Gtk.Align.START}
                                maxWidthChars={36}
                              />
                              <label
                                cssClasses={["nc-card-time"]}
                                label={fmtTime(n.time)}
                                xalign={1}
                                halign={Gtk.Align.END}
                              />
                            </box>
                          </Gtk.Frame>
                        )}
                      </For>
                    </box>
                  </Gtk.ScrolledWindow>
                )
              }}
            </With>
          </box>
        </Gtk.Frame>
      </box>
    </window>
  )
}
