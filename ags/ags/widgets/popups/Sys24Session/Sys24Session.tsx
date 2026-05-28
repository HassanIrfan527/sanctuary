import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createState } from "ags"

const ACTIONS = [
  { key: "1", label: "lock",     cmd: "hyprlock" },
  { key: "2", label: "logout",   cmd: "hyprctl dispatch exit" },
  { key: "3", label: "reboot",   cmd: "systemctl reboot" },
  { key: "4", label: "shutdown", cmd: "systemctl poweroff" },
]

export default function Sys24Session() {
  const [visible, setVisible] = createState(false)

  app.connect("window-toggled", (_, win) => {
    if (win.name === "sys24-session") setVisible(win.visible)
  })

  function run(cmd: string) {
    setVisible(false)
    execAsync(["bash", "-c", cmd]).catch(() => {})
  }

  const keyCtl = new Gtk.EventControllerKey()
  keyCtl.connect("key-pressed", (_, keyval) => {
    if (keyval === Gdk.KEY_Escape) {
      setVisible(false)
      return true
    }
    const ch = String.fromCharCode(keyval)
    const hit = ACTIONS.find((a) => a.key === ch)
    if (hit) {
      run(hit.cmd)
      return true
    }
    return false
  })

  return (
    <window
      visible={visible}
      name="sys24-session"
      namespace="sys24-session"
      cssClasses={["sys24-root", "Sys24Session"]}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
      application={app}
      onMap={(self: any) => self.add_controller(keyCtl)}
    >
      <box
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
      >
        <Gtk.Frame label="  session  " cssClasses={["sys24-fieldset", "session-modal"]}>
          <box spacing={0}>
            {ACTIONS.map((a) => (
              <button
                cssClasses={["session-button"]}
                onClicked={() => run(a.cmd)}
              >
                <box spacing={4}>
                  <label cssClasses={["session-key"]} label={`[${a.key}]`} />
                  <label label={a.label} />
                </box>
              </button>
            ))}
          </box>
        </Gtk.Frame>
      </box>
    </window>
  )
}
