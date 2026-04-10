import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"

export default function Clock() {
  const time = createPoll("", 1000, ["date", "+%I:%M %p"])
  return (
    <menubutton cssClasses={["clock"]}>
      <label label={time} />
      <popover>
        <Gtk.Calendar />
      </popover>
    </menubutton>
  )
}
