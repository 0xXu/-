import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: settingsView

    // 颜色选择
    property color selectedProfitColor: profitColor
    property color selectedLossColor: lossColor
    property int backupDays: 7

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
                height: 260 // 注意：原始代码中这里是260，下面外观设置的GridLayout内容较多，可能需要调整此高度
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
                        ComboBox {
                            id: themeCombo
                            model: ["light", "dark", "system"]
                            currentIndex: themeCombo.model.indexOf(themeManager.currentTheme)
                            onCurrentIndexChanged: {
                                themeManager.saveTheme(themeCombo.currentText);
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
                                color: themeManager.primaryColor
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
                                    themeManager.setColor("primaryColor", "#2c3e50"); // 假设这是默认主色调
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
                                color: themeManager.accentColor
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
                                    themeManager.setColor("accentColor", "#3498db"); // 假设这是默认强调色
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

            Item { height: 20 } // 底部间距
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

    // 目标设置成功对话框 (保留了一个)
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
            themeManager.setColor("primaryColor", color);
        }
    }
    ColorDialog {
        id: colorDialogAccent
        title: "选择强调色"
        onAccepted: {
            themeManager.setColor("accentColor", color);
        }
    }
}