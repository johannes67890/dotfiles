import QtQuick
import qs
import qs.components
import qs.services

// Mail from Thunderbird: what it has synced, newest first.
Item {
    id: page
    Component.onCompleted: { Mail.detail = null; Mail.refresh(true) }
    readonly property bool reading: Mail.detail !== null
    function back() { if (!reading) return false; Mail.detail = null; return true }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: Mail.refresh(true) }

    function when(t) {
        const d = new Date(t * 1000), now = new Date()
        if (d.toDateString() === now.toDateString()) return Qt.formatTime(d, "HH:mm")
        return Qt.formatDate(d, d.getFullYear() === now.getFullYear() ? "d MMM" : "d MMM yyyy").toUpperCase()
    }

    Row {
        id: header
        width: parent.width
        Title {
            width: parent.width - actions.width
            anchors.verticalCenter: parent.verticalCenter
            text: "ACTIVITY · MAIL" + (Mail.unread ? " · " + Mail.unread + " UNREAD" : "")
        }
        Row {
            id: actions
            spacing: 8
            Label { visible: Mail.syncing; text: "SYNCING…"; anchors.verticalCenter: parent.verticalCenter }
            // refresh: let Thunderbird fetch new mail without opening a window
            IconButton { size: 32; code: 0xF0450; idleBorder: Style.line; active: Mail.syncing; onClicked: Mail.sync() }
            Pill { label: "OPEN THUNDERBIRD"; onClicked: { Mail.open(""); Menu.showing = false } }
        }
    }

    Flow {
        id: accounts
        visible: !page.reading
        y: header.height + 12
        width: parent.width
        spacing: 8
        Repeater {
            model: Mail.accounts
            Rectangle {
                required property var modelData
                width: acct.implicitWidth + 24; height: 42; radius: 8
                color: "transparent"
                border.color: Style.line
                Column {
                    id: acct
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    Value { text: parent.parent.modelData.name; font.pixelSize: 11 }
                    Label {
                        font.pixelSize: 9
                        text: (parent.parent.modelData.unread ? parent.parent.modelData.unread + " UNREAD · " : "")
                            + "SYNCED " + Style.ago(Date.now() / 1000 - parent.parent.modelData.synced).toUpperCase() + " AGO"
                    }
                }
            }
        }
    }

    Tabs {
        id: filter
        visible: !page.reading
        y: accounts.y + accounts.height + 12
        model: [{ id: "all", label: "ALL" }, { id: "unread", label: "UNREAD" }]
    }

    ListView {
        id: list
        visible: !page.reading
        y: filter.y + filter.height + 10
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: 2
        model: filter.current === "unread" ? Mail.messages.filter(m => m.unread) : Mail.messages
        delegate: Clickable {
            required property var modelData
            required property int index
            width: ListView.view.width; height: 46; radius: 8
            onClicked: Mail.read(modelData)
            onActiveFocusChanged: if (activeFocus) ListView.view.positionViewAtIndex(index, ListView.Contain)
            Rectangle {
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: parent.modelData.unread ? Style.fg : "transparent"
                border.color: parent.modelData.unread ? Style.fg : Style.line
            }
            Value { x: 28; y: 6; width: parent.width - 28 - 150; text: parent.modelData.from; font.pixelSize: 12; font.bold: parent.modelData.unread }
            Value {
                x: 28; y: 25; width: parent.width - 28 - 150
                text: parent.modelData.subject; font.pixelSize: 11
                color: parent.modelData.unread ? Style.fg : Style.dim
            }
            Label { anchors.right: parent.right; anchors.rightMargin: 12; y: 8; text: page.when(parent.modelData.date) }
            Label { anchors.right: parent.right; anchors.rightMargin: 12; y: 27; width: 130; horizontalAlignment: Text.AlignRight; text: parent.modelData.account; font.pixelSize: 9 }
        }
    }
    Label {
        anchors.centerIn: list
        visible: !page.reading && Mail.updated > 0 && list.count === 0
        text: filter.current === "unread" ? "NO UNREAD MAIL" : "NO MAIL IN THUNDERBIRD'S CACHE · PRESS REFRESH"
    }

    // reader: one mail as plain text
    Item {
        id: reader
        visible: page.reading
        y: header.height + 12
        width: parent.width
        height: parent.height - y
        readonly property var d: Mail.detail ?? {}

        Row {
            id: readerBar
            spacing: 8
            Pill { label: "← BACK"; onClicked: page.back() }
            Pill {
                visible: !!Mail.detail && !Mail.detail.error
                label: "OPEN IN THUNDERBIRD"
                onClicked: { Mail.open(Mail.detail.id); Menu.showing = false }
            }
        }
        Section {
            id: meta
            y: readerBar.height + 10
            pad: 12
            Value { width: parent.width; text: reader.d.subject || ""; font.pixelSize: 15; wrapMode: Text.Wrap; maximumLineCount: 2 }
            KeyValue { key: "FROM"; value: reader.d.from || "" }
            KeyValue { visible: !!reader.d.to; key: "TO"; value: reader.d.to || "" }
            KeyValue { visible: !!reader.d.cc; key: "CC"; value: reader.d.cc || "" }
            KeyValue { visible: !!reader.d.date; key: "DATE"; value: reader.d.date || "" }
            KeyValue {
                visible: (reader.d.attachments ?? []).length > 0
                key: "ATTACHMENTS"
                value: (reader.d.attachments ?? []).join(", ")
            }
        }
        Rectangle {
            y: meta.y + meta.height + 10
            width: parent.width
            height: parent.height - y
            radius: 10
            color: "transparent"
            border.color: Style.line
            Flickable {
                id: scroller
                anchors.fill: parent
                anchors.margins: 14
                clip: true
                contentHeight: bodyText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: bodyText
                    width: scroller.width
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText // never rich text: nothing in a mail gets loaded
                    color: Style.fg
                    selectionColor: Style.line
                    font.family: Style.font
                    font.pixelSize: 12
                    readonly property var d: Mail.detail ?? {}
                    text: d.loading ? "Loading…" : d.error ? d.error : (d.body || "(no text in this mail)")
                }
            }
        }
    }
}
