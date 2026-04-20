import { createBinding, With } from "ags"
import { Gtk } from "ags/gtk4"
import AstalMpris from "gi://AstalMpris"

function fmt(sec: number): string {
  if (!sec || sec < 0) return "0:00"
  const m = Math.floor(sec / 60)
  const s = Math.floor(sec % 60)
  return `${m}:${s.toString().padStart(2, "0")}`
}

export default function MusicPlayer() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <With value={players}>
      {(list) => {
        if (list.length === 0) return <label label="No player" />

        const player = list[0]
        const title = createBinding(player, "title")
        const artist = createBinding(player, "artist")
        const status = createBinding(player, "playbackStatus")
        const cover = createBinding(player, "coverArt")
        const position = createBinding(player, "position")
        const length = createBinding(player, "length")

        return (
          <menubutton cssClasses={["player-pill"]}>
            <box spacing={10}>
              <label
                label={status((s) =>
                  s === AstalMpris.PlaybackStatus.PLAYING ? "" : "",
                )}
              />
              <label label={title} />
            </box>

            <popover cssClasses={["player-popover"]}>
              <box cssClasses={["player-content"]} spacing={14}>
                <image
                  file={cover}
                  pixelSize={110}
                  cssClasses={["player-art"]}
                />
                <box
                  orientation={Gtk.Orientation.VERTICAL}
                  cssClasses={["player-info"]}
                  hexpand
                >
                  <label
                    label={title}
                    cssClasses={["player-title"]}
                    xalign={0}
                    maxWidthChars={26}
                    ellipsize={3}
                  />
                  <label
                    label={artist}
                    cssClasses={["player-artist"]}
                    xalign={0}
                    maxWidthChars={26}
                    ellipsize={3}
                  />

                  <box cssClasses={["player-time-row"]}>
                    <label
                      label={position(
                        (p) => `${fmt(p)} / ${fmt(player.length)}`,
                      )}
                      cssClasses={["player-time"]}
                      xalign={0}
                      hexpand
                    />
                    <button
                      cssClasses={["player-play"]}
                      onClicked={() => player.play_pause()}
                    >
                      <label
                        label={status((s) =>
                          s === AstalMpris.PlaybackStatus.PLAYING ? "" : "",
                        )}
                      />
                    </button>
                  </box>

                  <box cssClasses={["player-progress-row"]} spacing={8}>
                    <button
                      cssClasses={["player-skip"]}
                      onClicked={() => player.previous()}
                    >
                      <label label="󰒮" />
                    </button>
                    <slider
                      hexpand
                      cssClasses={["player-progress"]}
                      min={0}
                      max={1}
                      value={position((p) =>
                        player.length > 0 ? p / player.length : 0,
                      )}
                      onChangeValue={({ value }) => {
                        if (player.length > 0)
                          player.position = value * player.length
                      }}
                    />
                    <button
                      cssClasses={["player-skip"]}
                      onClicked={() => player.next()}
                    >
                      <label label="󰒭" />
                    </button>
                  </box>
                </box>
              </box>
            </popover>
          </menubutton>
        )
      }}
    </With>
  )
}
