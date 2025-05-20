import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects

Window {
    id: userSelectWindow
    visible: true
    width: 800
    height: 600
    title: qsTr("InvestLedger - 用户选择")
    
    // 引用主窗口和主题管理器
    property var mainWindow
    property var theme
    
    // 错误对话框实例
    property var errorDialog

    // 默认位置居中
    Component.onCompleted: {
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        
        // 加载用户列表
        loadUserList();
    }
    
    // 函数：加载用户列表
    function loadUserList() {
        try {
            var users = backend.getUsers();
            userListModel.clear();
            for (var i = 0; i < users.length; i++) {
                userListModel.append({name: users[i].name});
            }
            if (userListModel.count > 0) {
                userListView.currentIndex = 0;
            }
        } catch (e) {
            console.error("Error loading user list:", e);
            if (errorDialog) {
                errorDialog.showError(qsTr("加载用户列表时发生错误: ") + e);
            }
        }
    }

    // 背景颜色
    Rectangle {
        anchors.fill: parent
        color: theme ? theme.backgroundColor : "#f5f5f5"
    }

    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 标题
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: theme ? Qt.lighter(theme.primaryColor, 1.1) : "#2196F3"
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 6

                Text {
                    text: qsTr("欢迎使用 InvestLedger")
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("请选择一个用户配置文件，或创建一个新用户")
                    font.pixelSize: 14
                    color: "white"
                    opacity: 0.9
                    Layout.fillWidth: true
                }
            }
        }

        // 用户列表和创建用户的卡片
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: theme ? theme.cardColor : "white"
            radius: 10
            
            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8.0
                color: "#40000000"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // 用户列表标题
                Text {
                    text: qsTr("用户列表")
                    font.pixelSize: 18
                    font.bold: true
                    color: theme ? theme.textColor : "#333333"
                }

                // 用户列表
                ListModel {
                    id: userListModel
                }

                ListView {
                    id: userListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: userListModel
                    clip: true
                    spacing: 8

                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: 60
                        text: model.name

                        background: Rectangle {
                            color: parent.pressed ? (theme ? Qt.lighter(theme.primaryColor, 1.8) : "#E3F2FD") :
                                   (parent.hovered ? (theme ? Qt.lighter(theme.primaryColor, 1.9) : "#EFF8FF") :
                                   (userListView.currentIndex === index ? (theme ? Qt.lighter(theme.primaryColor, 1.5) : "#BBDEFB") : 
                                   (theme ? theme.backgroundColor : "#FFFFFF")))
                            radius: 8
                            border.color: userListView.currentIndex === index ? (theme ? theme.primaryColor : "#2196F3") : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        contentItem: RowLayout {
                            spacing: 12

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: theme ? theme.primaryColor : "#2196F3"
                                opacity: 0.8

                                Text {
                                    anchors.centerIn: parent
                                    text: model.name.charAt(0).toUpperCase()
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "white"
                                }
                            }

                            Text {
                                text: model.name
                                font.pixelSize: 16
                                color: theme ? theme.textColor : "#333333"
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: {
                            userListView.currentIndex = index;
                        }

                        onDoubleClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                if (mainWindow) {
                                    mainWindow.selectUser(username);
                                }
                            }
                        }
                    }

                    ScrollIndicator.vertical: ScrollIndicator { }

                    // 空状态显示
                    footer: Item {
                        width: parent.width
                        height: userListModel.count === 0 ? 100 : 0
                        visible: userListModel.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                text: "🤔"
                                font.pixelSize: 32
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: qsTr("没有可用用户")
                                color: theme ? theme.textColor : "#333333"
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: qsTr("点击下方按钮创建新用户")
                                color: theme ? theme.textColor : "#666666"
                                font.pixelSize: 14
                                opacity: 0.7
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // 操作按钮
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true } // 弹簧

                    Button {
                        text: qsTr("刷新列表")
                        icon.name: "refresh"
                        onClicked: loadUserList()
                        
                        background: Rectangle {
                            color: parent.pressed ? (theme ? Qt.darker(theme.backgroundColor, 1.2) : "#E0E0E0") :
                                  (parent.hovered ? (theme ? Qt.lighter(theme.backgroundColor, 1.1) : "#F5F5F5") : 
                                  (theme ? theme.backgroundColor : "#FAFAFA"))
                            radius: 8
                            border.color: theme ? Qt.darker(theme.backgroundColor, 1.3) : "#E0E0E0"
                            border.width: 1
                            implicitHeight: 40
                            implicitWidth: 120
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: theme ? theme.textColor : "#424242"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: qsTr("创建新用户")
                        icon.name: "user-new"
                        
                        onClicked: {
                            newUsernameField.text = "";
                            newUserPopup.open();
                        }
                        
                        background: Rectangle {
                            color: parent.pressed ? (theme ? Qt.darker(theme.primaryColor, 1.2) : "#1976D2") :
                                  (parent.hovered ? (theme ? Qt.lighter(theme.primaryColor, 1.1) : "#42A5F5") : 
                                  (theme ? theme.primaryColor : "#2196F3"))
                            radius: 8
                            border.color: theme ? Qt.darker(theme.primaryColor, 1.1) : "#1E88E5"
                            border.width: 1
                            implicitHeight: 40
                            implicitWidth: 140
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: qsTr("选择用户")
                        highlighted: true
                        enabled: userListModel.count > 0 && userListView.currentIndex >= 0
                        
                        onClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                if (mainWindow) {
                                    mainWindow.selectUser(username);
                                }
                            } else if (errorDialog) {
                                errorDialog.showError(qsTr("请选择一个用户"));
                            }
                        }
                        
                        background: Rectangle {
                            color: parent.pressed ? (theme ? Qt.darker(theme.accentColor, 1.2) : "#00897B") :
                                  (parent.hovered ? (theme ? Qt.lighter(theme.accentColor, 1.1) : "#26A69A") : 
                                  (theme ? theme.accentColor : "#009688"))
                            radius: 8
                            border.color: theme ? Qt.darker(theme.accentColor, 1.1) : "#00796B"
                            border.width: 1
                            opacity: parent.enabled ? 1.0 : 0.5
                            implicitHeight: 40
                            implicitWidth: 140
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
        
        // 底部版权信息
        Text {
            text: qsTr("InvestLedger © 2023")
            font.pixelSize: 12
            color: theme ? Qt.darker(theme.textColor, 1.3) : "#757575"
            opacity: 0.7
            Layout.alignment: Qt.AlignRight
        }
    }
    
    // 创建新用户的弹出窗口
    Popup {
        id: newUserPopup
        width: 350
        height: 200
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            color: theme ? theme.cardColor : "white"
            radius: 8
            border.color: theme ? Qt.darker(theme.cardColor, 1.2) : "#E0E0E0"
            border.width: 1
            
            // 阴影效果
            DropShadow {
                anchors.fill: parent
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8
                color: "#40000000"
                source: parent
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: qsTr("创建新用户")
                font.pixelSize: 18
                font.bold: true
                color: theme ? theme.textColor : "#333333"
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: newUsernameField
                Layout.fillWidth: true
                placeholderText: qsTr("输入用户名")
                color: theme ? theme.textColor : "#333333"
                
                background: Rectangle {
                    color: theme ? theme.backgroundColor : "#F5F5F5"
                    border.color: theme ? Qt.darker(theme.backgroundColor, 1.3) : "#E0E0E0"
                    radius: 4
                }
                
                Keys.onReturnPressed: createUserButton.clicked() // 允许按Enter键创建
                Keys.onEnterPressed: createUserButton.clicked()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: qsTr("取消")
                    flat: true
                    onClicked: newUserPopup.close()
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: theme ? theme.textColor : "#666666"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: createUserButton
                    text: qsTr("创建")
                    highlighted: true
                    
                    onClicked: {
                        var username = newUsernameField.text.trim();
                        if (username) {
                            try {
                                if (backend.createUser(username)) {
                                    // 如果用户创建成功，选择该用户
                                    if (mainWindow) {
                                        mainWindow.selectUser(username);
                                    }
                                    newUserPopup.close();
                                } else if (errorDialog) {
                                    errorDialog.showError(qsTr("创建用户失败: 用户名可能已存在或无效。"));
                                }
                            } catch (e) {
                                console.error("Error creating user:", e);
                                if (errorDialog) {
                                    errorDialog.showError(qsTr("创建用户时发生错误: ") + e);
                                }
                            }
                        } else if (errorDialog) {
                            errorDialog.showError(qsTr("用户名不能为空。"));
                        }
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? (theme ? Qt.darker(theme.primaryColor, 1.2) : "#1976D2") :
                              (parent.hovered ? (theme ? Qt.lighter(theme.primaryColor, 1.1) : "#42A5F5") : 
                              (theme ? theme.primaryColor : "#2196F3"))
                        radius: 8
                        border.color: theme ? Qt.darker(theme.primaryColor, 1.1) : "#1E88E5"
                        border.width: 1
                        opacity: parent.enabled ? 1.0 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    
    // 关闭事件处理
    onClosing: {
        // 如果没有选择用户，则关闭整个应用
        if (!mainWindow || !mainWindow.userSelected) {
            Qt.quit();
        }
    }
} 