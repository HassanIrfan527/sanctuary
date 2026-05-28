import type { Accessor } from "ags"
import type { Result } from "./types"
import KeyPill from "../../ui/KeyPill"

type Props = {
  result: Result
  index: number
  selected: Accessor<number>
  onClick: (i: number) => void
}

export default function ResultRow({ result, index, selected, onClick }: Props) {
  return (
    <button
      cssClasses={selected((s) =>
        s === index ? ["cc-row", "selected"] : ["cc-row"],
      )}
      onClicked={() => onClick(index)}
    >
      <box spacing={10}>
        <image iconName={result.icon || "application-x-executable"} pixelSize={20} cssClasses={["cc-row-icon"]} />
        <box orientation={1} hexpand halign={1}>
          <label label={result.title} cssClasses={["cc-row-title"]} xalign={0} />
          {result.subtitle ? (
            <label
              label={result.subtitle}
              cssClasses={["cc-row-subtitle"]}
              xalign={0}
              maxWidthChars={60}
              ellipsize={3}
            />
          ) : null}
        </box>
        {result.keyhint ? <KeyPill text={result.keyhint} /> : null}
      </box>
    </button>
  )
}
