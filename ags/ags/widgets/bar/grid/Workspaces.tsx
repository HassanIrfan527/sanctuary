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

  return (
    <box cssClasses={["workspaces"]} spacing={4}>
      <label cssClasses={["ws-bracket"]} label="[" />
      <For each={ids} id={(id) => id}>
        {(id) => (
          <button
            onClicked={() => hypr.dispatch("workspace", `${id}`)}
            cssClasses={focused((f) =>
              f?.id === id ? ["ws", "active"] : ["ws"],
            )}
          >
            <label label={id.toString().padStart(2, "0")} />
          </button>
        )}
      </For>
      <label cssClasses={["ws-bracket"]} label="]" />
    </box>
  )
}
