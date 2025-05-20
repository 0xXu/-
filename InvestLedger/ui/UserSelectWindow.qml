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
    
    // 主题颜色属性
    property color lossColor: theme ? theme.lossColor : "#f44336" // 使用默认红色作为删除按钮颜色
    
    // 定义信号
    signal userSelected(string username)
    
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
                                color: theme.primaryColor
                                opacity: 0.8

                                Label {
                                    anchors.centerIn: parent
                                    text: model.name.charAt(0).toUpperCase()
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "white"
                                }
                            }

                            Label {
                                text: model.name
                                font.pixelSize: 16
                                color: theme.textColor
                                Layout.fillWidth: true
                            }
                            
                            // 删除用户按钮
                            Button {
                                id: deleteUserButton
                                icon.name: "delete"
                                implicitWidth: 30
                                implicitHeight: 30
                                visible: !model.name.startsWith("demo") // 示例用户不能删除
                                
                                background: Rectangle {
                                    color: deleteUserButton.pressed ? Qt.darker(lossColor, 1.2) :
                                           (deleteUserButton.hovered ? Qt.lighter(lossColor, 1.1) : "transparent")
                                    radius: 4
                                }
                                
                                contentItem: Text {
                                    text: "🗑️"
                                    font.pixelSize: 14
                                    color: deleteUserButton.hovered ? "white" : "#ff5252"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: function(mouse) {
                                    // 防止冒泡触发父项的点击事件
                                    mouse.accepted = true;
                                    // 显示确认对话框
                                    deleteConfirmDialog.userName = model.name;
                                    deleteConfirmDialog.open();
                                }
                                
                                // 提示文本
                                ToolTip.visible: hovered
                                ToolTip.text: qsTr("删除此用户")
                            }
                        }

                        onClicked: {
                            userListView.currentIndex = index;
                        }

                        onDoubleClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                // 发出用户选择信号
                                userSelected(username);
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
                        implicitHeight: 40
                        implicitWidth: 120
                        onClicked: loadUserList()
                        
                        background: Rectangle {
                            color: parent.pressed ? Qt.darker(theme.backgroundColor, 1.2) :
                                  (parent.hovered ? Qt.lighter(theme.backgroundColor, 1.1) : 
                                  theme.backgroundColor)
                            radius: 8
                            border.color: Qt.darker(theme.backgroundColor, 1.3)
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: theme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: qsTr("创建新用户")
                        icon.name: "user-new"
                        implicitHeight: 40
                        implicitWidth: 140
                        
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
                            opacity: parent.enabled ? 1.0 : 0.5
                            Behavior on color { ColorAnimation { duration: 150 } }
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
                        implicitHeight: 40
                        implicitWidth: 140
                        
                        background: Rectangle {
                            color: parent.pressed ? Qt.darker(theme.accentColor, 1.2) :
                                  (parent.hovered ? Qt.lighter(theme.accentColor, 1.1) : 
                                  theme.accentColor)
                            radius: 8
                            border.color: Qt.darker(theme.accentColor, 1.1)
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                // 发出用户选择信号
                                userSelected(username);
                            } else {
                                errorDialog.showError(qsTr("请选择一个用户"));
                            }
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
                                    // 创建成功后选择新用户
                                    userSelected(username);
                                    newUserPopup.close();
                                } else {
                                    errorDialog.showError(qsTr("创建用户失败: 用户名可能已存在或无效。"));
                                }
                            } catch (e) {
                                console.error("Error creating user:", e);
                                errorDialog.showError(qsTr("创建用户时发生错误: ") + e);
                            }
                        } else {
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
    
    // 错误对话框
    Dialog {
        id: errorDialog
        title: qsTr("错误")
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        // 样式美化
        background: Rectangle {
            color: theme.cardColor
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 10
            
            Text {
                id: errorText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: theme.textColor
            }
            
            Button {
                text: qsTr("确定")
                Layout.alignment: Qt.AlignRight
                onClicked: errorDialog.close()
                
                background: Rectangle {
                    color: theme.accentColor
                    radius: 8
                    border.color: Qt.darker(theme.accentColor, 1.1)
                    border.width: 1
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        
        function showError(message) {
            errorText.text = message;
            open();
        }
    }
    
    // 删除用户确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: qsTr("确认删除")
        width: 350
        height: 180
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property string userName: ""
        
        // 样式美化
        background: Rectangle {
            color: theme.cardColor
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            spacing: 20
            
            Text {
                text: qsTr("确定要删除用户 '%1' 吗？").arg(deleteConfirmDialog.userName)
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: theme.textColor
            }
            
            Text {
                text: qsTr("此操作将永久删除该用户的所有数据，且不可恢复！")
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#E53935"  // 警告色
                font.bold: true
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: qsTr("取消")
                    onClicked: deleteConfirmDialog.close()
                    
                    background: Rectangle {
                        color: theme.backgroundColor
                        radius: 8
                        border.color: Qt.darker(theme.backgroundColor, 1.3)
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Button {
                    text: qsTr("删除")
                    
                    background: Rectangle {
                        color: "#E53935"  // 删除按钮用红色
                        radius: 8
                        border.color: Qt.darker("#E53935", 1.1)
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        try {
                            if (backend.deleteUser(deleteConfirmDialog.userName)) {
                                // 删除成功后重新加载用户列表
                                loadUserList();
                                deleteConfirmDialog.close();
                            } else {
                                errorDialog.showError(qsTr("删除用户失败: 无法删除用户 '%1'").arg(deleteConfirmDialog.userName));
                            }
                        } catch (e) {
                            console.error("Error deleting user:", e);
                            errorDialog.showError(qsTr("删除用户时发生错误: ") + e);
                        }
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