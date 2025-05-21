import QtQuick
import QtQuick.Controls

Rectangle {
    property string text: ""
    property color textColor: parent.parent.parent.parent.parent.parent.theme ? 
                            parent.parent.parent.parent.parent.parent.theme.textColor : "black"
    
    height: 24
    color: Qt.rgba(0.9, 0.9, 0.9, 0.6)
    border.width: 1
    border.color: Qt.rgba(0.8, 0.8, 0.8, 0.8)
    
    Text {
        anchors.fill: parent
        anchors.margins: 4
        text: parent.text
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 12
        color: parent.textColor
    }
} 