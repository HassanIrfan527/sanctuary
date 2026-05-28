import { createBinding, With } from "ags"
import AstalMpris from "gi://AstalMpris"

export default function Media() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <With value={players}>
      {(list) => {
        if (list.length === 0) {
          return (
            <box cssClasses={["media", "idle"]} spacing={6}>
              <label cssClasses={["media-glyph"]} label="◇" />
              <label cssClasses={["media-idle"]} label="no signal" />
            </box>
          )
        }
        const player = list[0]
        const title = createBinding(player, "title")
        const artist = createBinding(player, "artist")
        const status = createBinding(player, "playbackStatus")
        const isPlaying = status((s) => s === AstalMpris.PlaybackStatus.PLAYING)

        return (
          <box cssClasses={["media"]} spacing={6}>
            <button cssClasses={["media-btn"]} onClicked={() => player.previous()}>
              <label label="«" />
            </button>
            <button
              cssClasses={isPlaying((p) => (p ? ["media-btn", "play", "lit"] : ["media-btn", "play"]))}
              onClicked={() => player.play_pause()}
            >
              <label label={isPlaying((p) => (p ? "▶" : "‖"))} />
            </button>
            <button cssClasses={["media-btn"]} onClicked={() => player.next()}>
              <label label="»" />
            </button>
            <label cssClasses={["media-sep"]} label="│" />
            <label
              cssClasses={["media-title"]}
              label={title((t) => t || "—")}
              maxWidthChars={20}
              ellipsize={3}
            />
            <label cssClasses={["media-dot"]} label="·" />
            <label
              cssClasses={["media-artist"]}
              label={artist((a) => a || "")}
              maxWidthChars={14}
              ellipsize={3}
            />
          </box>
        )
      }}
    </With>
  )
}
