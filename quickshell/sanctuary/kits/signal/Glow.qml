import QtQuick
import QtQuick.Effects
import ".."

// KIT (private) · Glow — the neon bloom for a palette with effects. Used as a
// layer effect, so the part stays sharp and the bloom sits behind it:
//
//   layer.enabled: Theme.glow > 0
//   layer.effect: Glow { tint: Theme.sigHot }
//
//   tint      the bloom's colour (usually the part's own)
//   strength  a multiplier on the palette's Theme.glow
//   flickers  follows Theme.flick (the neon stutter, fx "full" only)
MultiEffect {
    property color tint: Theme.sigHot
    property real strength: 1
    property bool flickers: false

    autoPaddingEnabled: true
    shadowEnabled: true
    shadowColor: tint
    shadowBlur: 1
    // A tight radius: a wide blur thins a 1px line's light out to nothing.
    blurMax: Math.round(6 + 10 * Theme.glow * strength)
    shadowOpacity: Math.min(1, (0.75 + 0.5 * Theme.glow) * strength) * (flickers ? Theme.flick : 1)
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
}
