import type { Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import ModeBadge from "../../ui/ModeBadge"
import type { Mode } from "./types"

type Props = {
  mode: Accessor<Mode>
  count: Accessor<number>
  onChange: (text: string) => void
  onActivate: () => void
  onKey: (keyval: number, state: number) => boolean
  entryRef: { current: Gtk.Entry | null }
}

export default function SearchRow({ mode, count, onChange, onActivate, onKey, entryRef }: Props) {
  return (
    <box orientation={1}>
      <box cssClasses={["cc-title-row"]}>
        <label cssClasses={["cc-title"]} label="GRID COMMAND CENTER" xalign={0} hexpand />
        <ModeBadge mode={mode} />
      </box>

      <box cssClasses={["cc-search-row"]}>
        <box cssClasses={["cc-search-box"]} hexpand spacing={0}>
          <label cssClasses={["cc-search-icon"]} label="" />
          <entry
            cssClasses={["cc-input"]}
            placeholderText="Type a command..."
            hexpand
            onNotifyText={(self) => onChange(self.text)}
            onActivate={() => onActivate()}
            $={(self) => {
              entryRef.current = self
              const ctrl = new Gtk.EventControllerKey()
              ctrl.connect("key-pressed", (_c, keyval, _kc, state) =>
                onKey(keyval, state),
              )
              self.add_controller(ctrl)
            }}
          />
          <label
            cssClasses={["cc-counter"]}
            label={count((c) => `${c.toString().padStart(2, "0")}`)}
          />
        </box>
      </box>
    </box>
  )
}
