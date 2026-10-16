import QtQuick
import "kit"

// The music player card — right-click the music module to open it.
//
// It is a full-screen, see-through layer with the card hung under the music
// module. The see-through part is the point: a click ANYWHERE outside the card
// lands on it and closes the card. Layer-shell popups have no "click outside"
// of their own, so this is how one gets it.
//
//   space  play / pause      h ←  previous      l →  next      esc q  close
//   click the progress line to seek (when the player allows it)
Popup {
    id: win

    name: "player"
    open: Ui.playerOpen && Media.hasTrack
    onDismissed: Ui.playerOpen = false
    cardWidth: 380
    // Hung under the music module. Opened without a click (IPC / a keybind)
    // there is no module x, so it sits right, where the module usually is.
    centred: false
    cardX: Math.max(8, Math.min(width - cardWidth - 16, (Ui.playerX > 0 ? Ui.playerX : width) - cardWidth / 2))
    cardY: Theme.barH + 4
    onKeyPressed: event => {
        const k = event.key;
        if (k === Qt.Key_Space)
            Media.toggle();
        else if (k === Qt.Key_H || k === Qt.Key_Left)
            Media.previous();
        else if (k === Qt.Key_L || k === Qt.Key_Right)
            Media.next();
        else
            return;
        event.accepted = true;
    }

    // The track ending / the player quitting closes it too.
    Connections {
        target: Media
        function onHasTrackChanged() {
            if (!Media.hasTrack)
                Ui.playerOpen = false;
        }
    }

    Fade {
        shown: win.visible

        Panel {
            width: parent.width
            pad: 14
            vpad: 14
            inset: 0
            spacing: 10
            headerHeight: 12
            title: (Media.playing ? "PLAY" : "HOLD") + "  ·  " + Media.identity.toUpperCase()
            titleRole: "status"
            titleTone: Media.playing ? "" : "dim"
            headerItems: Label {
                width: implicitWidth
                role: "fine"
                text: "esc"
            }

            Row {
                width: parent.width
                spacing: 12

                Picture {
                    source: Media.art
                }
                Column {
                    width: parent.width - (Media.art !== "" ? 96 : 0)
                    spacing: 4
                    Label {
                        role: "headline"
                        text: Media.title
                    }
                    Label {
                        role: "sub"
                        visible: text !== ""
                        text: Media.artist
                    }
                    Label {
                        role: "note"
                        oneLine: true
                        visible: text !== ""
                        text: Media.album
                    }
                }
            }

            // position: a line you can click to seek
            Column {
                width: parent.width
                spacing: 4
                visible: Media.length > 0
                Progress {
                    value: Media.progress
                    seekable: Media.canSeek
                    onSeek: f => Media.seek(f)
                }
                Item {
                    width: parent.width
                    height: 12
                    Label {
                        width: implicitWidth
                        role: "small"
                        text: Media.clock(Media.position)
                    }
                    Label {
                        anchors.right: parent.right
                        width: implicitWidth
                        role: "small"
                        text: Media.clock(Media.length)
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22
                Button { text: "|◀"; hint: "h"; onClicked: Media.previous() }
                Button { text: Media.playing ? "‖" : "▶"; hint: "spc"; onClicked: Media.toggle() }
                Button { text: "▶|"; hint: "l"; onClicked: Media.next() }
            }

            Item { width: 1; height: 4 }   // room for the key hints
        }
    }
}
