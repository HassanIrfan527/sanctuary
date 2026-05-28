import { createBinding } from "ags"
import { createPoll } from "ags/time"
import AstalNotifd from "gi://AstalNotifd"

const CPU_CMD = [
  "bash",
  "-c",
  "grep '^cpu ' /proc/stat | awk '{u=$2+$3+$4; t=u+$5; printf \"%d\", u*100/t}'",
]
const MEM_CMD = [
  "bash",
  "-c",
  "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d\", (t-a)*100/t}' /proc/meminfo",
]

export default function SysStats() {
  const cpu = createPoll("0", 2000, CPU_CMD)
  const mem = createPoll("0", 2000, MEM_CMD)
  const notifd = AstalNotifd.get_default()
  const dnd = createBinding(notifd, "dontDisturb")

  return (
    <box cssClasses={["sysstats"]}>
      <label label={cpu((c) => `CPU ${c.padStart(2, "0")}%`)} />
      <label cssClasses={["sep"]} label="|" />
      <label label={mem((m) => `MEM ${m.padStart(2, "0")}%`)} />
      <label cssClasses={["sep"]} label="|" />
      <label
        label={dnd((d) => (d ? "◆ DND" : "◇ LIVE"))}
        cssClasses={dnd((d) => (d ? ["lit"] : []))}
      />
    </box>
  )
}
