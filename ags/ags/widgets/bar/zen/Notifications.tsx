import { createBinding } from "ags"
import AstalNotifd from "gi://AstalNotifd"

const BELL_ON = "/home/anonymous/.dotfiles/ags/ags/assets/bell.svg"
const BELL_OFF = "/home/anonymous/.dotfiles/ags/ags/assets/bell-off.svg"

export default function Notifications() {
  const notifd = AstalNotifd.get_default()
  const notifications = createBinding(notifd, "notifications")
  const dnd = createBinding(notifd, "dontDisturb")

  const count = notifications((list) => list.length)
  const hasAny = notifications((list) => list.length > 0)

  return (
    <button
      cssClasses={dnd((d) => (d ? ["notif-btn", "dnd"] : ["notif-btn"]))}
      onClicked={() => {
        notifd.dontDisturb = !notifd.dontDisturb
      }}
    >
      <box spacing={6}>
        <image file={dnd((d) => (d ? BELL_OFF : BELL_ON))} pixelSize={16} />
        <label
          visible={hasAny}
          cssClasses={["notif-count"]}
          label={count((c) => `${c}`)}
        />
      </box>
    </button>
  )
}
