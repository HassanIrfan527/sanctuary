import { createBinding, With } from "ags"
import AstalMpris from "gi://AstalMpris"

export default function MusicStrip() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <With value={players}>
      {(list) => {
        if (list.length === 0) {
          return (
            <box cssClasses={["musicstrip", "idle"]} spacing={6}>
              <label cssClasses={["musicstrip-cue"]} label="◇" />
              <label cssClasses={["musicstrip-label"]} label="NO SIGNAL" />
            </box>
          )
        }
        const player = list[0]
        const title = createBinding(player, "title")
        const artist = createBinding(player, "artist")
        const status = createBinding(player, "playbackStatus")
        const isPlaying = status(
          (s) => s === AstalMpris.PlaybackStatus.PLAYING,
        )

        return (
          <box cssClasses={["musicstrip"]} spacing={8}>
            <button
              cssClasses={["musicstrip-btn"]}
              onClicked={() => player.previous()}
            >
              <label label="󰒮" />
            </button>
            <button
              cssClasses={isPlaying((p) =>
                p ? ["musicstrip-btn", "play", "live"] : ["musicstrip-btn", "play"],
              )}
              onClicked={() => player.play_pause()}
            >
              <label label={isPlaying((p) => (p ? "" : ""))} />
            </button>
            <button
              cssClasses={["musicstrip-btn"]}
              onClicked={() => player.next()}
            >
              <label label="󰒭" />
            </button>
            <label cssClasses={["musicstrip-sep"]} label="│" />
            <label
              cssClasses={["musicstrip-title"]}
              label={title((t) => (t ? t : "—"))}
              maxWidthChars={28}
              ellipsize={3}
            />
            <label cssClasses={["musicstrip-artist"]} label="·" />
            <label
              cssClasses={["musicstrip-artist"]}
              label={artist((a) => (a ? a : ""))}
              maxWidthChars={18}
              ellipsize={3}
            />
          </box>
        )
      }}
    </With>
  )
}
