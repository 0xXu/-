import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: navButton
    property bool selected: false
    property string text: ""
    property string iconName: ""
    signal clicked()
    
    Layout.fillWidth: true
    height: 50
    color: selected ? Qt.lighter(primaryColor, 1.2) : "transparent"
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        spacing: 10
        
        Rectangle {
            width: 24
            height: 24
            color: "transparent"
            // 实际项目中这里应该使用真实图标
            Text {
                anchors.centerIn: parent
                text: {
                    if (iconName === "dashboard") return "📊";
                    if (iconName === "list") return "📝";
                    if (iconName === "chart") return "📈";
                    if (iconName === "import") return "📥";
                    if (iconName === "settings") return "⚙️";
                    return "•";
                }
                font.pixelSize: 18
                color: "white"
            }
        }
        
        Text {
            text: navButton.text
            color: "white"
            font.pixelSize: 14
        }
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        property bool pressedAnim: false
        onEntered: if (!selected) parent.color = Qt.lighter(primaryColor, 1.4)
        onExited: if (!selected) parent.color = "transparent"
        onClicked: parent.clicked()
        onPressedChanged: {
            pressedAnim = pressed;
            if (pressedAnim) {
                parent.scale = 0.96;
                parent.opacity = 0.85;
            } else {
                parent.scale = 1.0;
                parent.opacity = 1.0;
            }
        }
    }
    Behavior on color {
        ColorAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
    }
    Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.InOutQuad }
    }
}