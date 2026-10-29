import QtQuick
import ".."

// KIT · Value — what a bar cell reads (00:42, LIVE, 04).
//   tone   "" value | "hot" | "warn" | "alarm" | "dim" | "soft" | "second"
//   strong bold (a state word) · size "" | "small" | "glyph"
Text {
    id: val
    property string tone: ""
    property bool strong: false
    property string size: ""

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    font.family: Theme.mono
    font.pixelSize: size === "glyph" ? 12 : size === "small" ? 10 : 11
    font.weight: strong ? Font.Bold : Font.Normal
    color: tone === "hot" ? Theme.sigHot : tone === "warn" ? Theme.sigWarn : tone === "alarm" ? Theme.sigAlarm
         : tone === "dim" ? Theme.surface2 : tone === "soft" ? Theme.subtext0 : tone === "second" ? Theme.peach
         : Theme.sigValue
    layer.enabled: Theme.glow > 0 && (tone === "hot" || tone === "alarm")
    layer.effect: Glow { tint: val.color; strength: 0.8 }
}
