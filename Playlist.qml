import QtQuick 2.1

Rectangle {
    id: playlistPanel
    state: "active"
    opacity: 1

    property var currentItem
    property string tabId: "local"
    property bool expanded: width == program_constants.playlistWidth
    property url currentPlayingSource

    signal showingAnimationDone
    signal hidingAnimationDone
    signal newSourceSelected (string path)

    states: [
        State {
            name: "active"
            PropertyChanges { target: playlistPanel; color: "#1D1D1D"; opacity: 1 }
            PropertyChanges { target: hidePlaylistButton; source: "image/playlist_button_active_background.png"}
        },
        State {
            name: "inactive"
            PropertyChanges { target: playlistPanel; color: "#000000"; opacity: 0.9 }
            PropertyChanges { target: hidePlaylistButton; source: "image/playlist_button_inactive_background.png"}
        }
    ]

    onStateChanged: {
        if (state == "inactive") {
            hide_timer.restart()
        } else {
            hide_timer.stop()
        }
    }

    function show() {
        if (!expanded) {
            visible = true
            showingPlaylistPanelAnimation.restart()
        }
    }

    function hide() {
        if (expanded) {
            hidingPlaylistPanelAnimation.restart()
        }
    }

    function getContent(type) {
        if (type == "network") {
            return network_playlist.getContent()
        } else {
            return local_playlist.getContent()
        }
    }

    function addItem(playlistType, item) {
        if (playlistType == "network") {
            network_playlist.addItem(item)
        } else {
            local_playlist.addItem(item)
        }
    }
    
    function clear() {
        print(playlistPanel.tabId)
        if (playlistPanel.tabId == "local") {
            local_playlist.clear()
            database.playlist_local = ""
        } else {
            network_playlist.cleart()
            database.playlist_network = ""
        }
    }
    
    function getNextSource() {
        // if (local_playlist.isSelected) {
        //     return local_playlist.getNextSource()
        // } else {
        //     return network_playlist.getNextSource()
        // }
        return local_playlist.getNextSource()
    }

    Timer {
        id: hide_timer
        interval: 5000
        repeat: false

        onTriggered: hidingPlaylistPanelAnimation.start()
    }

    PropertyAnimation {
        id: showingPlaylistPanelAnimation
        alwaysRunToEnd: true

        target: playlistPanel
        property: "width"
        to: program_constants.playlistWidth
        duration: 100
        easing.type: Easing.OutQuint

        onStopped: {
            playlistPanel.showingAnimationDone()
            playlistPanel.state = "active"
        }
    }

    PropertyAnimation {
        id: hidingPlaylistPanelAnimation
        alwaysRunToEnd: true

        target: playlistPanel
        property: "width"
        to: 0
        duration: 100
        easing.type: Easing.OutQuint

        onStopped: {
            playlistPanel.hidingAnimationDone()
            playlistPanel.visible = false
        }
    }

    MouseArea {
        id: playlistPanelArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            playlistPanel.state = "active"
        }

        onExited: {
            playlistPanel.state = "inactive"
        }

        onClicked: {
            console.log("Click on playlist.")
        }
    }

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottom_rect.top

        Item {
            id: tabs
            Item {
                property string name: "本地列表"
                property string type: "local"
            }
            
            Item {
                property string name: "网络列表"
                property string type: "network"
            }
        }

        Row {
            id: tabRow

            height: 50
            anchors.leftMargin: spacing
            width: parent.width

            property int tabWidth: width / tabs.children.length

            Repeater {
                model: tabs.children.length
                delegate: Item {
                    height: parent.height
                    width: tabRow.tabWidth

                    Rectangle {
                        anchors.fill: parent
                        color: tabId == tabs.children[index].type ? program_constants.bgDarkColor : "transparent"
                        radius: 2
                        anchors.margins: 12

                        Text {
                            text: tabs.children[index].name
                            color: tabId == tabs.children[index].type ? "#FACA57" : "#B4B4B4"
                            font { pixelSize: 13 }
                            anchors.centerIn: parent
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            tabId = tabs.children[index].type
                        }
                    }
                }
            }
        }

        PlaylistView {
            id: local_playlist
            width: 190
            root: local_playlist
            visible: playlistPanel.expanded && tabId == "local"
            currentPlayingSource: playlistPanel.currentPlayingSource

            onNewSourceSelected: {
                playlistPanel.newSourceSelected(path)
            }

            Component.onCompleted: initializeWithContent(database.playlist_local)
        }
    }

    Rectangle {
        id: bottom_rect
        width: parent.width
        height: 24
        color: program_constants.bgDarkColor
        anchors.bottom: parent.bottom

        ClearButton {
            id: clear_button
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter

            onEntered: playlist.state = "active"
            onClicked: playlist.clear()
        }
    }

    Image {
        id: hidePlaylistButton
        source: "image/playlist_button_active_background.png"
        anchors.left: playlistTopline.left
        anchors.leftMargin: 1
        anchors.verticalCenter: playlistPanel.verticalCenter
        opacity: playlistPanel.opacity + 0.1

        Image {
            id: hidePlaylistArrow
            source: "image/playlist_button_arrow.png"
            anchors.right: parent.right
            anchors.rightMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            opacity: playlistPanel.opacity
        }

        MouseArea {
            id: hidePlaylistButtonArea
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.left: hidePlaylistArrow.left
            hoverEnabled: true

            onClicked: {
                hidingPlaylistPanelAnimation.restart()
            }

            onEntered: {
                playlistPanel.state = "active"
            }

            onExited: {
                playlistPanel.state = "inactive"
            }
        }
    }

    Rectangle {
        id: playlistTopline
        color: "#060606"
        width: 1
        anchors.top: playlistPanel.top
        anchors.bottom: hidePlaylistButton.top
        anchors.right: playlistPanel.right
        opacity: playlistPanel.opacity
    }

    Rectangle {
        id: playlistBottomline
        color: "#060606"
        width: 1
        anchors.top: hidePlaylistButton.bottom
        anchors.bottom: playlistPanel.bottom
        anchors.right: playlistPanel.right
        opacity: playlistPanel.opacity
    }
}
