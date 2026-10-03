import QtQuick
import QtQuick.Shapes

// The outline of a speech bubble, drawn once as the face and once as the
// shadow (InkBubble stacks two of these). Two outlines:
//
//   talk   a rounded box with a tail out of the top edge, pointing up at the
//          bar — the toast is the bar "speaking"
//   shout  a zigzag box, for critical notifications. In manga a spiky balloon
//          is a scream; here it means the same thing.
//
// The tail rises ABOVE y=0 by `tail` px and spikes stick out by `spike` px, so
// the parent leaves that much room.
Shape {
    id: root

    property color fill: Theme.paper
    property color stroke: Theme.inkLine
    property real strokeWidth: Theme.inkStroke
    property bool shout: false
    property real tail: 12
    property real tailX: width - 46     // where the tail meets the top edge
    readonly property real r: 14
    readonly property real spike: 7

    preferredRendererType: Shape.CurveRenderer

    function zigzag(w, h) {
        const pts = [];
        const step = 16;
        const edge = (x0, y0, x1, y1, nx, ny) => {
            const n = Math.max(2, Math.round(Math.hypot(x1 - x0, y1 - y0) / step));
            for (let i = 0; i < n; i++) {
                const t = i / n;
                const out = (i % 2) ? spike : 0;
                pts.push(Qt.point(x0 + (x1 - x0) * t + nx * out, y0 + (y1 - y0) * t + ny * out));
            }
        };
        edge(0, 0, w, 0, 0, -1);
        edge(w, 0, w, h, 1, 0);
        edge(w, h, 0, h, 0, 1);
        edge(0, h, 0, 0, -1, 0);
        pts.push(pts[0]);
        return pts;
    }

    // talk
    ShapePath {
        fillColor: root.shout ? "transparent" : root.fill
        strokeColor: root.shout ? "transparent" : root.stroke
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        startX: root.r
        startY: 0

        PathLine { x: root.tailX - 22; y: 0 }
        PathLine { x: root.tailX + 8; y: -root.tail }   // tip leans right, toward the bar's corner
        PathLine { x: root.tailX - 6; y: 0 }
        PathLine { x: root.width - root.r; y: 0 }
        PathArc { x: root.width; y: root.r; radiusX: root.r; radiusY: root.r }
        PathLine { x: root.width; y: root.height - root.r }
        PathArc { x: root.width - root.r; y: root.height; radiusX: root.r; radiusY: root.r }
        PathLine { x: root.r; y: root.height }
        PathArc { x: 0; y: root.height - root.r; radiusX: root.r; radiusY: root.r }
        PathLine { x: 0; y: root.r }
        PathArc { x: root.r; y: 0; radiusX: root.r; radiusY: root.r }
    }

    // shout
    ShapePath {
        fillColor: root.shout ? root.fill : "transparent"
        strokeColor: root.shout ? root.stroke : "transparent"
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin

        PathPolyline { path: root.zigzag(root.width, root.height) }
    }
}
