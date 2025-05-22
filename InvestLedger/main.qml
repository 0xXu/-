import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1024
    height: 768
    title: "InvestLedger Application"

    // Theme object (assuming it's available or will be set)
    // property var theme: ThemeController.currentTheme 
    // For demonstration, using placeholder theme values if not globally available
    readonly property color primaryColor: colorScheme.primaryColor ? colorScheme.primaryColor : "#2c3e50"
    readonly property color backgroundColor: colorScheme.backgroundColor ? colorScheme.backgroundColor : "#ffffff"
    readonly property color textColor: colorScheme.textColor ? colorScheme.textColor : "#333333"
    readonly property color secondaryTextColor: colorScheme.secondaryTextColor ? colorScheme.secondaryTextColor : "#7f8c8d"
    readonly property color borderColor: colorScheme.borderColor ? colorScheme.borderColor : "#bdc3c7"
    readonly property color buttonBackgroundColor: colorScheme.buttonBackgroundColor ? colorScheme.buttonBackgroundColor : "#ecf0f1"
    readonly property color buttonTextColor: colorScheme.buttonTextColor ? colorScheme.buttonTextColor : "#2c3e50"
    readonly property color statusBarColor: Qt.lighter(colorScheme.backgroundColor, 1.1) // Slightly lighter than main background
    readonly property color statusBarTextColor: colorScheme.secondaryTextColor

    // Placeholder for your application's main theme/color scheme object
    QtObject {
        id: colorScheme
        property color primaryColor: "#3498db" // Example primary color
        property color backgroundColor: "#f0f3f4" // Example background
        property color textColor: "#2c3e50"      // Example text color
        property color secondaryTextColor: "#7f8c8d"
        property color borderColor: "#dde3e6"
        property color buttonBackgroundColor: "#e1e8eb"
        property color buttonTextColor: "#2c3e50"
    }
    
    // Main content area and status bar layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0 // No space between main content and status bar

        // Placeholder for the rest of your application's UI
        Item {
            id: mainContentArea
            Layout.fillWidth: true
            Layout.fillHeight: true // Takes up all space except status bar
            Text {
                anchors.centerIn: parent
                text: "Main Application Content Goes Here"
                font.pixelSize: 24
                color: mainWindow.textColor
            }
        }

        // Status Bar
        Rectangle {
            id: statusBar
            Layout.fillWidth: true
            Layout.preferredHeight: 28 // Height of the status bar
            color: mainWindow.statusBarColor
            border.color: mainWindow.borderColor
            border.width: 1
            z: 900 // Below dialogs but above main content if overlap occurs

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // Update Progress Bar in Status Bar
                Rectangle {
                    id: statusBarProgressBar
                    width: 150 // Fixed width for the status bar progress bar
                    height: 16
                    Layout.alignment: Qt.AlignVCenter
                    color: Qt.darker(mainWindow.statusBarColor, 1.1) // Slightly darker background for contrast
                    radius: 3
                    visible: false // Initially hidden
                    border.color: Qt.darker(mainWindow.borderColor, 1.1)
                    border.width: 1

                    Rectangle {
                        id: statusBarProgressFill
                        height: parent.height
                        width: 0
                        color: mainWindow.primaryColor
                        radius: 2

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                    }
                }
                
                // Spacer to push copyright to the right if progress bar is visible
                Item {
                    Layout.fillWidth: true
                    visible: !statusBarProgressBar.visible // Takes space only when progress bar is hidden
                }

                Text {
                    id: copyrightText
                    text: "©2023 InvestLedger"
                    font.pixelSize: 11
                    color: mainWindow.statusBarTextColor
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                }
            }
        }
    }

    // 更新进度指示器组件 - 将被添加到底部状态栏
    Component {
        id: updateProgressComponent
        
        Rectangle {
            id: updateProgressBar
            width: 150
            height: 16
            color: Qt.darker(parent.color, 1.05)
            radius: 3
            visible: false
            border.color: Qt.darker(mainWindow.borderColor, 1.1)
            border.width: 1
            
            Rectangle {
                id: progressFill
                height: parent.height - 2
                width: 0
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                color: mainWindow.primaryColor
                radius: 2
                
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: Math.floor(progressFill.width / parent.width * 100) + "%"
                font.pixelSize: 9
                color: "white"
                visible: progressFill.width > 30 // 只在进度条足够宽时显示百分比
            }
            
            // 提供更新进度的方法
            function updateProgress(percentage) {
                if (percentage > 0 && percentage <= 100) {
                    visible = true;
                    progressFill.width = width * (percentage / 100);
                }
            }
            
            // 重置进度条
            function reset() {
                progressFill.width = 0;
                visible = false;
            }
        }
    }

    // Update Notification Dialog - now a direct child of ApplicationWindow
    Dialog {
        id: updateNotifyDialog
        parent: Overlay.overlay // Ensures it's on top of everything within the window
        title: "有新版本可用"
        width: 450
        height: 380
        anchors.centerIn: parent // Centered in Overlay.overlay (effectively the window)
        modal: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: mainWindow.backgroundColor
            radius: 8
            border.color: mainWindow.borderColor
            border.width: 1
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 2; radius: 8.0; samples: 17; color: Qt.rgba(0,0,0,0.15)
            }
        }

        property string updateVersion: ""
        property string updateNotes: ""

        header: Rectangle {
            width: parent.width; height: 50; color: mainWindow.primaryColor; radius: 8
            Rectangle { width: parent.width; height: parent.height / 2; anchors.bottom: parent.bottom; color: mainWindow.primaryColor } // Top corners rounded
            Text { text: "有新版本可用"; color: "white"; font.pixelSize: 18; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 20 }
            Rectangle {
                width: 30; height: 30; radius: 15; color: "transparent"; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
                Text { text: "×"; font.pixelSize: 20; font.bold: true; color: "white"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Qt.rgba(1,1,1,0.1); onExited: parent.color = "transparent"; onClicked: updateNotifyDialog.close() }
            }
        }

        contentItem: ColumnLayout {
            width: parent.width; spacing: 20; anchors.margins: 20
            Rectangle { // Version info
                Layout.fillWidth: true; height: 60; color: Qt.lighter(mainWindow.primaryColor, 1.8); radius: 6
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 15
                    Rectangle { // Icon
                        width: 40; height: 40; radius: 20; color: mainWindow.primaryColor
                        Text { anchors.centerIn: parent; text: "↑"; color: "white"; font.pixelSize: 20; font.bold: true }
                    }
                    Column {
                        spacing: 5; Layout.fillWidth: true
                        Text { text: "发现新版本: v" + updateNotifyDialog.updateVersion; font.pixelSize: 16; font.bold: true; color: mainWindow.textColor }
                        Text { text: "点击下方按钮立即更新获取最新功能和修复"; font.pixelSize: 12; color: mainWindow.secondaryTextColor }
                    }
                }
            }
            Text { text: "更新说明:"; font.pixelSize: 14; font.bold: true; color: mainWindow.textColor }
            Rectangle { // Update notes area
                Layout.fillWidth: true; Layout.fillHeight: true; color: Qt.lighter(mainWindow.backgroundColor, 1.05); border.color: mainWindow.borderColor; border.width: 1; radius: 4
                ScrollView {
                    anchors.fill: parent; anchors.margins: 10; clip: true
                    TextArea { text: updateNotifyDialog.updateNotes; readOnly: true; wrapMode: Text.WordWrap; textFormat: TextFormat.MarkdownText; color: mainWindow.textColor; background: Rectangle { color: "transparent" }; font.pixelSize: 13; leftPadding: 5; rightPadding: 5 }
                }
            }
            RowLayout { // Buttons
                Layout.alignment: Qt.AlignRight; spacing: 10
                Button {
                    text: "稍后更新"; implicitWidth: 100; implicitHeight: 36; onClicked: updateNotifyDialog.close()
                    background: Rectangle { radius: 4; color: parent.down ? Qt.darker(mainWindow.buttonBackgroundColor, 1.1) : parent.hovered ? Qt.lighter(mainWindow.buttonBackgroundColor, 1.1) : mainWindow.buttonBackgroundColor; border.color: mainWindow.borderColor; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                    contentItem: Text { text: parent.text; color: mainWindow.buttonTextColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "下载更新"; implicitWidth: 100; implicitHeight: 36; highlighted: true
                    background: Rectangle { radius: 4; color: parent.down ? Qt.darker(mainWindow.primaryColor, 1.1) : parent.hovered ? Qt.lighter(mainWindow.primaryColor, 1.1) : mainWindow.primaryColor; Behavior on color { ColorAnimation { duration: 150 } } }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: { 
                        backend.downloadUpdate(false); 
                        updateNotifyDialog.close(); 
                        // 创建并显示进度条
                        if (!updateProgressLoader.active) {
                            updateProgressLoader.active = true;
                        }
                        console.log("开始下载更新，底部状态栏将显示进度");
                    }
                }
            }
        }
    }

    // Update Finish Dialog - now a direct child of ApplicationWindow
    Dialog {
        id: updateFinishDialog
        parent: Overlay.overlay // Ensures it's on top
        title: "更新下载完成"
        width: 400
        height: 200
        anchors.centerIn: parent // Centered in Overlay.overlay
        modal: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: mainWindow.backgroundColor; radius: 8; border.color: mainWindow.borderColor; border.width: 1
            layer.enabled: true
            layer.effect: DropShadow { horizontalOffset: 0; verticalOffset: 2; radius: 8.0; samples: 17; color: Qt.rgba(0,0,0,0.15) }
        }
        property bool updateSuccess: false
        header: Rectangle {
            width: parent.width; height: 50; color: updateFinishDialog.updateSuccess ? "#27ae60" : "#e74c3c"; radius: 8
            Rectangle { width: parent.width; height: parent.height / 2; anchors.bottom: parent.bottom; color: parent.color } // Top corners rounded
            Text { text: updateFinishDialog.updateSuccess ? "更新下载完成" : "更新下载失败"; color: "white"; font.pixelSize: 18; font.bold: true; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 20 }
            Rectangle {
                width: 30; height: 30; radius: 15; color: "transparent"; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
                Text { text: "×"; font.pixelSize: 20; font.bold: true; color: "white"; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Qt.rgba(1,1,1,0.1); onExited: parent.color = "transparent"; onClicked: updateFinishDialog.close() }
            }
        }
        contentItem: ColumnLayout {
            width: parent.width; spacing: 20; anchors.margins: 20
            RowLayout {
                spacing: 15; Layout.topMargin: 10
                Rectangle { // Icon
                    width: 40; height: 40; radius: 20; color: updateFinishDialog.updateSuccess ? "#27ae60" : "#e74c3c"
                    Text { anchors.centerIn: parent; text: updateFinishDialog.updateSuccess ? "✓" : "!" ; color: "white"; font.pixelSize: 20; font.bold: true }
                }
                Text { text: updateFinishDialog.updateSuccess ? "更新已下载完成，将在下次启动时自动安装。" : "更新下载失败，请检查网络连接后重试。"; font.pixelSize: 14; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: mainWindow.textColor }
            }
            RowLayout { // Buttons
                Layout.alignment: Qt.AlignRight; spacing: 10; Layout.topMargin: 10
                Button {
                    text: "确定"; implicitWidth: 100; implicitHeight: 36
                    background: Rectangle { radius: 4; color: parent.down ? Qt.darker(mainWindow.buttonBackgroundColor, 1.1) : parent.hovered ? Qt.lighter(mainWindow.buttonBackgroundColor, 1.1) : mainWindow.buttonBackgroundColor; border.color: mainWindow.borderColor; border.width: 1; Behavior on color { ColorAnimation { duration: 150 } } }
                    contentItem: Text { text: parent.text; color: mainWindow.buttonTextColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: updateFinishDialog.close()
                }
                Button {
                    text: "立即重启"; visible: updateFinishDialog.updateSuccess; implicitWidth: 100; implicitHeight: 36
                    background: Rectangle { radius: 4; color: parent.down ? Qt.darker("#27ae60", 1.1) : parent.hovered ? Qt.lighter("#27ae60", 1.1) : "#27ae60"; Behavior on color { ColorAnimation { duration: 150 } } }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: { backend.downloadUpdate(true); }
                }
            }
        }
    }

    // 使用Loader在底部状态栏中加载进度条
    Loader {
        id: updateProgressLoader
        active: false
        sourceComponent: updateProgressComponent
        
        // 这里需要根据您的具体布局设置parent和position
        // 例如，假设底部状态栏有一个ID为statusBarContent的布局容器
        parent: bottomStatusBar ? bottomStatusBar : mainWindow
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    // Connections to backend - direct child of ApplicationWindow
    Connections {
        target: backend // Assuming 'backend' is set as a context property to the QML engine
        function onUpdateAvailable(version, notes) {
            console.log("收到更新通知: 版本 " + version);
            updateNotifyDialog.updateVersion = version;
            updateNotifyDialog.updateNotes = notes;
            updateNotifyDialog.open();
        }
        function onUpdateProgress(percentage) {
            console.log("底部状态栏更新进度: " + percentage + "%");
            
            // 确保进度条已加载
            if (!updateProgressLoader.active) {
                updateProgressLoader.active = true;
            }
            
            // 更新进度
            if (updateProgressLoader.item) {
                updateProgressLoader.item.updateProgress(percentage);
            }
        }
        function onUpdateFinished(success) {
            console.log("更新完成状态: " + (success ? "成功" : "失败"));
            
            // 隐藏进度条
            if (updateProgressLoader.item) {
                updateProgressLoader.item.reset();
            }
            
            // 显示完成对话框
            updateFinishDialog.updateSuccess = success;
            updateFinishDialog.open();
        }
    }
} 