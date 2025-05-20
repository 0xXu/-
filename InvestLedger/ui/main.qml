import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtCharts
import Qt5Compat.GraphicalEffects
// Import custom components from the "components" directory
import "components"
// Import dialogs from the current directory, though we're defining them here directly for clarity
// import "." as UI // Not strictly needed as dialogs are defined in this file


ApplicationWindow {
    id: mainWindow
    visible: false // 初始设置为false，用户选择后再显示
    width: 1280
    height: 800
    title: qsTr("InvestLedger - 轻量个人投资记账程序") + " - v" + appVersion

    // Application-wide properties
    property var budgetAlerts: []
    property bool showBudgetAlert: budgetAlerts.length > 0
    property bool userSelected: false // True after a user is successfully selected
    property string currentUser: ""
    property int currentPage: 0  // 0: Dashboard, 1: Transactions, 2: Charts, 3: Import/Export, 4: Settings
    property bool isLoading: false // 控制加载动画显示

    // Check if QtCharts module was successfully imported
    property bool chartsAvailable: typeof Charts !== 'undefined'

    // Theme manager instance
    ThemeManager {
        id: themeManagerInstance
    }
    property var theme: themeManagerInstance

    // Theme color definitions, controlled by ThemeManager
    // These will be updated once themeManagerInstance.loadTheme() is called
    property color primaryColor: themeManagerInstance.primaryColor
    property color accentColor: themeManagerInstance.accentColor
    property color textColor: themeManagerInstance.textColor
    property color bgColor: themeManagerInstance.backgroundColor
    property color cardColor: themeManagerInstance.cardColor
    property color profitColor: themeManagerInstance.profitColor
    property color lossColor: themeManagerInstance.lossColor

    // Dialog loader helper object
    QtObject {
        id: dialogLoader

        // Functions to create and return dialog instances from dialogs.qml
        // These assume dialogs.qml defines components like 'ImportDialog', 'ExportDialog', etc.
        function loadDialog(dialogName) {
            var component = Qt.createComponent("dialogs.qml");
            if (component.status === Component.Ready) {
                var dialogObj = component.createObject(mainWindow);
                if (dialogObj && dialogObj[dialogName]) {
                    return dialogObj[dialogName].createObject(mainWindow);
                } else {
                    console.error("Failed to load dialog '%1': Dialog object invalid.".arg(dialogName));
                    return null;
                }
            } else {
                console.error("Failed to load dialogs.qml component:", component.errorString());
                return null;
            }
        }

        function loadImportDialog() { return loadDialog("importDialog"); }
        function loadExportDialog() { return loadDialog("exportDialog"); }
        function loadSettingsDialog() { return loadDialog("settingsDialog"); }
        function loadHelpDialog() { return loadDialog("helpDialog"); }
    }

    // Function to select a user and initialize the main application UI
    function selectUser(username) {
        try {
            // 显示加载动画
            isLoading = true;
            
            // 使用Timer确保UI更新并显示加载动画
            loadingTimer.username = username;
            loadingTimer.start();
        } catch (e) {
            console.error("Error selecting user:", e);
            errorDialog.showError(qsTr("选择用户时发生错误: ") + e);
            isLoading = false;
        }
    }
    
    // 加载用户数据的Timer
    Timer {
        id: loadingTimer
        interval: 100 // 给UI一点时间显示加载动画
        property string username: ""
        
        onTriggered: {
            try {
                if (backend.selectUser(username)) {
                    userSelected = true;
                    currentUser = username;
                    theme.loadTheme(); // Load theme settings for the selected user
                    loadDashboard(); // Load the dashboard content
                    
                    // 选择用户后检查更新
                    backend.checkForUpdates();
                    
                    // 完成加载后显示主窗口
                    mainWindow.visible = true;
                } else {
                    errorDialog.showError(qsTr("选择用户失败: 用户 '%1' 不存在或无法加载。").arg(username));
                }
                // 无论成功与否，都隐藏加载动画
                isLoading = false;
            } catch (e) {
                console.error("Error in loadingTimer:", e);
                errorDialog.showError(qsTr("加载用户数据时发生错误: ") + e);
                isLoading = false;
            }
        }
    }

    // Function to navigate to the dashboard page
    function loadDashboard() {
        currentPage = 0;
        // Additional dashboard specific loading logic can go here
    }

    // Lifecycle hook: executed after component creation
    Component.onCompleted: {
        // Load theme settings before showing any UI that depends on it
        themeManagerInstance.loadTheme();
        // 不要在这里设置mainWindow.visible为true，让用户选择界面先显示
        // 用户选择后，selectUser函数会设置mainWindow.visible为true
    }

    // --- User Selection View ---
    // This is the full-screen user selection view that appears at startup
    Item {
        id: userSelectView
        anchors.fill: parent
        visible: !userSelected // Only show when no user is selected

        // Background with theme color
        Rectangle {
            anchors.fill: parent
            color: theme.backgroundColor
        }

        // Main content container
        Rectangle {
            width: Math.min(parent.width * 0.8, 600)
            height: Math.min(parent.height * 0.8, 600)
            anchors.centerIn: parent
            color: theme.cardColor
            radius: 12
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1

            // Shadow effect
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8.0
                color: "#40000000"
            }

            // Content layout
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: Qt.lighter(theme.primaryColor, 1.1)
                    radius: 8

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        Label {
                            text: qsTr("选择用户")
                            font.pixelSize: 24
                            font.bold: true
                            color: "white"
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("请选择一个用户配置文件，或创建一个新用户")
                            font.pixelSize: 14
                            color: "white"
                            opacity: 0.8
                            Layout.fillWidth: true
                        }
                    }
                }

                // User list
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
                            color: parent.pressed ? Qt.lighter(theme.primaryColor, 1.8) :
                                   (parent.hovered ? Qt.lighter(theme.primaryColor, 1.9) :
                                   (userListView.currentIndex === index ? Qt.lighter(theme.primaryColor, 1.5) : theme.backgroundColor))
                            radius: 8
                            border.color: userListView.currentIndex === index ? theme.primaryColor : "transparent"
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
                        }

                        onClicked: {
                            userListView.currentIndex = index;
                        }

                        onDoubleClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                selectUser(username);
                            }
                        }
                    }

                    ScrollIndicator.vertical: ScrollIndicator { }

                    // Empty state
                    footer: Item {
                        width: parent.width
                        height: userListModel.count === 0 ? 100 : 0
                        visible: userListModel.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            Label {
                                text: "🤔"
                                font.pixelSize: 32
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Label {
                                text: qsTr("没有可用用户")
                                color: theme.textColor
                                font.pixelSize: 16
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Label {
                                text: qsTr("点击下方按钮创建新用户")
                                color: theme.textColor
                                font.pixelSize: 14
                                opacity: 0.7
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    spacing: 10

                    Item { Layout.fillWidth: true } // Spacer

                    Button {
                        text: qsTr("创建新用户")
                        icon.name: "user-new"
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40

                        onClicked: {
                            newUsernameField.text = "";
                            newUserPopup.open();
                        }

                        background: Rectangle {
                            color: theme.primaryColor
                            radius: 8
                            border.color: Qt.darker(theme.primaryColor, 1.1)
                            border.width: 1
                            opacity: parent.enabled ? 1.0 : 0.5
                        }

                        contentItem: Label {
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
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40

                        onClicked: {
                            if (userListView.currentIndex >= 0) {
                                var username = userListModel.get(userListView.currentIndex).name;
                                selectUser(username);
                            } else {
                                errorDialog.showError(qsTr("请选择一个用户"));
                            }
                        }

                        background: Rectangle {
                            color: theme.accentColor
                            radius: 8
                            border.color: Qt.darker(theme.accentColor, 1.1)
                            border.width: 1
                            opacity: parent.enabled ? 1.0 : 0.5
                        }

                        contentItem: Label {
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

        // 用户选择视图已在主窗口的Component.onCompleted中初始化
    } // End of userSelectView

    // --- New User Creation Popup ---
    Popup {
        id: newUserPopup
        width: 350
        height: 200
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            color: theme.cardColor
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
            DropShadow { // Visual depth
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

            Label {
                text: qsTr("创建新用户")
                font.pixelSize: 18
                font.bold: true
                color: theme.textColor
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: newUsernameField
                Layout.fillWidth: true
                placeholderText: qsTr("输入用户名")
                color: theme.textColor
                background: Rectangle {
                    color: theme.backgroundColor
                    border.color: Qt.darker(theme.backgroundColor, 1.3)
                    radius: 4
                }
                Keys.onReturnPressed: createUserButton.clicked() // Allow Enter to create
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
                    palette.buttonText: theme.textColor // Use theme color for flat button text
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
                                    // If user created successfully, select them
                                    selectUser(username); // This will handle showing mainWindow and closing userSelectDialog
                                    newUserPopup.close(); // Close this new user popup
                                    // userSelectDialog.showDialog(); // No need to explicitly re-populate if selectUser closes it
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
                        color: theme.primaryColor
                        radius: 8
                        border.color: Qt.darker(theme.primaryColor, 1.1)
                        border.width: 1
                        opacity: parent.enabled ? 1.0 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Label { // Custom content item for thematic text color
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.margins: 6
                    }
                }
            }
        }
    } // End of newUserPopup

    // --- Global Error Dialog ---
    Dialog {
        id: errorDialog
        title: qsTr("错误")
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle { // Styling for error dialog
            color: theme.cardColor
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
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
            spacing: 10
            anchors.margins: 15 // Add anchors.margins

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
                    opacity: parent.enabled ? 1.0 : 0.5
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                contentItem: Label {
                    text: parent.text
                    font: parent.font
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

    // --- Application Window Header (ToolBar) ---
    // This is the single, unified top bar for the application.
    header: ToolBar {
        height: 60 // Fixed height for the toolbar
        background: Rectangle {
            color: primaryColor
            implicitWidth: parent.width
            implicitHeight: parent.height
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Application Title
            Text {
                text: "InvestLedger"
                color: "white"
                font.pixelSize: 20
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            // Undo button
            Button {
                id: undoButton
                text: qsTr("撤销")
                icon.name: "edit-undo"
                enabled: backend.canUndo
                onClicked: {
                    if (backend.undo()) {
                        backend.refreshCurrentView()
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("撤销上一步操作")
                
                // 美化按钮样式
                background: Rectangle {
                    color: undoButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (undoButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 4
                    border.color: undoButton.enabled ? theme.accentColor : "#cccccc"
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 80
                }
                
                contentItem: Item {
                    implicitWidth: undoRow.implicitWidth
                    implicitHeight: undoRow.implicitHeight
                    
                    Row {
                        id: undoRow
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "↩"
                            font.pixelSize: 16
                            color: undoButton.enabled ? "white" : "#cccccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: undoButton.text
                            font.pixelSize: 14
                            color: undoButton.enabled ? "white" : "#cccccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Redo button
            Button {
                id: redoButton
                text: qsTr("重做")
                icon.name: "edit-redo"
                enabled: backend.canRedo
                onClicked: {
                    if (backend.redo()) {
                        backend.refreshCurrentView()
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("重做上一步操作")
                
                // 美化按钮样式
                background: Rectangle {
                    color: redoButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (redoButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 4
                    border.color: redoButton.enabled ? theme.accentColor : "#cccccc"
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 80
                }
                
                contentItem: Item {
                    implicitWidth: redoRow.implicitWidth
                    implicitHeight: redoRow.implicitHeight
                    
                    Row {
                        id: redoRow
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "↪"
                            font.pixelSize: 16
                            color: redoButton.enabled ? "white" : "#cccccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: redoButton.text
                            font.pixelSize: 14
                            color: redoButton.enabled ? "white" : "#cccccc"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Separator line
            Rectangle {
                width: 1
                height: parent.height * 0.7
                color: "#cccccc"
                Layout.alignment: Qt.AlignVCenter
            }

            // Budget Alert Area (fills remaining space if no other items stretch)
            Rectangle {
                id: alertArea
                visible: showBudgetAlert
                color: "#fff8e1"  // Light yellow background
                border.color: "#ffca28"
                border.width: 1
                radius: 4
                Layout.fillWidth: true // Allows it to expand
                Layout.minimumWidth: 150 // Minimum width for the alert area
                Layout.maximumWidth: 400 // Max width
                height: alertText.implicitHeight + 16 // Dynamic height based on text content

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Warning icon
                    Text {
                        text: "⚠️"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Warning text
                    Text {
                        id: alertText
                        text: budgetAlerts.length > 0 ? budgetAlerts[0].message : ""
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#c07e00" // Darker text for alert
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Close button for alert
                    Button {
                        text: "×"
                        flat: true
                        font.bold: true
                        font.pixelSize: 16
                        onClicked: {
                            if (budgetAlerts.length > 0) {
                                budgetAlerts.shift() // Remove the first alert
                                budgetAlerts = budgetAlerts // Trigger property update
                            }
                        }
                    }
                }
            }

            // Filler item to push subsequent buttons to the right if alertArea isn't visible
            Item {
                Layout.fillWidth: true
                visible: !showBudgetAlert // Only active if alert is not shown
            }

            // Current User Display
            Text {
                text: userSelected ? qsTr("当前用户: ") + currentUser : qsTr("未选择用户")
                color: "white"
                font.pixelSize: 14
                Layout.rightMargin: 10
                verticalAlignment: Text.AlignVCenter
            }

            // Switch User Button
            Button {
                id: switchUserButton
                text: qsTr("切换用户")
                visible: userSelected // Only visible if a user is currently selected
                onClicked: {
                    userSelected = false; // 重置用户选择状态
                    currentUser = "";
                    mainWindow.visible = false;
                    Qt.quit(); // 退出应用并重新启动
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("切换当前活跃的用户")
                
                // 美化按钮样式
                background: Rectangle {
                    color: switchUserButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (switchUserButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 100
                }
                
                contentItem: Item {
                    implicitWidth: switchUserText.implicitWidth
                    implicitHeight: switchUserText.implicitHeight
                    
                    Text {
                        id: switchUserText
                        text: switchUserButton.text
                        font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }

            // Check for Updates Button
            Button {
                id: checkUpdateButton
                text: qsTr("检查更新")
                onClicked: {
                    if (backend.checkForUpdates()) { // Assuming backend provides this functionality
                        updateDialog.open();
                    } else {
                        errorDialog.showError(qsTr("已是最新版本"));
                    }
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("检查应用程序是否有新版本可用")
                
                // 美化按钮样式
                background: Rectangle {
                    color: checkUpdateButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (checkUpdateButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 100
                }
                
                contentItem: Item {
                    implicitWidth: checkUpdateText.implicitWidth
                    implicitHeight: checkUpdateText.implicitHeight
                    
                    Text {
                        id: checkUpdateText
                        text: checkUpdateButton.text
                        font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }

            // Settings Button
            Button {
                id: settingsButton
                text: qsTr("设置")
                onClicked: {
                    var dialog = dialogLoader.loadSettingsDialog();
                    if (dialog) dialog.open();
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("打开应用程序设置")
                
                // 美化按钮样式
                background: Rectangle {
                    color: settingsButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (settingsButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 80
                }
                
                contentItem: Item {
                    implicitWidth: settingsText.implicitWidth
                    implicitHeight: settingsText.implicitHeight
                    
                    Text {
                        id: settingsText
                        text: settingsButton.text
                        font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }

            // Theme Toggle Button
            Button {
                id: themeToggleButton
                text: theme.isDarkTheme ? qsTr("切换到亮色") : qsTr("切换到暗色")
                onClicked: {
                    theme.saveTheme(theme.isDarkTheme ? "light" : "dark"); // Save the new theme preference
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("切换应用程序的亮/暗主题")
                
                // 美化按钮样式
                background: Rectangle {
                    color: themeToggleButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (themeToggleButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 140 
                }
                
                contentItem: Item {
                    implicitWidth: themeToggleText.implicitWidth
                    implicitHeight: themeToggleText.implicitHeight
                    
                    Text {
                        id: themeToggleText
                        text: themeToggleButton.text
                        font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }

            // Help Button
            Button {
                id: helpButton
                text: qsTr("帮助")
                onClicked: {
                    var dialog = dialogLoader.loadHelpDialog();
                    if (dialog) dialog.open();
                }
                ToolTip.visible: hovered
                ToolTip.text: qsTr("获取帮助信息")

                // 美化按钮样式
                background: Rectangle {
                    color: helpButton.pressed ? Qt.darker(theme.accentColor, 1.2) :
                           (helpButton.hovered ? Qt.lighter(theme.accentColor, 1.1) : "transparent")
                    radius: 8
                    border.color: theme.accentColor
                    border.width: 1
                    implicitHeight: 36
                    implicitWidth: 80 
                }
                
                contentItem: Item {
                    implicitWidth: helpText.implicitWidth
                    implicitHeight: helpText.implicitHeight
                    
                    Text {
                        id: helpText
                        text: helpButton.text
                        font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }
        }
    } // End of ToolBar (header)

    // --- Main Content Area of Application Window ---
    // This ColumnLayout implicitly becomes the contentItem of ApplicationWindow,
    // occupying space below the header and above the footer.
    ColumnLayout {
        anchors.fill: parent // Fills the remaining space in ApplicationWindow
        spacing: 0

        // SplitView for Navigation and Main Views
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true // Fills available height after header

            // Left-side Navigation Bar
            Rectangle {
                implicitWidth: 200 // Default width
                SplitView.minimumWidth: 150 // Minimum resizable width
                SplitView.maximumWidth: 300 // Maximum resizable width
                color: Qt.lighter(primaryColor, 1.5) // Lighter shade of primary color

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Navigation Buttons (NavButton is a custom component)
                    NavButton {
                        text: qsTr("仪表盘")
                        iconName: "dashboard"
                        selected: currentPage === 0
                        onClicked: currentPage = 0
                    }

                    NavButton {
                        text: qsTr("交易列表")
                        iconName: "list"
                        selected: currentPage === 1
                        onClicked: currentPage = 1
                    }

                    NavButton {
                        text: qsTr("统计图表")
                        iconName: "chart"
                        selected: currentPage === 2
                        onClicked: currentPage = 2
                    }

                    NavButton {
                        text: qsTr("导入导出")
                        iconName: "import"
                        selected: currentPage === 3
                        onClicked: currentPage = 3
                    }

                    Item { Layout.fillHeight: true } // Filler to push "Settings" to bottom

                    NavButton {
                        text: qsTr("设置")
                        iconName: "settings"
                        selected: currentPage === 4
                        onClicked: currentPage = 4
                    }
                }
            }

            // Main Content Display Area
            Rectangle {
                SplitView.fillWidth: true // Takes up remaining width in SplitView
                color: bgColor // Background color from theme

                // 加载动画覆盖层
                Rectangle {
                    id: loadingOverlay
                    anchors.fill: parent
                    color: Qt.rgba(theme.backgroundColor.r, theme.backgroundColor.g, theme.backgroundColor.b, 0.8)
                    visible: isLoading
                    z: 1000 // 确保在最上层

                    BusyIndicator {
                        id: busyIndicator
                        anchors.centerIn: parent
                        running: isLoading
                        width: 80
                        height: 80
                    }
                    
                    Text {
                        anchors.top: busyIndicator.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("正在加载数据，请稍候...")
                        font.pixelSize: 16
                        color: theme.textColor
                    }
                }

                // StackLayout to switch between different views (Dashboard, Transactions, etc.)
                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 10 // anchors.margins around the content
                    currentIndex: currentPage // Controls which item is visible

                    // Dashboard View
                    Item {
                        DashboardView {} // Assuming DashboardView.qml exists
                    }

                    // Transaction List View
                    Item {
                        TransactionListView {} // Assuming TransactionListView.qml exists
                    }

                    // Chart Statistics View
                    Item {
                        // Loader to conditionally load ChartView.qml
                        Loader {
                            anchors.fill: parent
                            // Load ChartView only if QtCharts module is available
                            source: chartsAvailable ? "components/ChartView.qml" : ""

                            // Message displayed if QtCharts is not available
                            Text {
                                anchors.centerIn: parent
                                text: chartsAvailable ? "" : qsTr("图表功能需要Qt Charts模块支持")
                                font.pixelSize: 18
                                color: "gray"
                                visible: !chartsAvailable
                            }
                        }
                    }

                    // Import/Export Page
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 20
                            anchors.margins: 20 // Add anchors.margins for this page

                            Text {
                                text: qsTr("数据导入导出")
                                font.pixelSize: 24
                                font.bold: true
                                color: theme.textColor
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 120
                                color: cardColor
                                radius: 5
                                DropShadow { anchors.fill: parent; horizontalOffset: 2; verticalOffset: 2; radius: 5; color: "#20000000"; source: parent }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 40

                                    Button {
                                        text: qsTr("导入数据")
                                        icon.name: "import"
                                        onClicked: {
                                            var dialog = dialogLoader.loadImportDialog();
                                            if (dialog) dialog.open();
                                        }
                                    }

                                    Button {
                                        text: qsTr("导出数据")
                                        icon.name: "export"
                                        onClicked: {
                                            var dialog = dialogLoader.loadExportDialog();
                                            if (dialog) dialog.open();
                                        }
                                    }
                                }
                            }
                            Item { Layout.fillHeight: true } // Filler item
                        }
                    }

                    // Settings View
                    Item {
                        SettingsView {} // Assuming SettingsView.qml exists
                    }
                }
            }
        }

        // --- Bottom Status Bar ---
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: Qt.darker(primaryColor, 1.2) // Darker shade of primary color for footer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                Layout.alignment: Qt.AlignVCenter // Align items vertically in center

                Text {
                    text: qsTr("InvestLedger v") + appVersion // Display app version
                    color: "white"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true } // Filler to push copyright to right

                Text {
                    text: "©2023"
                    color: "white"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    } // End of main content ColumnLayout

    // --- Update Notification Dialog ---
    Dialog {
        id: updateDialog
        title: qsTr("发现新版本")
        width: 400
        height: 200
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        background: Rectangle { // Styling for update dialog
            color: theme.cardColor
            radius: 8
            border.color: Qt.darker(theme.cardColor, 1.2)
            border.width: 1
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
            spacing: 10
            anchors.margins: 15 // Add anchors.margins

            Text {
                text: qsTr("发现新版本，是否立即更新？")
                font.pixelSize: 16
                Layout.fillWidth: true
                color: theme.textColor
            }

            CheckBox {
                id: autoRestartCheckbox
                text: qsTr("更新后自动重启")
                checked: true
                Layout.alignment: Qt.AlignLeft
                contentItem: Text { // Custom content for thematic checkbox text
                    text: autoRestartCheckbox.text
                    font: autoRestartCheckbox.font
                    color: theme.textColor
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    text: qsTr("稍后")
                    onClicked: updateDialog.close()
                    background: Rectangle { // Styling for standard button
                        color: theme.backgroundColor
                        radius: 4
                        border.color: Qt.darker(theme.backgroundColor, 1.3)
                        border.width: 1
                        opacity: parent.enabled ? 1.0 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Label {
                        text: parent.text
                        font: parent.font
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: qsTr("立即更新")
                    highlighted: true
                    onClicked: {
                        backend.downloadUpdate(autoRestartCheckbox.checked); // Assuming backend handles download
                        updateDialog.close();
                    }
                    background: Rectangle { // Styling for highlighted button
                        color: theme.primaryColor
                        radius: 4
                        border.color: Qt.darker(theme.primaryColor, 1.1)
                        border.width: 1
                        opacity: parent.enabled ? 1.0 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Label {
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

    // --- Global Backend Signal Connections ---
    Connections {
        target: backend // Assuming 'backend' is a C++ object exposed to QML

        // Connect to an error signal from the backend
        function onErrorOccurred(message) {
            errorDialog.showError(message);
        }

        // Connect to an update available signal from the backend
        function onUpdateAvailable(version, notes) {
            updateDialog.open(); // Opens the update dialog when a new version is detected
            // 'version' and 'notes' parameters are available if you want to display them in the dialog.
        }
    }
}