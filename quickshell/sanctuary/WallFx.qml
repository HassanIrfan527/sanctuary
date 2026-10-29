import QtQuick
import Quickshell
import Quickshell.Wayland

// The wallpaper overlay — a sheet laid over the wallpaper, under every window
// (layer "bottom": above awww / mpvpaper on "background", below windows, the
// bar on "top"). Picked in the wallpaper picker (Ctrl+O, or the OVERLAY tab),
// remembered in ~/.local/state/sanctuary/wallfx (Ui.wallFx). It takes no
// input: the pointer passes straight through.
//
//   off        nothing
//   vignette   the edges fall into the dark
//   scanlines  faint CRT lines
//   crt        vignette + scanlines + grain — a screen in Night City
//   haze       vignette + the style's accent rising off the bottom edge
//
// Like Popup.qml it is style-free: it draws only darkness and Theme.accent, so
// it works over any wallpaper, in any style. Everything is static — painted once
// per size / mode / colour — so it costs nothing while you work.
PanelWindow {
    id: fx

    required property var modelData
    screen: modelData

    readonly property string mode: Ui.wallFx
    readonly property bool vignette: mode === "vignette" || mode === "crt" || mode === "haze"
    readonly property bool lines: mode === "scanlines" || mode === "crt"
    readonly property bool grain: mode === "crt"

    visible: mode !== "off"
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sanctuary-wallfx"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}

    Rectangle {   // haze: the accent, rising off the bottom edge
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.45
        visible: fx.mode === "haze"
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0) }
            GradientStop { position: 1; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) }
        }
    }

    Canvas {   // vignette
        anchors.fill: parent
        visible: fx.vignette
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = Math.hypot(width, height) / 2;
            const g = ctx.createRadialGradient(width / 2, height / 2, r * 0.45, width / 2, height / 2, r);
            g.addColorStop(0, Qt.rgba(0, 0, 0, 0));
            g.addColorStop(1, Qt.rgba(0, 0, 0, 0.72));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
    }

    Canvas {   // scanlines: one dark line every 3px
        anchors.fill: parent
        visible: fx.lines
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Qt.rgba(0, 0, 0, 0.28);
            for (let y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1);
        }
    }

    Canvas {   // grain: scattered specks, light and dark
        anchors.fill: parent
        visible: fx.grain
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const n = Math.round(width * height / 30);
            for (let i = 0; i < n; i++) {
                ctx.fillStyle = i % 2 ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.12);
                ctx.fillRect(Math.random() * width, Math.random() * height, 1, 1);
            }
        }
    }
}
