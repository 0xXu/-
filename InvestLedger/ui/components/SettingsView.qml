import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: settingsView

    // 主题属性，由main.qml传入
    property var theme

    // 颜色选择
    property color selectedProfitColor: profitColor
    property color selectedLossColor: lossColor
    property int backupDays: 7
    property string appVersion: backend ? backend.getAppVersion() : "未知版本"

    // 保存设置
    function saveSettings() {
        // 这里在实际应用中应该保存设置到配置文件
        // 简化版本中只更新全局颜色
        profitColor = selectedProfitColor;
        lossColor = selectedLossColor;

        // 设置备份天数
        backend.cleanupBackups(backupDays);

        saveSuccessDialog.open();
    }

    // 备份数据库
    function backupDatabase() {
        var success = backend.backupDatabase();
        if (success) {
            backupSuccessDialog.open();
        } else {
            errorDialog.showError("备份数据库失败");
        }
    }
    
    // 检查更新
    function checkForUpdates() {
        if (backend.checkForUpdates()) {
            updateAvailableDialog.open();
        } else {
            noUpdatesDialog.open();
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        opacity: 0.0
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
        Component.onCompleted: opacity = 1.0;
        ColumnLayout {
            width: settingsView.width - 30
            spacing: 20

            // 设置标题
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: cardColor
                radius: 5
                opacity: 0.0
                SequentialAnimation on opacity {
                    NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuad }
                }
                Component.onCompleted: opacity = 1.0;
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    Text {
                        text: "应用设置"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "保存设置"
                        highlighted: true
                        onClicked: saveSettings()
                    }
                }
            }
            
            // 外观设置
            Rectangle {
                Layout.fillWidth: true
                height: 260
                color: cardColor
                radius: 5
                y: 40
                SequentialAnimation on y {
                    NumberAnimation { to: 0; duration: 400; easing.type: Easing.OutQuad }
                }
                Component.onCompleted: y = 0;
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    Text {
                        text: "外观设置"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 15
                        columnSpacing: 20
                        // 盈利颜色
                        Text {
                            text: "盈利颜色:"
                            font.pixelSize: 14
                        }
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 30
                                height: 30
                                color: selectedProfitColor
                                border.color: "black"
                                border.width: 1
                            }
                            Button {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogProfit.open();
                                }
                            }
                            Button {
                                text: "恢复默认"
                                onClicked: {
                                    selectedProfitColor = "#e74c3c"; // 假设这是默认盈利颜色
                                }
                            }
                        }
                        // 亏损颜色
                        Text {
                            text: "亏损颜色:"
                            font.pixelSize: 14
                        }
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 30
                                height: 30
                                color: selectedLossColor
                                border.color: "black"
                                border.width: 1
                            }
                            Button {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogLoss.open();
                                }
                            }
                            Button {
                                text: "恢复默认"
                                onClicked: {
                                    selectedLossColor = "#2ecc71"; // 假设这是默认亏损颜色
                                }
                            }
                        }
                        // 主题风格
                        Text {
                            text: "主题风格:"
                            font.pixelSize: 14
                        }
                        RowLayout {
                            ComboBox {
                                id: themeCombo
                                model: ["light", "dark", "system"]
                                currentIndex: themeCombo.model.indexOf(theme.currentTheme)
                                onCurrentIndexChanged: {
                                    theme.saveTheme(themeCombo.currentText);
                                }
                            }
                            
                            Button {
                                text: theme.isDarkTheme ? "切换到亮色" : "切换到暗色"
                                onClicked: {
                                    theme.saveTheme(theme.isDarkTheme ? "light" : "dark");
                                }
                            }
                        }
                        // 主色调
                        Text {
                            text: "主色调:"
                            font.pixelSize: 14
                        }
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 30
                                height: 30
                                color: theme.primaryColor
                                border.color: "black"
                                border.width: 1
                            }
                            Button {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogPrimary.open();
                                }
                            }
                            Button {
                                text: "恢复默认"
                                onClicked: {
                                    theme.setColor("primaryColor", "#2c3e50"); // 假设这是默认主色调
                                }
                            }
                        }
                        // 强调色
                        Text {
                            text: "强调色:"
                            font.pixelSize: 14
                        }
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 30
                                height: 30
                                color: theme.accentColor
                                border.color: "black"
                                border.width: 1
                            }
                            Button {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogAccent.open();
                                }
                            }
                            Button {
                                text: "恢复默认"
                                onClicked: {
                                    theme.setColor("accentColor", "#3498db"); // 假设这是默认强调色
                                }
                            }
                        }
                    }
                }
            }

            // 备份设置
            Rectangle {
                Layout.fillWidth: true
                height: 180
                color: cardColor
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "备份设置"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 15
                        columnSpacing: 20

                        // 备份天数
                        Text {
                            text: "保留备份天数:"
                            font.pixelSize: 14
                        }

                        SpinBox {
                            id: backupDaysSpinBox
                            from: 1
                            to: 30
                            value: backupDays

                            onValueChanged: {
                                backupDays = value;
                            }
                        }
                    }

                    RowLayout {
                        Layout.topMargin: 10
                        Layout.fillWidth: true

                        Button {
                            text: "立即备份数据库"
                            onClicked: backupDatabase()
                        }

                        Text {
                            text: "备份将保存在用户数据目录中"
                            font.pixelSize: 12
                            color: Qt.darker(textColor, 1.2) // 确保 textColor 在此上下文中可用
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // 目标设置
            Rectangle {
                Layout.fillWidth: true
                height: 250 // 此高度可能需要根据内容调整
                color: cardColor
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "盈利目标设置"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 15
                        columnSpacing: 20

                        // 月度目标
                        Text {
                            text: "月度目标:"
                            font.pixelSize: 14
                        }

                        SpinBox {
                            id: monthlyGoalSpinBox
                            from: 0
                            to: 1000000
                            value: 5000 // 内部值，乘以100后为5000.00
                            stepSize: 100

                            property int decimals: 2
                            property real realValue: value / 100

                            textFromValue: function(value, locale) {
                                return Number(value / 100).toLocaleString(locale, 'f', decimals)
                            }

                            valueFromText: function(text, locale) {
                                return Number.fromLocaleString(locale, text) * 100
                            }
                        }

                        ComboBox {
                            id: monthCombo
                            model: [
                                {text: "1月", value: 1}, {text: "2月", value: 2},
                                {text: "3月", value: 3}, {text: "4月", value: 4},
                                {text: "5月", value: 5}, {text: "6月", value: 6},
                                {text: "7月", value: 7}, {text: "8月", value: 8},
                                {text: "9月", value: 9}, {text: "10月", value: 10},
                                {text: "11月", value: 11}, {text: "12月", value: 12}
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: new Date().getMonth() // JavaScript的getMonth()返回0-11，所以1月是0
                        }

                        // 年份选择
                        Text {
                            text: "年份:"
                            font.pixelSize: 14
                        }

                        SpinBox {
                            id: yearSpinBox
                            from: 2020
                            to: 2100
                            value: new Date().getFullYear()
                        }

                        Button {
                            text: "设置月度目标"
                            onClicked: {
                                var success = backend.setBudgetGoal(
                                    yearSpinBox.value,
                                    monthCombo.currentValue, // currentValue 是 ComboBox model中定义的value
                                    monthlyGoalSpinBox.realValue
                                );

                                if (success) {
                                    goalSetSuccessDialog.open();
                                } else {
                                    errorDialog.showError("设置月度目标失败");
                                }
                            }
                        }
                    }
                }
            }
            
            // 软件更新
            Rectangle {
                Layout.fillWidth: true
                height: 150
                color: cardColor
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "软件更新"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        Text {
                            text: "当前版本："
                            font.pixelSize: 14
                        }

                        Text {
                            text: appVersion
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "检查更新"
                            onClicked: checkForUpdates()
                        }
                    }
                    
                    Text {
                        text: "定期更新软件可以获得新功能和修复问题。"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }
            
            // 关于软件
            Rectangle {
                Layout.fillWidth: true
                height: 200
                color: cardColor
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "关于软件"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: "InvestLedger - 轻量个人投资记账程序"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "版本：" + appVersion
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "© 2023 InvestLedger 团队，保留所有权利"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "这是一个简单易用的个人投资记账工具，帮助您跟踪和分析投资盈亏。"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        Layout.topMargin: 10
                        
                        Button {
                            text: "帮助文档"
                            onClicked: helpDialog.open()
                        }
                        
                        Button {
                            text: "技术支持"
                            onClicked: supportDialog.open()
                        }
                    }
                }
            }

            Item { height: 30 } // 底部间距
        }
    } // ScrollView end

    // 保存成功对话框
    Dialog {
        id: saveSuccessDialog
        title: "保存成功"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "设置保存成功！"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: saveSuccessDialog.close()
            }
        }
    }

    // 备份成功对话框
    Dialog {
        id: backupSuccessDialog
        title: "备份成功"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "数据库备份成功！"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: backupSuccessDialog.close()
            }
        }
    }

    // 目标设置成功对话框
    Dialog {
        id: goalSetSuccessDialog
        title: "目标设置成功"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "盈利目标设置成功！"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: goalSetSuccessDialog.close()
            }
        }
    }
    
    // 有更新可用对话框
    Dialog {
        id: updateAvailableDialog
        title: "发现新版本"
        width: 400
        height: 250
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "发现新版本！"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }
            
            Text {
                text: "有新版本可用：v" + backend.getLatestVersion() + "\n当前版本：" + appVersion
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Text {
                text: "新版本包含以下改进：\n• 用户界面优化\n• 性能提升\n• 问题修复"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
                    text: "稍后更新"
                    onClicked: updateAvailableDialog.close()
                }
                
                Button {
                    text: "立即更新"
                    highlighted: true
                    onClicked: {
                        backend.downloadUpdate(autoRestartCheckbox.checked);
                        updateAvailableDialog.close();
                    }
                }
            }
        }
    }
    
    // 无更新对话框
    Dialog {
        id: noUpdatesDialog
        title: "检查更新"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "您已经使用最新版本！"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: noUpdatesDialog.close()
            }
        }
    }
    
    // 帮助对话框
    Dialog {
        id: helpDialog
        title: "帮助文档"
        width: 500
        height: 400
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "InvestLedger 使用指南"
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                Text {
                    width: helpDialog.width - 40
                    wrapMode: Text.WordWrap
                    text: "## 基本使用\n\n" +
                          "1. **仪表盘**: 查看投资总览、盈亏状况和统计数据\n" +
                          "2. **交易列表**: 管理所有交易记录，支持筛选和排序\n" +
                          "3. **统计图表**: 通过图表直观展示投资表现\n" +
                          "4. **导入导出**: 支持数据的导入和导出\n\n" +
                          "## 添加交易\n\n" +
                          "在交易列表页面点击\"添加交易\"按钮，填写相关信息后保存。\n" +
                          "您也可以通过快速添加功能，使用文本格式录入交易。\n\n" +
                          "## 数据备份\n\n" +
                          "定期备份您的数据以防丢失。在设置页面的\"备份设置\"中可以手动备份数据库。\n\n" +
                          "## 设置目标\n\n" +
                          "您可以在设置中设定月度或年度的盈利目标，系统会显示当前进度。\n\n" +
                          "## 更多帮助\n\n" +
                          "如需更多帮助，请联系技术支持。"
                }
            }

            Button {
                text: "关闭"
                Layout.alignment: Qt.AlignRight
                onClicked: helpDialog.close()
            }
        }
    }
    
    // 技术支持对话框
    Dialog {
        id: supportDialog
        title: "技术支持"
        width: 400
        height: 200
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        contentItem: ColumnLayout {
            spacing: 20

            Text {
                text: "如果您在使用过程中遇到问题，请通过以下方式联系我们："
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: "邮件: support@investledger.example.com\n" +
                      "官网: www.investledger.example.com\n" +
                      "QQ群: 12345678"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: supportDialog.close()
            }
        }
    }

    // ColorDialogs
    ColorDialog {
        id: colorDialogProfit
        title: "选择盈利颜色"
        onAccepted: {
            settingsView.selectedProfitColor = color;
        }
    }
    ColorDialog {
        id: colorDialogLoss
        title: "选择亏损颜色"
        onAccepted: {
            settingsView.selectedLossColor = color;
        }
    }
    ColorDialog {
        id: colorDialogPrimary
        title: "选择主色调"
        onAccepted: {
            theme.setColor("primaryColor", color);
        }
    }
    ColorDialog {
        id: colorDialogAccent
        title: "选择强调色"
        onAccepted: {
            theme.setColor("accentColor", color);
        }
    }
}