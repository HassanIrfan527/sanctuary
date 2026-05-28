import type { Accessor } from "ags"

export type Mode = "APPS" | "CMD" | "CLIP" | "HELP"

export default function ModeBadge({ mode }: { mode: Accessor<Mode> | Mode }) {
  const label =
    typeof mode === "string"
      ? `[ ${mode} ]`
      : (mode as Accessor<Mode>)((m) => `[ ${m} ]`)
  return <label label={label} cssClasses={["modebadge"]} />
}
