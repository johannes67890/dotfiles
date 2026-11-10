import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.components
import qs.services

// Centered player; controls use the same glyphs as the Spotify "text" theme.
Item {
    id: page
    readonly property var p: Media.player

    Title { text: "MEDIA" + (page.p ? " · " + page.p.identity.toUpperCase() : "") }
    Label { anchors.centerIn: parent; visible: !page.p; text: "NOTHING IS PLAYING" }

    Column {
        visible: !!page.p
        anchors.centerIn: parent
        width: 460
        spacing: 12

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 230; height: 230; radius: 10
            color: Style.raised
            border.color: Style.line
            clip: true
            Image { anchors.fill: parent; anchors.margins: 1; source: page.p?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop }
        }
        Value {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: page.p?.trackTitle || "—"
            font.pixelSize: 18
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: [page.p?.trackArtist, page.p?.trackAlbum].filter(s => s).join(" · ").toUpperCase()
        }

        // seek bar, like the Spotify theme's: dark track, light fill, time in the middle
        Rectangle {
            id: seek
            visible: page.p?.lengthSupported ?? false
            width: parent.width; height: 18; radius: 4
            color: Style.raised
            readonly property real ratio: page.p && page.p.length > 0 ? Math.min(1, page.p.position / page.p.length) : 0
            Rectangle { width: parent.width * seek.ratio; height: parent.height; radius: 4; color: Style.line }
            Rectangle { x: Math.max(0, parent.width * seek.ratio - 2); width: 3; height: parent.height; color: Style.fg }
            Text {
                anchors.centerIn: parent
                text: Media.time(page.p?.position ?? 0) + " / " + Media.time(page.p?.length ?? 0)
                color: Style.dim
                font.family: Style.font
                font.pixelSize: 11
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function set(mx) { if (page.p?.canSeek) page.p.position = Math.max(0, Math.min(1, mx / width)) * page.p.length }
                onPressed: mouse => set(mouse.x)
                onPositionChanged: mouse => set(mouse.x)
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            GlyphButton {
                glyph: "⇄"
                visible: page.p?.shuffleSupported ?? false
                active: page.p?.shuffle ?? false
                onClicked: page.p.shuffle = !page.p.shuffle
            }
            GlyphButton { glyph: "◁"; enabled: page.p?.canGoPrevious ?? false; onClicked: page.p.previous() }
            GlyphButton { glyph: page.p?.isPlaying ? "❚❚" : "▶"; size: 28; onClicked: page.p.togglePlaying() }
            GlyphButton { glyph: "▷"; enabled: page.p?.canGoNext ?? false; onClicked: page.p.next() }
            GlyphButton {
                // off -> playlist -> track
                glyph: page.p?.loopState === MprisLoopState.Track ? "↻1" : "↻"
                visible: page.p?.loopSupported ?? false
                active: (page.p?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                onClicked: page.p.loopState = page.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : page.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
    }
}
