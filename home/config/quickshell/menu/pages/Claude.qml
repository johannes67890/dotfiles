import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Item {
    id: page
    readonly property var d: ClaudeUsage.data

    component Stat: Column {
        property string name
        property string value
        property string sub: ""
        spacing: 2
        Label { text: parent.name; font.pixelSize: 9 }
        Value { text: parent.value; font.pixelSize: 15; width: parent.width }
        Label { visible: !!parent.sub; text: parent.sub; font.pixelSize: 9; width: parent.width }
    }
    component Ranked: Row {
        property string name
        property real value
        property real maxValue: 1
        property string text
        spacing: 10
        Value { width: 210; text: parent.name; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        Bar { width: parent.width - 210 - 150 - 20; anchors.verticalCenter: parent.verticalCenter; value: parent.value / Math.max(1, parent.maxValue) }
        Value { width: 150; horizontalAlignment: Text.AlignRight; text: parent.text; font.pixelSize: 11 }
    }

    // header
    Row {
        id: header
        width: parent.width
        spacing: 10
        ClaudeLogo { width: 22; height: 22; anchors.verticalCenter: parent.verticalCenter }
        Title { text: "CLAUDE"; anchors.verticalCenter: parent.verticalCenter }
        Label { text: page.d.model ? "· " + page.d.model.replace("claude-", "").toUpperCase() : ""; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        visible: tabs.current === "chat"
        anchors.right: parent.right
        spacing: 8
        Pill { visible: Claude.busy; label: "STOP"; onClicked: Claude.stop() }
        Pill { label: "NEW CHAT"; onClicked: Claude.newChat() }
    }
    Component.onCompleted: { ClaudeUsage.refresh(); useTab() }
    // A tab asked for over IPC (open page/tab); cleared so it doesn't stick to later visits.
    function useTab() { if (tabs.model.some(t => t.id === Menu.tab)) tabs.current = Menu.tab; if (Menu.tab) Menu.tab = "" }
    Connections { target: Menu; function onTabChanged() { page.useTab() } }
    Tabs {
        id: tabs
        y: header.height + 14
        model: [
            { id: "chat", label: "CHAT" }, { id: "overview", label: "OVERVIEW" }, { id: "activity", label: "ACTIVITY" },
            { id: "projects", label: "PROJECTS & MODELS" }, { id: "tools", label: "TOOLS & SESSIONS" }
        ]
    }
    Label {
        anchors.right: parent.right
        y: 6
        visible: tabs.current !== "chat"
        font.pixelSize: 9
        text: "LOCAL USAGE · PLAN LIMITS ONLY IN /usage"
    }

    Item {
        id: body
        y: tabs.y + tabs.height + 12
        width: parent.width
        height: parent.height - y

        // CHAT
        Item {
            visible: tabs.current === "chat"
            anchors.fill: parent
            Row {
                id: models
                spacing: 8
                Label { text: "MODEL"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                Tabs {
                    model: [
                        { id: "", label: "DEFAULT" }, { id: "fable", label: "FABLE" }, { id: "opus", label: "OPUS" },
                        { id: "sonnet", label: "SONNET" }, { id: "haiku", label: "HAIKU" }
                    ]
                    current: Settings.claudeModel
                    onCurrentChanged: Settings.claudeModel = current
                }
            }
            Rectangle {
                y: models.height + 10
                width: parent.width
                height: parent.height - y - input.height - 12
                radius: 10
                color: "transparent"
                border.color: Style.line
                Label {
                    anchors.centerIn: parent
                    visible: Claude.messages.length === 0 && !Claude.busy
                    text: "ASK ANYTHING · ANSWERS USE YOUR CLAUDE PLAN"
                }
                ListView {
                    id: chat
                    anchors.fill: parent
                    anchors.margins: 14
                    clip: true
                    spacing: 14
                    model: Claude.messages
                    onCountChanged: Qt.callLater(positionViewAtEnd)
                    delegate: Column {
                        required property var modelData
                        readonly property bool answer: modelData.role === "claude"
                        width: ListView.view.width
                        spacing: 4
                        Label { visible: parent.modelData.role !== "note"; text: parent.answer ? "CLAUDE" : "YOU"; font.pixelSize: 9 }
                        TextEdit {
                            width: parent.width
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: parent.answer && parent.modelData.html ? TextEdit.RichText : TextEdit.PlainText
                            // Plain text until quickshell-md has formatted it: Qt's own Markdown view would load
                            // images and backgrounds from URLs in the answer, which can carry web content.
                            text: parent.answer && parent.modelData.html ? parent.modelData.html : parent.modelData.text
                            onLinkActivated: link => { if (/^https?:\/\//.test(link)) Qt.openUrlExternally(link) }
                            color: parent.answer ? Style.fg : Style.dim
                            selectionColor: Style.line
                            font.family: Style.font
                            font.pixelSize: 12
                        }
                    }
                    footer: Label {
                        visible: Claude.busy || !!Claude.error
                        topPadding: 14
                        width: chat.width
                        wrapMode: Text.Wrap
                        text: Claude.busy ? "THINKING…" : Claude.error
                    }
                }
            }
            Rectangle {
                id: input
                y: parent.height - height
                width: parent.width; height: 40
                radius: 10
                color: "transparent"
                border.color: field.activeFocus ? Style.lineActive : Style.line
                Field {
                    id: field
                    x: 14; width: parent.width - 28
                    anchors.verticalCenter: parent.verticalCenter
                    focus: true
                    readOnly: Claude.busy
                    font.pixelSize: 13
                    placeholder: Claude.busy ? "WAITING FOR CLAUDE…" : Claude.messages.length ? "FOLLOW-UP…" : "ASK CLAUDE A QUICK QUESTION"
                    onAccepted: { Claude.ask(text); text = "" }
                }
            }
        }

        // OVERVIEW
        Column {
            visible: tabs.current === "overview"
            width: parent.width
            spacing: 12
            Grid {
                columns: 4
                spacing: 12
                width: parent.width
                Repeater {
                    model: [
                        { name: "LAST 5 H", u: page.d.h5 }, { name: "TODAY", u: page.d.today },
                        { name: "7 DAYS", u: page.d.week }, { name: "30 DAYS", u: page.d.month }
                    ]
                    Section {
                        id: card
                        required property var modelData
                        width: (body.width - 36) / 4
                        pad: 12
                        Label { text: card.modelData.name }
                        Column {
                            spacing: 0
                            Value { text: ClaudeUsage.tokens(card.modelData.u.out); font.pixelSize: 20 }
                            Label { text: "OUTPUT TOKENS"; font.pixelSize: 9 }
                        }
                        KeyValue { key: "MESSAGES"; value: card.modelData.u.msgs }
                        KeyValue { key: "SESSIONS"; value: card.modelData.u.sessions }
                        KeyValue { key: "INPUT"; value: ClaudeUsage.tokens(card.modelData.u.input) }
                    }
                }
            }
            Section {
                pad: 12
                Grid {
                    columns: 4
                    width: parent.width
                    Stat { width: parent.width / 4; name: "CACHE HIT · 7 D"; value: Math.round(page.d.cacheHit * 100) + "%"; sub: "OF INPUT FROM CACHE" }
                    Stat { width: parent.width / 4; name: "WEB SEARCHES · 7 D"; value: String(page.d.webSearches) }
                    Stat { width: parent.width / 4; name: "LATEST MODEL"; value: page.d.model.replace("claude-", "") }
                    Stat { width: parent.width / 4; name: "UPDATED"; value: ClaudeUsage.updated ? Qt.formatTime(new Date(ClaudeUsage.updated), "HH:mm:ss") : "…" }
                }
            }
            Section {
                pad: 12
                Label { text: "OUTPUT TOKENS · LAST 30 DAYS" }
                Graph {
                    width: parent.width; height: 140
                    bars: true
                    values: page.d.daily.map(x => x.out)
                    labels: page.d.daily.map(x => x.label)
                    labelEvery: 5
                    format: ClaudeUsage.tokens
                }
            }
        }

        // ACTIVITY
        Column {
            visible: tabs.current === "activity"
            width: parent.width
            spacing: 12
            Section {
                pad: 12
                Row {
                    width: parent.width
                    Label { width: parent.width - peakH.width; text: "OUTPUT TOKENS PER HOUR · LAST 24 H" }
                    Label { id: peakH; text: "PEAK " + ClaudeUsage.tokens(Math.max(0, ...page.d.hourly.map(x => x.out))) }
                }
                Graph {
                    width: parent.width; height: 160
                    bars: true
                    values: page.d.hourly.map(x => x.out)
                    labels: page.d.hourly.map(x => x.label)
                    labelEvery: 3
                    format: ClaudeUsage.tokens
                }
            }
            Section {
                pad: 12
                Row {
                    width: parent.width
                    Label { width: parent.width - peakD.width; text: "MESSAGES PER DAY · LAST 30 DAYS" }
                    Label { id: peakD; text: "PEAK " + Math.max(0, ...page.d.daily.map(x => x.msgs)) }
                }
                Graph {
                    width: parent.width; height: 160
                    bars: true
                    values: page.d.daily.map(x => x.msgs)
                    labels: page.d.daily.map(x => x.label)
                    labelEvery: 5
                }
            }
        }

        // PROJECTS & MODELS
        Column {
            visible: tabs.current === "projects"
            width: parent.width
            spacing: 12
            Section {
                pad: 14
                Label { text: "PROJECTS · 30 DAYS · OUTPUT TOKENS" }
                Repeater {
                    model: page.d.projects
                    Ranked {
                        required property var modelData
                        width: parent.width
                        name: modelData.name
                        value: modelData.out
                        maxValue: page.d.projects[0]?.out ?? 1
                        text: ClaudeUsage.tokens(modelData.out) + " · " + modelData.msgs + " msgs"
                    }
                }
            }
            Section {
                pad: 14
                Label { text: "MODELS · 30 DAYS" }
                Repeater {
                    model: page.d.models
                    Ranked {
                        required property var modelData
                        width: parent.width
                        name: modelData.name.replace("claude-", "")
                        value: modelData.out
                        maxValue: page.d.models[0]?.out ?? 1
                        text: ClaudeUsage.tokens(modelData.out) + " · " + modelData.msgs + " msgs"
                    }
                }
            }
        }

        // TOOLS & SESSIONS
        Row {
            visible: tabs.current === "tools"
            width: parent.width
            spacing: 12
            Section {
                width: 300
                pad: 14
                Label { text: "TOOL CALLS · 30 DAYS" }
                Repeater {
                    model: page.d.tools
                    Row {
                        required property var modelData
                        width: parent.width
                        spacing: 8
                        Value { width: 110; text: parent.modelData.name; font.pixelSize: 11 }
                        Bar { width: parent.width - 110 - 50 - 16; anchors.verticalCenter: parent.verticalCenter; value: parent.modelData.count / Math.max(1, page.d.tools[0]?.count ?? 1) }
                        Value { width: 50; horizontalAlignment: Text.AlignRight; text: parent.modelData.count; font.pixelSize: 11 }
                    }
                }
                Label { text: "WEB SEARCHES · 7 D · " + page.d.webSearches }
            }
            Section {
                width: body.width - 312
                pad: 14
                Label { text: "RECENT SESSIONS" }
                Repeater {
                    model: page.d.sessions
                    Row {
                        id: sess
                        required property var modelData
                        width: parent.width
                        spacing: 8
                        Column {
                            width: parent.width - copy.width - 8
                            Value { width: parent.width; text: (sess.modelData.cwd ?? "?").replace(/^\/home\/[^/]+/, "~"); font.pixelSize: 11 }
                            Label {
                                font.pixelSize: 9
                                text: Style.ago(Date.now() / 1000 - sess.modelData.last).toUpperCase() + " AGO · " + sess.modelData.msgs + " MSGS · " + ClaudeUsage.tokens(sess.modelData.out) + " OUT"
                            }
                        }
                        Pill {
                            id: copy
                            label: "COPY RESUME"
                            textSize: 9
                            padding: 16
                            implicitHeight: 26
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: Quickshell.execDetached(["wl-copy", "cd '" + String(sess.modelData.cwd).replace(/'/g, "'\\''") + "' && claude --resume " + sess.modelData.id])
                        }
                    }
                }
            }
        }
    }
}
