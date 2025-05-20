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
    
    // 自定义控件样式
    property int buttonHeight: 36
    property int buttonWidth: 100 // 减小按钮宽度以适应布局
    property int buttonRadius: 4
    property int inputHeight: 36
    property int inputRadius: 4
    property string buttonFontFamily: "Microsoft YaHei"
    property int buttonFontSize: 14
    property int inputFontSize: 14
    property int labelFontSize: 14
    property color buttonBgColor: theme ? theme.accentColor : "#3498db"
    property color buttonTextColor: "white"
    property color buttonBorderColor: Qt.darker(buttonBgColor, 1.1)
    property color inputBgColor: theme ? (theme.isDarkTheme ? "#2c3e50" : "#f5f5f5") : "#f5f5f5"
    property color inputBorderColor: theme ? (theme.isDarkTheme ? "#34495e" : "#d0d0d0") : "#d0d0d0"
    property color inputTextColor: theme ? (theme.isDarkTheme ? "white" : "black") : "black"

    // 自定义按钮组件
    component CustomButton: Rectangle {
        id: customBtn
        property string text: "按钮"
        property bool highlighted: false
        property bool isPressed: false
        signal clicked()

        width: buttonWidth
        height: buttonHeight
        radius: buttonRadius
        color: highlighted ? buttonBgColor : (theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0")
        border.color: highlighted ? buttonBorderColor : inputBorderColor
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.family: buttonFontFamily
            font.pixelSize: buttonFontSize
            color: highlighted ? buttonTextColor : (theme ? (theme.isDarkTheme ? "white" : "#333333") : "#333333")
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.opacity = 0.8
            onExited: parent.opacity = 1.0
            onPressed: parent.isPressed = true
            onReleased: parent.isPressed = false
            onClicked: parent.clicked()
        }

        states: [
            State {
                name: "pressed"
                when: isPressed
                PropertyChanges {
                    target: customBtn
                    color: highlighted ? Qt.darker(buttonBgColor, 1.2) : Qt.darker(color, 1.1)
                }
            }
        ]
    }

    // 自定义下拉框组件
    component CustomComboBox: Rectangle {
        id: customCombo
        property var model
        property string textRole: ""
        property string valueRole: ""
        property int currentIndex: 0
        property var currentText: model && model.length > 0 && currentIndex >= 0 ? 
                                 (textRole ? model[currentIndex][textRole] : model[currentIndex]) : ""
        property var currentValue: model && model.length > 0 && valueRole && currentIndex >= 0 ? 
                                 model[currentIndex][valueRole] : currentIndex
        signal indexChanged()

        width: buttonWidth * 1.2
        height: inputHeight
        radius: inputRadius
        color: inputBgColor
        border.color: inputBorderColor
        border.width: 1

        Text {
            id: selectedText
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: customCombo.currentText
            font.family: buttonFontFamily
            font.pixelSize: inputFontSize
            color: inputTextColor
        }

        Rectangle {
            width: height
            height: parent.height
            anchors.right: parent.right
            color: "transparent"
            Image {
                anchors.centerIn: parent
                source: theme && theme.isDarkTheme ? "qrc:/icons/dropdown_dark.png" : "qrc:/icons/dropdown_light.png"
                width: 12
                height: 12
                sourceSize.width: 12
                sourceSize.height: 12
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!dropdownMenu.visible) {
                    dropdownMenu.open()
                } else {
                    dropdownMenu.close()
                }
            }
        }

        Popup {
            id: dropdownMenu
            y: parent.height
            width: parent.width
            height: Math.min(300, contentItem.implicitHeight)
            padding: 0
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            contentItem: ListView {
                implicitHeight: contentHeight
                model: customCombo.model
                delegate: Rectangle {
                    width: parent.width
                    height: inputHeight
                    color: index === customCombo.currentIndex ? 
                           (theme ? theme.accentColor : "#3498db") : 
                           (theme ? (theme.isDarkTheme ? "#2c3e50" : "white") : "white")
                    
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: customCombo.textRole ? modelData[customCombo.textRole] : modelData
                        color: index === customCombo.currentIndex ? "white" : inputTextColor
                        font.family: buttonFontFamily
                        font.pixelSize: inputFontSize
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            customCombo.currentIndex = index
                            customCombo.indexChanged()
                            dropdownMenu.close()
                        }
                    }
                }
                
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }

    // 自定义SpinBox组件
    component CustomSpinBox: Rectangle {
        id: customSpin
        property int from: 0
        property int to: 100
        property int value: 0
        property int stepSize: 1
        property int decimals: 0
        property alias realValue: internalProps.realValue // 别名以便外部访问
        property var textFromValue: function(value, locale) { return value.toString() }
        property var valueFromText: function(text, locale) { return parseInt(text) }
        signal spinValueChanged()

        QtObject {
            id: internalProps
            property real realValue: customSpin.value // 默认realValue
        }
        
        width: buttonWidth * 1.2 // 例如 100 * 1.2 = 120
        height: inputHeight
        radius: inputRadius
        color: inputBgColor
        border.color: inputBorderColor
        border.width: 1

        Row {
            anchors.fill: parent
            spacing: 1 // 稍微增加一点间距

            Rectangle { // Minus button
                id: minusButton
                width: 30 // 固定宽度
                height: parent.height
                color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "-"
                    font.pixelSize: 20
                    color: inputTextColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (customSpin.value > customSpin.from) {
                            customSpin.value -= customSpin.stepSize
                            customSpin.spinValueChanged()
                        }
                    }
                }
            }

            Rectangle { // TextInput container
                width: parent.width - minusButton.width - plusButton.width - parent.spacing * 2
                height: parent.height
                color: "transparent"
                
                TextInput {
                    id: spinInput
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    anchors.rightMargin: 5
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    text: customSpin.textFromValue(customSpin.value, Qt.locale())
                    font.family: buttonFontFamily
                    font.pixelSize: inputFontSize
                    color: inputTextColor
                    selectByMouse: true
                    validator: IntValidator {
                        bottom: customSpin.from
                        top: customSpin.to
                    }
                    
                    onEditingFinished: {
                        var parsedValue = customSpin.valueFromText(text, Qt.locale())
                        if (parsedValue >= customSpin.from && parsedValue <= customSpin.to) {
                           customSpin.value = parsedValue
                        } else {
                            // 如果值无效，恢复到旧值
                            spinInput.text = customSpin.textFromValue(customSpin.value, Qt.locale())
                        }
                        customSpin.spinValueChanged()
                    }
                }
            }

            Rectangle { // Plus button
                id: plusButton
                width: 30 // 固定宽度
                height: parent.height
                color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 20
                    color: inputTextColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (customSpin.value < customSpin.to) {
                            customSpin.value += customSpin.stepSize
                            customSpin.spinValueChanged()
                        }
                    }
                }
            }
        }
        Component.onCompleted: {
            // Allow specific instances to override realValue calculation
            if (typeof monthlyGoalSpinBox !== 'undefined' && customSpin === monthlyGoalSpinBox) {
                 internalProps.realValue = customSpin.value / 100.0
            }
        }
        onSpinValueChanged: {
             if (typeof monthlyGoalSpinBox !== 'undefined' && customSpin === monthlyGoalSpinBox) {
                 internalProps.realValue = customSpin.value / 100.0
            } else {
                 internalProps.realValue = customSpin.value
            }
        }
    }
    
    // 自定义CheckBox组件
    component CustomCheckBox: Row {
        id: customCheck
        property bool checked: false
        property string text: "选项"
        signal checkClicked()
        spacing: 8
        
        Rectangle {
            id: checkRect
            width: 20
            height: 20
            radius: 3
            border.color: inputBorderColor
            border.width: 1
            color: customCheck.checked ? buttonBgColor : inputBgColor
            anchors.verticalCenter: parent.verticalCenter
            
            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "white"
                font.pixelSize: 14
                visible: customCheck.checked
            }
        }
        
        Text {
            text: customCheck.text
            font.family: buttonFontFamily
            font.pixelSize: labelFontSize
            color: theme ? (theme.isDarkTheme ? "white" : "#333333") : "#333333"
            anchors.verticalCenter: parent.verticalCenter
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                customCheck.checked = !customCheck.checked
                customCheck.checkClicked()
            }
        }
    }

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

            // 设置标题 (移除保存按钮)
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

                    // 保存设置按钮已移除
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
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        RowLayout {
                            spacing: 10
                            Layout.alignment: Qt.AlignLeft
                            Rectangle {
                                width: 30
                                height: 30
                                color: selectedProfitColor
                                border.color: "black"
                                border.width: 1
                            }
                            CustomButton {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogProfit.open();
                                }
                            }
                            CustomButton {
                                text: "恢复默认"
                                onClicked: {
                                    selectedProfitColor = "#e74c3c";
                                    profitColor = selectedProfitColor; // 即时应用
                                }
                            }
                        }
                        // 亏损颜色
                        Text {
                            text: "亏损颜色:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        RowLayout {
                            spacing: 10
                            Layout.alignment: Qt.AlignLeft
                            Rectangle {
                                width: 30
                                height: 30
                                color: selectedLossColor
                                border.color: "black"
                                border.width: 1
                            }
                            CustomButton {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogLoss.open();
                                }
                            }
                            CustomButton {
                                text: "恢复默认"
                                onClicked: {
                                    selectedLossColor = "#2ecc71";
                                    lossColor = selectedLossColor; // 即时应用
                                }
                            }
                        }
                        // 主题风格
                        Text {
                            text: "主题风格:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignLeft
                            spacing: 10
                            CustomComboBox {
                            id: themeCombo
                            model: ["light", "dark", "system"]
                                currentIndex: model.indexOf(theme.currentTheme)
                                onIndexChanged: {
                                    theme.saveTheme(currentText);
                                }
                            }
                            
                            CustomButton {
                                text: theme.isDarkTheme ? "切换到亮色" : "切换到暗色"
                                onClicked: {
                                    theme.saveTheme(theme.isDarkTheme ? "light" : "dark");
                                }
                            }
                        }
                        // 主色调
                        Text {
                            text: "主色调:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        RowLayout {
                            spacing: 10
                            Layout.alignment: Qt.AlignLeft
                            Rectangle {
                                width: 30
                                height: 30
                                color: theme.primaryColor
                                border.color: "black"
                                border.width: 1
                            }
                            CustomButton {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogPrimary.open();
                                }
                            }
                            CustomButton {
                                text: "恢复默认"
                                onClicked: {
                                    theme.setColor("primaryColor", "#2c3e50");
                                }
                            }
                        }
                        // 强调色
                        Text {
                            text: "强调色:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }
                        RowLayout {
                            spacing: 10
                            Layout.alignment: Qt.AlignLeft
                            Rectangle {
                                width: 30
                                height: 30
                                color: theme.accentColor
                                border.color: "black"
                                border.width: 1
                            }
                            CustomButton {
                                text: "选择颜色"
                                onClicked: {
                                    colorDialogAccent.open();
                                }
                            }
                            CustomButton {
                                text: "恢复默认"
                                onClicked: {
                                    theme.setColor("accentColor", "#3498db");
                                }
                            }
                        }
                    }
                }
            }

            // 备份设置
            Rectangle {
                Layout.fillWidth: true
                // height: 180  // 移除固定高度
                implicitHeight: backupSettingsLayout.implicitHeight + 30 // 根据内容自动调整高度
                color: cardColor
                radius: 5

                ColumnLayout {
                    id: backupSettingsLayout
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

                        Text {
                            text: "保留备份天数:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }

                        CustomSpinBox {
                            id: backupDaysSpinBox
                            from: 1
                            to: 30
                            value: settingsView.backupDays

                            onSpinValueChanged: {
                                settingsView.backupDays = value;
                                backend.cleanupBackups(value);
                            }
                        }
                    }

                    RowLayout {
                        Layout.topMargin: 10
                        Layout.fillWidth: true

                        CustomButton {
                            text: "立即备份数据库"
                            onClicked: backupDatabase()
                        }

                        Text {
                            text: "备份将保存在用户数据目录中"
                            font.pixelSize: 12
                            color: Qt.darker(textColor, 1.2)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            Layout.leftMargin: 10
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // 目标设置
            Rectangle {
                Layout.fillWidth: true
                // height: 250  // 移除固定高度
                implicitHeight: goalSettingsLayout.implicitHeight + 30 // 根据内容自动调整高度
                color: cardColor
                radius: 5

                ColumnLayout {
                    id: goalSettingsLayout
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

                        Text {
                            text: "月度目标:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }

                        CustomSpinBox {
                            id: monthlyGoalSpinBox
                            width: buttonWidth * 1.4
                            from: 0
                            to: 100000000
                            value: 5000
                            stepSize: 100

                            textFromValue: function(val, locale) {
                                return Number(val / 100.0).toLocaleString(locale, 'f', 2)
                            }

                            valueFromText: function(txt, locale) {
                                var num = Number.fromLocaleString(locale, txt);
                                return Math.round(num * 100);
                            }
                            
                            Component.onCompleted: {
                                internalProps.realValue = value / 100.0;
                            }
                            onSpinValueChanged: {
                                internalProps.realValue = value / 100.0;
                            }
                        }

                        CustomComboBox {
                            id: monthCombo
                            width: buttonWidth * 0.8
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
                            currentIndex: new Date().getMonth()
                        }

                        Text {
                            text: "年份:"
                            font.pixelSize: labelFontSize
                            verticalAlignment: Text.AlignVCenter
                        }

                        CustomSpinBox {
                            id: yearSpinBox
                            width: buttonWidth * 1.0
                            from: 2020
                            to: 2100
                            value: new Date().getFullYear()
                        }

                        CustomButton {
                            text: "设置月度目标"
                            Layout.columnSpan: comportementGrid.columns > 2 ? 1 : comportementGrid.columns
                            Layout.alignment: Qt.AlignRight
                            onClicked: {
                                var success = backend.setBudgetGoal(
                                    yearSpinBox.value,
                                    monthCombo.currentValue,
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
                // height: 150  // 移除固定高度
                implicitHeight: updateLayout.implicitHeight + 30 // 根据内容自动调整高度
                color: cardColor
                radius: 5

                ColumnLayout {
                    id: updateLayout
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
                            font.pixelSize: labelFontSize
                        }

                        Text {
                            text: appVersion
                            font.pixelSize: labelFontSize
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        CustomButton {
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
                // height: 200  // 移除固定高度
                implicitHeight: aboutLayout.implicitHeight + 30 // 根据内容自动调整高度
                color: cardColor
                radius: 5

                ColumnLayout {
                    id: aboutLayout
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
                        font.pixelSize: labelFontSize
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "版本：" + appVersion
                        font.pixelSize: labelFontSize
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "© 2023 InvestLedger 团队，保留所有权利"
                        font.pixelSize: labelFontSize
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
                        
                        CustomButton {
                            text: "帮助文档"
                            onClicked: helpDialog.open()
                        }
                        
                        CustomButton {
                            text: "技术支持"
                            onClicked: supportDialog.open()
                        }
                    }
                }
            }

            Item { height: 30 } // 底部间距
        }
    } // ScrollView end

    // 保存成功对话框 (已移除，因为不再有全局保存按钮)
    /*
    Dialog {
        id: saveSuccessDialog
        // ...
    }
    */

    // 备份成功对话框
    Dialog {
        id: backupSuccessDialog
        title: "备份成功"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: "数据库备份成功！"
            wrapMode: Text.WordWrap
        }
    }

    // 目标设置成功对话框
    Dialog {
        id: goalSetSuccessDialog
        title: "目标设置成功"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: "盈利目标设置成功！"
            wrapMode: Text.WordWrap
        }
    }
    
    // 有更新可用对话框 (Ensure CustomButton and CustomCheckBox are used)
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
                text: "有新版本可用：v" + (backend ? backend.getLatestVersion() : "N/A") + "\n当前版本：" + appVersion
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Text {
                text: "新版本包含以下改进：\n• 用户界面优化\n• 性能提升\n• 问题修复"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            CustomCheckBox {
                id: autoRestartCheckbox
                text: "更新后自动重启"
                checked: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                CustomButton {
                    text: "稍后更新"
                    onClicked: updateAvailableDialog.close()
                }
                
                CustomButton {
                    text: "立即更新"
                    highlighted: true
                    onClicked: {
                        if(backend) backend.downloadUpdate(autoRestartCheckbox.checked);
                        updateAvailableDialog.close();
                    }
                }
            }
        }
    }

    // 无更新对话框 (Ensure CustomButton is used)
    Dialog {
        id: noUpdatesDialog
        title: "检查更新"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: "您已经使用最新版本！"
            wrapMode: Text.WordWrap
        }
    }
    
    // 帮助对话框 (Ensure CustomButton is used)
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

            CustomButton {
                text: "关闭"
                Layout.alignment: Qt.AlignRight
                onClicked: helpDialog.close()
            }
        }
    }

    // 技术支持对话框 (Ensure CustomButton is used)
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

            CustomButton {
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
            profitColor = color; // 即时应用
        }
    }
    ColorDialog {
        id: colorDialogLoss
        title: "选择亏损颜色"
        onAccepted: {
            settingsView.selectedLossColor = color;
            lossColor = color; // 即时应用
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