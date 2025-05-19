import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: customButton
    property string tooltipText: ""
    property string iconSource: ""

    implicitWidth: 40
    implicitHeight: 40
    icon.width: 20
    icon.height: 20
    icon.source: iconSource
    icon.color: theme.textColor // Assuming 'theme' is accessible or passed down

    background: Rectangle {
        color: customButton.hovered ? Qt.tint(theme.backgroundColor, Qt.rgba(1,1,1,0.1)) : "transparent"
        radius: 4
        border.color: customButton.hovered ? Qt.darker(theme.backgroundColor, 1.3) : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    ToolTip.visible: hovered && tooltipText !== ""
    ToolTip.text: tooltipText
    ToolTip.delay: 500

    // Access theme from a global singleton or a parent item
    // This is a common pattern, adjust if your theme is managed differently
    readonly property var theme: ApplicationWindow.mainWindow ? ApplicationWindow.mainWindow.theme : ({ 
        backgroundColor: "#f0f0f0", 
        textColor: "#333333", 
        primaryColor: "#007bff" 
    })
}