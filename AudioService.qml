pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: sink?.audio ?? null
    readonly property var sourceAudio: source?.audio ?? null

    readonly property bool sinkAvailable: sinkAudio !== null
    readonly property bool sourceAvailable: sourceAudio !== null
    readonly property bool sinkMuted: sinkAudio?.muted ?? false
    readonly property bool sourceMuted: sourceAudio?.muted ?? false
    readonly property int sinkVolume: Math.round((sinkAudio?.volume ?? 0) * 100)
    readonly property int sourceVolume: Math.round((sourceAudio?.volume ?? 0) * 100)

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink, root.source].filter(object => object !== null)
    }

    function toggleSinkMute(): void {
        if (sinkAudio)
            sinkAudio.muted = !sinkAudio.muted
    }

    function toggleSourceMute(): void {
        if (sourceAudio)
            sourceAudio.muted = !sourceAudio.muted
    }

    function openMixer(tab): void {
        Quickshell.execDetached(["pavucontrol", "-t", tab.toString()])
    }
}
