import { createPoll } from "ags/time"

export default function Clock() {
  const hm = createPoll("", 1000, ["date", "+%I:%M %p"])
  const date = createPoll("", 30000, ["date", "+%a %d %b"])

  return (
    <box cssClasses={["clockbox"]} spacing={10}>
      <label cssClasses={["clock-date"]} label={date} />
      <label cssClasses={["clock-sep"]} label="│" />
      <label cssClasses={["clock-hm"]} label={hm} />
    </box>
  )
}
