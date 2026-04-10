import { createBinding } from "ags"
import AstalHyprland from "gi://AstalHyprland"

const WORKSPACE_COUNT = 5

export default function Workspaces() {
  const hypr = AstalHyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")

  return (
    <box cssClasses={["workspaces"]} spacing={4}>
      {Array.from({ length: WORKSPACE_COUNT }, (_, i) => i + 1).map((id) => (
        <button
          onClicked={() => hypr.dispatch("workspace", `${id}`)}
          cssClasses={focused((f) =>
            f?.id === id ? ["ws", "active"] : ["ws"],
          )}
        >
          <label label={`${id}`} />
        </button>
      ))}
    </box>
  )
}
