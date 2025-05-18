import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
// 使用条件导入QtCharts
import QtCharts 2.3 as Charts // 有QtCharts就导入，没有就忽略错误
// 导入自定义组件
import "components"
// 导入对话框
import "." as UI

ApplicationWindow {
    id: mainWindow
    visible: false // 初始不可见, 等待用户选择
    width: 1280
    height: 800
    title: qsTr("InvestLedger - 轻量个人投资记账程序") + " - v" + appVersion
    
    // 预算告警信息
    property var budgetAlerts: []
    // 是否显示预算告警
    property bool showBudgetAlert: budgetAlerts.length > 0
    
    // 工具栏组件
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: 10
            
            // 撤销按钮
            Button {
                id: undoButton
                text: qsTr("撤销")
                icon.name: "edit-undo"
                enabled: backend.canUndo
                onClicked: {
                    if (backend.undo()) {
                        // 刷新当前视图
                        backend.refreshCurrentView()
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("撤销上一步操作")
            }
            
            // 重做按钮
            Button {
                id: redoButton
                text: qsTr("重做")
                icon.name: "edit-redo"
                enabled: backend.canRedo
                onClicked: {
                    if (backend.redo()) {
                        // 刷新当前视图
                        backend.refreshCurrentView()
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("重做上一步操作")
            }
            
            // 分隔符
            Rectangle {
                width: 1
                height: parent.height * 0.7
                color: "#cccccc"
            }
            
            // 预算告警区域
            Rectangle {
                id: alertArea
                visible: showBudgetAlert
                color: "#fff8e1"  // 淡黄色背景
                border.color: "#ffca28"
                border.width: 1
                radius: 4
                Layout.fillWidth: true
                height: alertText.height + 16
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    // 警告图标
                    Text {
                        text: "⚠️"
                        font.pixelSize: 18
                    }
                    
                    // 警告文本
                    Text {
                        id: alertText
                        text: budgetAlerts.length > 0 ? budgetAlerts[0].message : ""
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    // 关闭按钮
                    Button {
                        text: "×"
                        flat: true
                        onClicked: {
                            // 移除当前显示的告警
                            if (budgetAlerts.length > 0) {
                                budgetAlerts.shift()
                                budgetAlerts = budgetAlerts  // 触发属性更新
                            }
                        }
                    }
                }
            }
            
            // 填充空间
            Item {
                Layout.fillWidth: true
                visible: !showBudgetAlert
            }
        }
    }
    
    // 对话框组件加载器
    QtObject {
        id: dialogLoader
        
        // 加载导入对话框
        function loadImportDialog() {
            var component = Qt.createComponent("dialogs.qml");
            if (component.status === Component.Ready) {
                var dialogObj = component.createObject(mainWindow);
                if (dialogObj && dialogObj.importDialog) {
                    return dialogObj.importDialog.createObject(mainWindow);
                } else {
                    console.error("加载导入对话框失败: 对话框对象无效");
                    return null;
                }
            } else {
                console.error("加载对话框组件失败:", component.errorString());
                return null;
            }
        }
        
        // 加载导出对话框
        function loadExportDialog() {
            var component = Qt.createComponent("dialogs.qml");
            if (component.status === Component.Ready) {
                var dialogObj = component.createObject(mainWindow);
                if (dialogObj && dialogObj.exportDialog) {
                    return dialogObj.exportDialog.createObject(mainWindow);
                } else {
                    console.error("加载导出对话框失败: 对话框对象无效");
                    return null;
                }
            } else {
                console.error("加载对话框组件失败:", component.errorString());
                return null;
            }
        }
        
        // 加载设置对话框
        function loadSettingsDialog() {
            var component = Qt.createComponent("dialogs.qml");
            if (component.status === Component.Ready) {
                var dialogObj = component.createObject(mainWindow);
                if (dialogObj && dialogObj.settingsDialog) {
                    return dialogObj.settingsDialog.createObject(mainWindow);
                } else {
                    console.error("加载设置对话框失败: 对话框对象无效");
                    return null;
                }
            } else {
                console.error("加载对话框组件失败:", component.errorString());
                return null;
            }
        }
        
        // 加载帮助对话框
        function loadHelpDialog() {
            var component = Qt.createComponent("dialogs.qml");
            if (component.status === Component.Ready) {
                var dialogObj = component.createObject(mainWindow);
                if (dialogObj && dialogObj.helpDialog) {
                    return dialogObj.helpDialog.createObject(mainWindow);
                } else {
                    console.error("加载帮助对话框失败: 对话框对象无效");
                    return null;
                }
            } else {
                console.error("加载对话框组件失败:", component.errorString());
                return null;
            }
        }
    }
    
    // 主题管理器
    property ThemeManager theme: ThemeManager {}
    
    // 主题色定义 - 由主题管理器控制
    property color primaryColor: theme.primaryColor
    property color accentColor: theme.accentColor
    property color textColor: theme.textColor
    property color bgColor: theme.backgroundColor
    property color cardColor: theme.cardColor
    property color profitColor: theme.profitColor
    property color lossColor: theme.lossColor
    
    // 当前状态
    property bool userSelected: false
    property string currentUser: ""
    property int currentPage: 0  // 0: 仪表盘, 1: 交易列表, 2: 图表统计, 3: 导入导出
    
    // 图表功能可用性
    property bool chartsAvailable: typeof hasCharts !== 'undefined' && hasCharts
    
    Component.onCompleted: {
        // 默认显示用户选择对话框
        // 确保在 mainWindow.visible = false 的情况下，对话框仍能正确显示和操作
        if (!userSelected) { // 仅当没有用户被选择时显示
            userSelectDialog.showDialog();
        } else {
            // 如果已有用户（例如通过某种方式自动登录），则直接显示主窗口
            mainWindow.visible = true;
        }
    }
    
    function initializeApp() {
        // 如果只有一个用户且不是首次启动，自动选择该用户
        var users = backend.getUsers();
        showUserSelectDialog();
    }
    
    function selectUser(username) {
        if (backend.selectUser(username)) {
            userSelected = true;
            currentUser = username;
            // 加载用户主题设置
            theme.loadTheme();
            loadDashboard();
        }
    }
    
    function loadDashboard() {
        // 加载仪表盘数据
        currentPage = 0;
    }
    
    // 当用户选择完成后显示主窗口
    Connections {
        target: userSelectDialog
        function onUserSelectedSuccessfully() { // 自定义信号，在selectUser成功后发出
            mainWindow.visible = true;
        }
        function onDialogClosedWithoutSelection() { // 如果对话框关闭但未选择用户
            // Qt.quit(); // 例如，如果未选择用户则退出应用
            // 或者保持主窗口不可见，等待用户通过其他方式触发选择 (例如 "切换用户" 按钮)
        }
    }

    // 用户选择对话框
    Dialog {
        id: userSelectDialog
        title: qsTr("选择或创建用户")
        width: Math.min(mainWindow.width * 0.8, 450) // 响应式宽度
        height: Math.min(mainWindow.height * 0.7, 350) // 响应式高度
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.NoButton // 移除标准按钮，使用自定义按钮
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent // 允许点击外部关闭

        // 信号
        signal userSelectedSuccessfully()
        signal dialogClosedWithoutSelection()

        // 背景和边框美化
        background: Rectangle {
            color: theme.cardColor // 使用主题颜色
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
        }

        // 动画效果
        opacity: 0
        transform: Scale { xScale: 0.9; yScale: 0.9; origin.x: userSelectDialog.width / 2; origin.y: userSelectDialog.height / 2 }
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on transform { ScaleAnimator { duration: 250; easing.type: Easing.OutCubic } }

        onOpened: {
            opacity = 1;
            transform.xScale = 1.0;
            transform.yScale = 1.0;
        }

        onClosed: {
            opacity = 0;
            transform.xScale = 0.9;
            transform.yScale = 0.9;
            if (!userSelected) { // 如果关闭时没有选择用户
                dialogClosedWithoutSelection();
            }
        }
        header: Label { // 使用Label作为标题栏，更灵活
            text: qsTr("选择用户")
            font.pixelSize: 18
            font.bold: true
            color: theme.textColor
            padding: 12
            background: Rectangle {
                color: Qt.lighter(theme.primaryColor, 1.1)
                radius: 8
                anchors.topFill: parent
                height: parent.height
                // 只圆角化顶部
                border.color: theme.primaryColor
                Rectangle { // 底部边框线
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.darker(theme.primaryColor, 1.2)
                }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: userSelectDialog.header ? userSelectDialog.header.height : 0 // 确保内容在header下方
            spacing: 15
            padding: 15

            Label {
                text: qsTr("请选择一个用户配置文件，或创建一个新用户。")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: theme.textColor
                font.pixelSize: 13
            }

            ListView {
                id: userListView
                Layout.fillWidth: true
                Layout.preferredHeight: 150 // 设定一个合适的高度
                Layout.minimumHeight: 100
                clip: true // 裁剪内容
                model: ListModel { id: userListModel }
                ScrollBar.vertical: ScrollBar {}
                delegate: ItemDelegate {
                    width: parent.width
                    height: 45
                    padding: 8

                    background: Rectangle {
                        color: ListView.isCurrentItem ? Qt.tint(theme.primaryColor, Qt.rgba(1,1,1,0.2)) : (hovered ? Qt.tint(theme.cardColor, Qt.rgba(1,1,1,0.1)) : "transparent")
                        radius: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    contentItem: Text {
                        text: name
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 15
                        color: ListView.isCurrentItem ? theme.textColor : theme.textColor // 保持文本颜色一致或根据主题调整
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        selectUser(name);
                        userSelectDialog.userSelectedSuccessfully() // 发出成功信号
                        userSelectDialog.close();
                    }
                }
            }

            Button {
                text: qsTr("创建新用户")
                Layout.fillWidth: true
                highlighted: true // 突出显示
                icon.name: "user-new" // 添加图标
                onClicked: newUserDialog.open()
                palette.buttonText: theme.textColor // 确保按钮文本颜色与主题一致
            }
        }
        function showDialog() {
            var users = backend.getUsers();
            userListModel.clear();
            if (users.length === 0) {
                // 如果没有用户，可以提示创建用户，或者直接打开新建用户对话框
                // userListModel.append({name: "没有可用的用户", isPlaceholder: true});
            } else {
                for (var i = 0; i < users.length; i++) {
                    userListModel.append(users[i]);
                }
            }
            open();
        }
    }
    
    // 新建用户对话框
    Dialog {
        id: newUserDialog
        title: "新建用户"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        contentItem: ColumnLayout {
            spacing: 10
            
            Text {
                text: "输入用户名："
                font.pixelSize: 14
            }
            
            TextField {
                id: newUsernameField
                Layout.fillWidth: true
                placeholderText: "用户名"
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "取消"
                    onClicked: newUserDialog.close()
                }
                
                Button {
                    text: "创建"
                    highlighted: true
                    onClicked: {
                        var username = newUsernameField.text.trim();
                        if (username) {
                            if (backend.createUser(username)) {
                                selectUser(username);
                                newUserDialog.close();
                                userSelectDialog.userSelectedSuccessfully(); // 发出成功信号
                                userSelectDialog.close();
                            } else {
                                errorDialog.showError("创建用户失败");
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 错误对话框
    Dialog {
        id: errorDialog
        title: "错误"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        contentItem: ColumnLayout {
            Text {
                id: errorText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: errorDialog.close()
            }
        }
        
        function showError(message) {
            errorText.text = message;
            open();
        }
    }
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // 顶部工具栏
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: primaryColor
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10
                
                Text {
                    text: "InvestLedger"
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: userSelected ? "当前用户: " + currentUser : "未选择用户"
                    color: "white"
                    font.pixelSize: 14
                }
                
                Button {
                    text: "切换用户"
                    visible: userSelected
                    onClicked: showUserSelectDialog()
                }
                
                Button {
                    text: "检查更新"
                    onClicked: {
                        if (backend.checkForUpdates()) {
                            updateDialog.open();
                        } else {
                            errorDialog.showError("已是最新版本");
                        }
                    }
                }
                
                Button {
                    text: "设置"
                    onClicked: {
                        var dialog = dialogLoader.loadSettingsDialog();
                        dialog.open();
                    }
                }
                
                // 主题切换按钮
                Button {
                    text: theme.isDarkTheme ? "切换到亮色" : "切换到暗色"
                    onClicked: {
                        theme.saveTheme(theme.isDarkTheme ? "light" : "dark");
                    }
                }
                
                Button {
                    text: "帮助"
                    onClicked: {
                        var dialog = dialogLoader.loadHelpDialog();
                        dialog.open();
                    }
                }
            }
        }
        
        // 内容区域
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // 左侧导航栏
            Rectangle {
                implicitWidth: 200
                SplitView.minimumWidth: 150
                SplitView.maximumWidth: 300
                color: Qt.lighter(primaryColor, 1.5)
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    NavButton {
                        text: "仪表盘"
                        iconName: "dashboard"
                        selected: currentPage === 0
                        onClicked: currentPage = 0
                    }
                    
                    NavButton {
                        text: "交易列表"
                        iconName: "list"
                        selected: currentPage === 1
                        onClicked: currentPage = 1
                    }
                    
                    NavButton {
                        text: "统计图表"
                        iconName: "chart"
                        selected: currentPage === 2
                        onClicked: currentPage = 2
                    }
                    
                    NavButton {
                        text: "导入导出"
                        iconName: "import"
                        selected: currentPage === 3
                        onClicked: currentPage = 3
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    NavButton {
                        text: "设置"
                        iconName: "settings"
                        selected: currentPage === 4
                        onClicked: currentPage = 4
                    }
                }
            }
            
            // 主内容区
            Rectangle {
                SplitView.fillWidth: true
                color: bgColor
                
                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    currentIndex: currentPage
                    
                    // 仪表盘页面
                    Item {
                        DashboardView {}
                    }
                    
                    // 交易列表页面
                    Item {
                        TransactionListView {}
                    }
                    
                    // 统计图表页面
                    Item {
                        Loader {
                            anchors.fill: parent
                            source: chartsAvailable ? "components/ChartView.qml" : ""
                            
                            Text {
                                anchors.centerIn: parent
                                text: chartsAvailable ? "" : "图表功能需要Qt Charts模块支持"
                                font.pixelSize: 18
                                color: "gray"
                                visible: !chartsAvailable
                            }
                        }
                    }
                    
                    // 导入导出页面
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 20
                            
                            Text {
                                text: "数据导入导出"
                                font.pixelSize: 24
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 120
                                color: cardColor
                                radius: 5
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 40
                                    
                                    Button {
                                        text: "导入数据"
                                        icon.name: "import"
                                        onClicked: {
                                            var dialog = dialogLoader.loadImportDialog();
                                            dialog.open();
                                        }
                                    }
                                    
                                    Button {
                                        text: "导出数据"
                                        icon.name: "export"
                                        onClicked: {
                                            var dialog = dialogLoader.loadExportDialog();
                                            dialog.open();
                                        }
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                    
                    // 设置页面
                    Item {
                        SettingsView {}
                    }
                }
            }
        }
        
        // 底部状态栏
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: Qt.darker(primaryColor, 1.2)
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                
                Text {
                    text: "InvestLedger v" + appVersion
                    color: "white"
                    font.pixelSize: 12
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: "©2023"
                    color: "white"
                    font.pixelSize: 12
                }
            }
        }
    }
    
    // 更新对话框
    Dialog {
        id: updateDialog
        title: "发现新版本"
        width: 400
        height: 200
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        contentItem: ColumnLayout {
            spacing: 10
            
            Text {
                text: "发现新版本，是否立即更新？"
                font.pixelSize: 16
                Layout.fillWidth: true
            }
            
            CheckBox {
                id: autoRestartCheckbox
                text: "更新后自动重启"
                checked: true
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "稍后"
                    onClicked: updateDialog.close()
                }
                
                Button {
                    text: "立即更新"
                    highlighted: true
                    onClicked: {
                        backend.downloadUpdate(autoRestartCheckbox.checked);
                        updateDialog.close();
                    }
                }
            }
        }
    }
    
    // 全局信号处理
    Connections {
        target: backend
        
        function onErrorOccurred(message) {
            errorDialog.showError(message);
        }
        
        function onUpdateAvailable(version, notes) {
            updateDialog.open();
        }
    }
    
    // 显示用户选择对话框
    function showUserSelectDialog() {
        userSelectDialog.showDialog();
    }
}