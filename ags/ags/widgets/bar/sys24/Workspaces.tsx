import { createBinding, createComputed, For } from "ags"
import AstalHyprland from "gi://AstalHyprland"

const MIN_WORKSPACES = 5

export default function Workspaces() {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")
  const workspaces = createBinding(hypr, "workspaces")

  const ids = createComputed(() => {
    const existing = workspaces()
      .map((w) => w.id)
      .filter((id) => id > 0)
    const maxId = existing.length ? Math.max(...existing) : 0
    const count = Math.max(MIN_WORKSPACES, maxId)
    return Array.from({ length: count }, (_, i) => i + 1)
  })

  const occupied = createComputed(() => {
    const set = new Set<number>()
    workspaces().forEach((w) => {
      if (w.clients && w.clients.length > 0) set.add(w.id)
    })
    return set
  })

  return (
    <box cssClasses={["workspaces"]} spacing={2}>
      <For each={ids} id={(id) => id}>
        {(id) => (
          <button
            onClicked={() => hypr.dispatch("workspace", `${id}`)}
            cssClasses={focused((f) =>
              f?.id === id ? ["ws-dot", "active"] : ["ws-dot"],
            )}
          >
            <label
              label={createComputed(() => {
                if (focused()?.id === id) return "▣"
                if (occupied().has(id)) return "▢"
                return "·"
              })}
            />
          </button>
        )}
      </For>
    </box>
  )
}
