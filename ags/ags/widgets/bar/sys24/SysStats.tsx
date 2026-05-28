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
  "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f\", (t-a)/1024/1024}' /proc/meminfo",
]
const BAT_CMD = [
  "bash",
  "-c",
  "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo --",
]

function Pair({ label, value, cls = "" }: { label: string; value: any; cls?: string }) {
  return (
    <box cssClasses={["stat-pair"]} spacing={2}>
      <label cssClasses={["stat-key"]} label={label} />
      <label cssClasses={["stat-val", cls]} label={value} />
    </box>
  )
}

export default function SysStats() {
  const cpu = createPoll("0", 2000, CPU_CMD)
  const mem = createPoll("0", 2000, MEM_CMD)
  const bat = createPoll("--", 5000, BAT_CMD)
  const notifd = AstalNotifd.get_default()
  const dnd = createBinding(notifd, "dontDisturb")

  return (
    <box cssClasses={["sysstats"]} spacing={6}>
      <Pair label="cpu" value={cpu((c) => `${c.padStart(2, " ")}%`)} />
      <label cssClasses={["sep"]} label="│" />
      <Pair label="mem" value={mem((m) => `${m}G`)} />
      <label cssClasses={["sep"]} label="│" />
      <Pair label="bat" value={bat((b) => `${b.trim()}%`)} />
      <label cssClasses={["sep"]} label="│" />
      <label
        cssClasses={dnd((d) => (d ? ["dnd-flag", "lit"] : ["dnd-flag"]))}
        label={dnd((d) => (d ? "● dnd" : "○ live"))}
      />
    </box>
  )
}
