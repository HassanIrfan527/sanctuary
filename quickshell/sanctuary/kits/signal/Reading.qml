import QtQuick
import ".."

// KIT · Reading — a load as a number (CPU 12%), coloured by how high it is:
// the style's thresholds live here (Signal: warn from 65%, alarm from 85%).
Text {
    property real level: 0          // 0..1

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    font.family: Theme.mono
    font.pixelSize: 11
    color: level >= 0.85 ? Theme.sigAlarm : level >= 0.65 ? Theme.sigWarn : Theme.sigValue
}
