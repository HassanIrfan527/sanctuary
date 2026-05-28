import { createPoll } from "ags/time"
import { createComputed } from "ags"

const ACTIVE_CMD = [
  "bash",
  "-c",
  "hyprctl activewindow -j 2>/dev/null | jq -r '\"\\(.class // \"-\")\\u001f\\(.title // \"\")\"' 2>/dev/null || echo '-\\u001f'",
]

export default function ActiveWindow() {
  const raw = createPoll("-", 600, ACTIVE_CMD)

  const cls = createComputed(() => {
    const r = raw()
    const i = r.indexOf("")
    return i < 0 ? "—" : (r.slice(0, i) || "—").toLowerCase()
  })
  const title = createComputed(() => {
    const r = raw()
    const i = r.indexOf("")
    const t = i < 0 ? "" : r.slice(i + 1)
    if (!t) return ""
    return t.length > 80 ? t.slice(0, 79) + "…" : t
  })

  return (
    <box cssClasses={["activewindow", "aw-embed"]} spacing={6}>
      <label cssClasses={["aw-class"]} label={cls} />
      <label cssClasses={["aw-sep"]} label="·" />
      <label cssClasses={["aw-title"]} label={title} ellipsize={3} maxWidthChars={70} />
    </box>
  )
}
