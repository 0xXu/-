import QtQuick
import QtQuick.Controls

Rectangle {
    property string text: ""
    property color bgColor: parent.parent.parent.parent.parent.parent.buttonBgColor
    
    height: 26
    color: bgColor
    border.width: 1
    border.color: Qt.darker(bgColor, 1.2)
    
    Text {
        anchors.fill: parent
        anchors.margins: 4
        text: parent.text
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 12
        font.bold: true
        color: "white"
    }
} 