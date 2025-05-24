import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
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
        property color bgColor: buttonBgColor // Default to theme's accent color or a fallback
        signal clicked()

        width: buttonWidth
        height: buttonHeight
        radius: buttonRadius
        color: highlighted ? bgColor : (isPressed ? Qt.darker(bgColor, 1.1) : (theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0")) // Use bgColor here
        border.color: highlighted ? Qt.darker(bgColor, 1.1) : inputBorderColor // Use bgColor for highlighted border
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
            onEntered: parent.opacity = highlighted ? 1.0 : 0.8 // Keep highlighted buttons fully opaque
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
                    // Color change is handled in the main color property binding now
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
        signal activated(int index) // 添加activated信号

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
                            customCombo.activated(index) // 触发activated信号
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

    // 添加Toast提示组件
    component Toast: Rectangle {
        id: toastRoot
        property string message: ""
        property int displayTime: 2000 // 显示2秒
        property bool showing: false
        
        width: toastMessage.implicitWidth + 40
        height: 40
        radius: 20
        color: Qt.rgba(0, 0, 0, 0.7)
        opacity: showing ? 1.0 : 0.0
        visible: opacity > 0
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: showing ? 40 : -50
        
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }
        
        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }
        
        Text {
            id: toastMessage
            anchors.centerIn: parent
            text: toastRoot.message
            color: "white"
            font.pixelSize: 14
        }
        
        Timer {
            id: hideTimer
            interval: toastRoot.displayTime
            onTriggered: {
                toastRoot.showing = false;
            }
        }
        
        function show(msg) {
            message = msg;
            showing = true;
            hideTimer.restart();
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
        
        // 同步设置到仪表盘
        if (backend) {
            backend.refreshDashboard();
        }

        // 显示Toast提示
        settingsToast.show("设置已保存");
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

    // Behavior on opacity for the main view (moved from ScrollView)
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
    Component.onCompleted: settingsView.opacity = 1.0; // settingsView is the root Item, assuming opacity is on it or Flickable

    Flickable {
        id: flickableArea
        anchors.fill: parent
        clip: true
        // Assuming settingsView is the root Item and flickableArea should have an initial opacity of 0 too
        // and then fade in. If settingsView itself has the opacity, this is not needed here.
        // opacity: 0.0 

        contentWidth: settingsColumnLayout.width
        contentHeight: settingsColumnLayout.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds // Or Flickable.DragOverBounds for overscroll

        // The main content layout
        ColumnLayout {
            id: settingsColumnLayout
            width: flickableArea.width - (customScrollbar.visible ? customScrollbar.width + customScrollbar.anchors.rightMargin : 0) - 30 // Adjust width for scrollbar and padding
            spacing: 20

            // Prevent layout loops by only binding width if flickableArea.width changes significantly
            // This might not be strictly necessary but can help in complex layouts.
            // onWidthChanged: { if (Math.abs(width - (flickableArea.width - ...)) > 1) updateLayout(); }
            // function updateLayout() { width = ... } 

            // Setting page title bar (Example of one card, others follow the same pattern)
            Rectangle {
                id: titleCard // Ensure IDs are unique if they were based on ScrollView
                Layout.fillWidth: true
                implicitHeight: titleLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                }
                
                RowLayout {
                    id: titleLayout
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    // 标题和图标
                    RowLayout {
                        spacing: 12
                        
                        // 设置图标
                        Rectangle {
                            width: 36
                            height: 36
                            radius: width/2
                            color: theme ? theme.primaryColor : "#3498db"
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⚙️"
                                font.pixelSize: 18
                            }
                        }
                        
                        // 标题文字
                        Column {
                            spacing: 4

                    Text {
                        text: "应用设置"
                        font.pixelSize: 18
                        font.bold: true
                                color: theme ? theme.textColor : "black"
                            }
                            
                            Text {
                                text: "自定义应用外观和功能行为"
                                font.pixelSize: 12
                                color: Qt.darker(textColor, 1.2)
                                opacity: 0.7
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // 保存设置按钮
                    CustomButton {
                        text: "保存设置"
                        highlighted: true
                        onClicked: saveSettings()
                    }
                    }
                }
            
            // 外观设置
            Rectangle {
                id: appearanceCard
                Layout.fillWidth: true
                implicitHeight: appearanceLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                }
                
                ColumnLayout {
                    id: appearanceLayout
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 16
                    
                    // 卡片标题
                    RowLayout {
                        Layout.fillWidth: true
                    spacing: 10
                        
                    Text {
                        text: "外观设置"
                        font.pixelSize: 16
                        font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme ? Qt.alpha(theme.borderColor, 0.5) : "#e0e0e0"
                        }
                    }
                    
                    // 卡片内容
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 18
                        columnSpacing: 24
                        
                        // 盈利颜色
                        Text {
                            text: "盈利颜色:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            
                            // 颜色预览块
                            Rectangle {
                                width: 36
                                height: 24
                                radius: 4
                                color: selectedProfitColor
                                border.color: theme ? Qt.alpha(theme.borderColor, 0.7) : "#d0d0d0"
                                border.width: 1
                                
                                // 颜色名称或数值
                                Text {
                                    anchors.centerIn: parent
                                    text: selectedProfitColor.toString().toUpperCase()
                                    font.pixelSize: 9
                                    color: Qt.rgba(
                                        1.0 - selectedProfitColor.r,
                                        1.0 - selectedProfitColor.g,
                                        1.0 - selectedProfitColor.b,
                                        1.0
                                    )
                                    visible: false // 设置为true可以显示颜色代码
                                }
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
                                    selectedProfitColor = "#4CAF50";
                                    profitColor = selectedProfitColor; // 即时应用
                                }
                            }
                        }
                        
                        // 亏损颜色
                        Text {
                            text: "亏损颜色:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            
                            // 颜色预览块
                            Rectangle {
                                width: 36
                                height: 24
                                radius: 4
                                color: selectedLossColor
                                border.color: theme ? Qt.alpha(theme.borderColor, 0.7) : "#d0d0d0"
                                border.width: 1
                                
                                // 颜色名称或数值
                                Text {
                                    anchors.centerIn: parent
                                    text: selectedLossColor.toString().toUpperCase()
                                    font.pixelSize: 9
                                    color: Qt.rgba(
                                        1.0 - selectedLossColor.r,
                                        1.0 - selectedLossColor.g,
                                        1.0 - selectedLossColor.b,
                                        1.0
                                    )
                                    visible: false // 设置为true可以显示颜色代码
                                }
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
                                    selectedLossColor = "#F44336";
                                    lossColor = selectedLossColor; // 即时应用
                                }
                            }
                        }
                        
                        // 主题风格
                        Text {
                            text: "主题风格:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        ColumnLayout {
                            spacing: 8
                            
                        RowLayout {
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                spacing: 12
                                
                                Row {
                                    spacing: 4
                                    
                                    // 主题选择按钮组
                                    Repeater {
                                        model: [
                                            { name: "亮色", value: "light", icon: "☀️" },
                                            { name: "暗色", value: "dark", icon: "🌙" },
                                            { name: "系统", value: "system", icon: "🖥️" }
                                        ]
                                        
                                        Rectangle {
                                            width: 70
                                            height: 32
                                            radius: 6
                                            color: theme.currentTheme === modelData.value ? 
                                                theme.accentColor : 
                                                theme ? (theme.isDarkTheme ? "#2c3e50" : "#f5f5f5") : "#f5f5f5"
                                            border.color: theme.currentTheme === modelData.value ? 
                                                theme.accentColor : 
                                                theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0"
                                            border.width: 1
                                            
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                
                                                Text {
                                                    text: modelData.icon
                                                    font.pixelSize: 14
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                
                                                Text {
                                                    text: modelData.name
                                                    font.pixelSize: 13
                                                    color: theme.currentTheme === modelData.value ? 
                                                        "white" : 
                                                        theme ? theme.textColor : "black"
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                onClicked: {
                                                    theme.saveTheme(modelData.value);
                                                }
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Text {
                                text: theme.isDarkTheme ? 
                                    "暗色主题适合夜间使用，减轻眼睛疲劳" : 
                                    "亮色主题适合日间使用，提高可读性"
                                font.pixelSize: 11
                                color: Qt.darker(textColor, 1.2)
                                opacity: 0.7
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                        
                        // 主色调
                        Text {
                            text: "主色调:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            
                            // 颜色预览块
                            Rectangle {
                                width: 36
                                height: 24
                                radius: 4
                                color: theme.primaryColor
                                border.color: theme ? Qt.alpha(theme.borderColor, 0.7) : "#d0d0d0"
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
                                    theme.setColor("primaryColor", "#4CAF50");
                                }
                            }
                        }
                        
                        // 强调色
                        Text {
                            text: "强调色:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            
                            // 颜色预览块
                            Rectangle {
                                width: 36
                                height: 24
                                radius: 4
                                color: theme.accentColor
                                border.color: theme ? Qt.alpha(theme.borderColor, 0.7) : "#d0d0d0"
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
                                    theme.setColor("accentColor", "#2196F3");
                                }
                            }
                        }
                    }
                }
            }

            // 备份设置
            Rectangle {
                id: backupCard
                Layout.fillWidth: true
                implicitHeight: backupSettingsLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                }

                ColumnLayout {
                    id: backupSettingsLayout
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 16

                    // 卡片标题
                    RowLayout {
                        Layout.fillWidth: true
                    spacing: 10

                    Text {
                            text: "备份与恢复"
                        font.pixelSize: 16
                        font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme ? Qt.alpha(theme.borderColor, 0.5) : "#e0e0e0"
                        }
                    }
                    
                    // 说明文本
                    Text {
                        text: "定期备份可以防止数据丢失，您可以随时恢复历史备份"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        opacity: 0.8
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // 备份内容设置
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 18
                        columnSpacing: 24

                        Text {
                            text: "保留备份天数:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                        CustomSpinBox {
                            id: backupDaysSpinBox
                            from: 1
                                to: 90
                            value: settingsView.backupDays

                            onSpinValueChanged: {
                                settingsView.backupDays = value;
                                }
                            }
                            
                            Text {
                                text: "天"
                                font.pixelSize: labelFontSize
                                color: theme ? theme.textColor : "black"
                            }
                        }
                        
                        Text {
                            text: "自动备份频率:"
                            font.pixelSize: labelFontSize
                            color: theme ? theme.textColor : "black"
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        RowLayout {
                            spacing: 12
                            
                            CustomComboBox {
                                id: backupIntervalCombo
                                model: [
                                    { text: "每次退出", value: "exit" },
                                    { text: "每天", value: "daily" }, 
                                    { text: "每周", value: "weekly" },
                                    { text: "从不", value: "never" }
                                ]
                                textRole: "text"
                                valueRole: "value"
                                currentIndex: 1 // 默认为每天
                                
                                onIndexChanged: {
                                    // 保存自动备份频率设置
                                    if(backend) {
                                        backend.setBackupInterval(currentValue);
                                    }
                                }
                            }
                            
                            Rectangle { // WarningRect
                                color: "#FFF9C4" // 浅黄色背景
                                radius: 4
                                height: 28
                                // width: childrenRect.width + 16 // OLD
                                implicitWidth: warningRow.implicitWidth + 16 // NEW
                                visible: backupIntervalCombo.currentValue === "never"
                                
                                Row {
                                    id: warningRow // Assign an ID to the Row
                                    anchors.centerIn: parent
                                    spacing: 6
                                    
                                    Text {
                                        text: "⚠️"
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    Text {
                                        text: "不推荐"
                                        font.pixelSize: 12
                                        color: "#FF6F00" // 深橙色
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    // 备份操作按钮
                    RowLayout {
                        Layout.topMargin: 10
                        Layout.fillWidth: true
                        spacing: 16

                        // 立即备份按钮
                        Rectangle {
                            Layout.preferredWidth: 140
                            height: 36
                            radius: 4
                            color: theme.accentColor
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Text {
                                    text: "💾"
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: "立即备份"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                            onClicked: backupDatabase()
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.9
                                onExited: parent.opacity = 1.0
                            }
                        }
                        
                        // 恢复备份按钮
                        Rectangle {
                            Layout.preferredWidth: 140
                            height: 36
                            radius: 4
                            color: "transparent"
                            border.color: theme.accentColor
                            border.width: 1
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                        Text {
                                    text: "🔄"
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: "恢复备份"
                                    color: theme.accentColor
                                    font.bold: true
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: restoreBackupDialog.open()
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.9
                                onExited: parent.opacity = 1.0
                            }
                        }
                        
                        // 查看备份按钮
                        Rectangle {
                            Layout.preferredWidth: 140
                            height: 36
                            radius: 4
                            color: "transparent"
                            border.color: inputBorderColor
                            border.width: 1
                            
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Text {
                                    text: "📂"
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: "查看备份文件"
                                    color: theme ? theme.textColor : "black"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    backend.openBackupFolder();
                                }
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.8
                                onExited: parent.opacity = 1.0
                            }
                        }
                    }
                    
                    // 备份信息提示
                    Rectangle {
                        Layout.fillWidth: true
                        height: backupInfoText.implicitHeight + 16
                        color: theme.isDarkTheme ? Qt.rgba(0.2, 0.3, 0.4, 0.3) : Qt.rgba(0.9, 0.95, 1.0, 0.5)
                        radius: 4
                        border.width: 1
                        border.color: theme.isDarkTheme ? Qt.rgba(0.3, 0.4, 0.5, 0.3) : Qt.rgba(0.8, 0.85, 0.9, 0.5)
                        
                        Text {
                            id: backupInfoText
                            anchors.fill: parent
                            anchors.margins: 8
                            text: "备份文件保存在: " + (backend ? backend.getBackupPath() : "用户数据目录") + "\n" +
                                  "当前系统上次备份时间: " + (backend ? backend.getLastBackupTime() : "未知")
                            font.pixelSize: 12
                            color: Qt.darker(textColor, 1.2)
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // 分析设置
            Rectangle {
                id: analysisCard // Renamed from potential conflict if old id was analysisSettingsLayout
                Layout.fillWidth: true
                implicitHeight: analysisSettingsLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                }

                ColumnLayout {
                    id: analysisSettingsLayout // This ID seems to be used for the content
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 16

                    // 卡片标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                    Text {
                            text: "分析设置"
                        font.pixelSize: 16
                        font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme ? Qt.alpha(theme.borderColor, 0.5) : "#e0e0e0"
                        }
                    }
                    
                    // 说明文本
                    Text {
                        text: "调整分析参数，生成更精准的统计和建议"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        opacity: 0.8
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    // 添加分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: inputBorderColor
                        opacity: 0.5
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }

                    // 分析设置选项卡 - 使用更现代的设计
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: analysisContent.implicitHeight + 30
                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.3) : Qt.rgba(0.97, 0.97, 1.0, 0.7)) : "#f5f5f5"
                        radius: 8
                        border.width: 1
                        border.color: theme ? (theme.isDarkTheme ? Qt.rgba(0.3, 0.3, 0.5, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 1.0)) : "#d0d0d0"
                        
                        ColumnLayout {
                            id: analysisContent
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            
                            // 统计区间设置
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                
                                // 统计区间
                                Text {
                                    text: "统计区间:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                CustomComboBox {
                                    id: statisticsPeriodCombo
                                    model: ["近7天", "近30天", "本月", "本季度", "本年", "全部"]
                                    currentIndex: 2 // 默认选择"本月"
                                    
                                    onActivated: {
                                        if (backend) {
                                            backend.setStatisticsPeriod(currentIndex);
                                        }
                                    }
                                }
                                
                                // 将收益计入统计
                                Text {
                                    text: "将股息计入统计:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                CustomCheckBox {
                                    id: includeDividendCheck
                                    text: ""
                                    checked: true
                                    
                                    onCheckClicked: {
                                        if (backend) {
                                            backend.setIncludeDividend(checked);
                                        }
                                    }
                                }
                                
                                // 将手续费计入统计
                                        Text {
                                    text: "将手续费计入统计:"
                                    font.pixelSize: labelFontSize
                                            color: theme ? theme.textColor : "black"
                                }
                                
                                CustomCheckBox {
                                    id: includeFeeCheck
                                    text: ""
                                    checked: true
                                    
                                    onCheckClicked: {
                                        if (backend) {
                                            backend.setIncludeFee(checked);
                                        }
                                    }
                                }
                                
                                // 项目分组方式
                                        Text {
                                    text: "项目分组方式:"
                                    font.pixelSize: labelFontSize
                                            color: theme ? theme.textColor : "black"
                                }
                                
                                CustomComboBox {
                                    id: projectGroupingCombo
                                    model: ["按项目", "按类别", "按平台"]
                                    currentIndex: 0
                                    
                                    onActivated: {
                                        if (backend) {
                                            backend.setProjectGrouping(currentIndex);
                                        }
                                    }
                                }
                            }
                            
                            // 高级分析设置
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Text {
                                    text: "高级分析选项"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: theme ? Qt.alpha(theme.borderColor, 0.3) : "#e0e0e0"
                                }
                                
                                // 高级选项内容
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 15
                                    columnSpacing: 15
                                    
                                    // 生成风险评估
                                Text {
                                        text: "生成风险评估:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                    CustomCheckBox {
                                        id: riskAssessmentCheck
                                        text: ""
                                        checked: true
                                        
                                        onCheckClicked: {
                                            if (backend) {
                                                backend.setGenerateRiskAssessment(checked);
                                            }
                                        }
                                    }
                                    
                                    // 生成投资建议
                                        Text {
                                        text: "生成投资建议:"
                                        font.pixelSize: labelFontSize
                                            color: theme ? theme.textColor : "black"
                                    }
                                    
                                    CustomCheckBox {
                                        id: investmentAdviceCheck
                                        text: ""
                                        checked: true
                                        
                                        onCheckClicked: {
                                            if (backend) {
                                                backend.setGenerateInvestmentAdvice(checked);
                                            }
                                        }
                                    }
                                    
                                    // AI分析深度
                                        Text {
                                        text: "AI分析深度:"
                                        font.pixelSize: labelFontSize
                                            color: theme ? theme.textColor : "black"
                                    }
                                    
                                    CustomComboBox {
                                        id: aiAnalysisDepthCombo
                                        model: ["简要", "标准", "详细"]
                                        currentIndex: 1
                                        
                                        onActivated: {
                                            if (backend) {
                                                backend.setAiAnalysisDepth(currentIndex);
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            // 操作按钮
                                RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                    spacing: 10
                                    
                                Item { Layout.fillWidth: true }
                                
                                CustomButton {
                                    text: "重置默认"
                                    implicitWidth: 100
                                    
                                    onClicked: {
                                        statisticsPeriodCombo.currentIndex = 2; // "本月"
                                        includeDividendCheck.checked = true;
                                        includeFeeCheck.checked = true;
                                        projectGroupingCombo.currentIndex = 0;
                                        riskAssessmentCheck.checked = true;
                                        investmentAdviceCheck.checked = true;
                                        aiAnalysisDepthCombo.currentIndex = 1;
                                        
                                        if (backend) {
                                            backend.resetAnalysisSettings();
                                        }
                                    }
                                }
                                
                                CustomButton {
                                    text: "立即分析"
                                    implicitWidth: 100
                                    bgColor: theme ? theme.primaryColor : "#4CAF50"
                                    
                                    onClicked: {
                                        if (backend) {
                                            backend.runAnalysis();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 目标设置
            Rectangle {
                id: goalCard 
                Layout.fillWidth: true
                implicitHeight: goalSettingsLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: Qt.rgba(0, 0, 0, 0.15)
                }

                ColumnLayout {
                    id: goalSettingsLayout
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 16

                    // 卡片标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Text {
                            text: "盈利目标设置"
                            font.pixelSize: 16
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme ? Qt.alpha(theme.borderColor, 0.5) : "#e0e0e0"
                        }
                    }
                    
                    // 说明文本
                    Text {
                        text: "设置月度和年度盈利目标，系统将在仪表盘显示完成进度"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        opacity: 0.8
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // 添加分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: inputBorderColor
                        opacity: 0.5
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }

                    // 目标设置模式选择器
                    Text {
                        text: "目标设置模式:"
                        font.pixelSize: labelFontSize
                        color: theme ? theme.textColor : "black"
                    }
                    
                    // 标签页切换控件
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 20
                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.7) : Qt.rgba(0.9, 0.9, 0.9, 1.0)) : "#f0f0f0"
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 0
                            
                            // 常规模式按钮
                            Rectangle {
                                width: parent.width / 2
                                height: parent.height - 6
                                radius: height / 2
                                color: !goalSettingsLayout.isCompoundMode ? theme.primaryColor : "transparent"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "常规模式"
                                    font.pixelSize: 14
                                    color: !goalSettingsLayout.isCompoundMode ? "white" : theme.textColor
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        goalSettingsLayout.isCompoundMode = false;
                                    }
                                }
                            }
                            
                            // 复利模式按钮
                            Rectangle {
                                width: parent.width / 2
                                height: parent.height - 6
                                radius: height / 2
                                color: goalSettingsLayout.isCompoundMode ? theme.primaryColor : "transparent"
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "复利模式"
                                    font.pixelSize: 14
                                    color: goalSettingsLayout.isCompoundMode ? "white" : theme.textColor
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        goalSettingsLayout.isCompoundMode = true;
                                        // 计算复利目标
                                        recalculateMonthlyCompoundGoal();
                                        recalculateAnnualCompoundGoal();
                                    }
                                }
                            }
                        }
                    }
                    
                    // 添加属性跟踪当前模式
                    property bool isCompoundMode: false
                    
                    // 月度目标设置卡片 - 使用更现代的设计
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: monthlyGoalContent.implicitHeight + 30
                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.3) : Qt.rgba(0.97, 0.97, 1.0, 0.7)) : "#f5f5f5"
                        radius: 8
                        border.width: 1
                        border.color: theme ? (theme.isDarkTheme ? Qt.rgba(0.3, 0.3, 0.5, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 1.0)) : "#d0d0d0"
                        
                        ColumnLayout {
                            id: monthlyGoalContent
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            
                            // 标题行
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                // 图标
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: width/2
                                    color: theme ? Qt.alpha(theme.primaryColor, 0.7) : "#4CAF50"
                                
                                    Text {
                                        anchors.centerIn: parent
                                        text: "📅"
                                        font.pixelSize: 14
                                    }
                                }
                                
                                Text {
                                    text: "月度目标"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: theme ? (theme.isDarkTheme ? Qt.rgba(0.4, 0.4, 0.6, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 0.8)) : "#d0d0d0"
                                }
                                
                                // 开启/关闭切换
                                Rectangle {
                                    width: 50
                                    height: 24
                                    radius: height/2
                                    color: monthlyGoalSwitch.checked ? theme.primaryColor : 
                                           (theme.isDarkTheme ? "#2c3e50" : "#d0d0d0")
                                    
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: width/2
                                        color: "white"
                                        x: monthlyGoalSwitch.checked ? parent.width - width - 4 : 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Behavior on x {
                                            NumberAnimation { duration: 150 }
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: monthlyGoalSwitch
                                        anchors.fill: parent
                                        property bool checked: true
                                        onClicked: {
                                            checked = !checked;
                                            // TODO: Connect to backend
                                            if (backend) {
                                                backend.enableMonthlyGoal(checked);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 常规模式内容 - 条件显示
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                enabled: monthlyGoalSwitch.checked
                                opacity: monthlyGoalSwitch.checked ? 1.0 : 0.5
                                visible: !goalSettingsLayout.isCompoundMode // 只在常规模式下显示
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                // 月度目标金额
                                Text {
                                    text: "目标金额:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 10
                                
                                    Rectangle {
                                        Layout.preferredWidth: 180
                                        Layout.minimumWidth: 120
                                        height: inputHeight
                                        radius: inputRadius
                                        color: inputBgColor
                                        border.color: inputBorderColor
                                        border.width: 1
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 0
                                            
                                            Text {
                                                text: "¥"
                                                color: inputTextColor
                                                font.pixelSize: inputFontSize
                                            }
                                            
                                            TextInput {
                                                id: monthlyGoalInput
                                                Layout.fillWidth: true
                                                horizontalAlignment: TextInput.AlignRight
                                                color: inputTextColor
                                                font.pixelSize: inputFontSize
                                                selectByMouse: true
                                                validator: DoubleValidator {
                                                    bottom: 0.0
                                                    notation: DoubleValidator.StandardNotation
                                                    decimals: 2
                                                }
                                                text: "1000.00" // Default value - should connect to backend
                                                
                                                onEditingFinished: {
                                                    if (backend) {
                                                        backend.setMonthlyGoal(parseFloat(text) || 0);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 重置按钮
                                    CustomButton {
                                        text: "重置"
                                        implicitWidth: 70
                                        onClicked: {
                                            if (backend) {
                                                backend.resetMonthlyGoal();
                                                monthlyGoalInput.text = "0.00";
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 复利模式内容 - 条件显示
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                enabled: monthlyGoalSwitch.checked
                                opacity: monthlyGoalSwitch.checked ? 1.0 : 0.5
                                visible: goalSettingsLayout.isCompoundMode // 只在复利模式下显示
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                // 初始投资金额
                                Text {
                                    text: "初始投资:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 180
                                    height: inputHeight
                                    radius: inputRadius
                                    color: inputBgColor
                                    border.color: inputBorderColor
                                    border.width: 1
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 0
                                        
                                        Text {
                                            text: "¥"
                                            color: inputTextColor
                                            font.pixelSize: inputFontSize
                                        }
                                        
                                        TextInput {
                                            id: initialInvestmentInput
                                            Layout.fillWidth: true
                                            horizontalAlignment: TextInput.AlignRight
                                            color: inputTextColor
                                            font.pixelSize: inputFontSize
                                            selectByMouse: true
                                            validator: DoubleValidator {
                                                bottom: 0.0
                                                notation: DoubleValidator.StandardNotation
                                                decimals: 2
                                            }
                                            text: "10000.00"
                                            
                                            onEditingFinished: {
                                                recalculateMonthlyCompoundGoal();
                                            }
                                        }
                                    }
                                }
                                
                                // 月度收益率
                                Text {
                                    text: "月收益率:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 5
                                    
                                    CustomSpinBox {
                                        id: monthlyRateSpinBox
                                        from: 1
                                        to: 100
                                        value: 10
                                        Layout.preferredWidth: 100
                                        textFromValue: function(value) { return value.toString() }
                                        valueFromText: function(text) { return parseInt(text) }
                                        
                                        onSpinValueChanged: {
                                            recalculateMonthlyCompoundGoal();
                                        }
                                    }
                                    
                                    Text {
                                        text: "%"
                                        color: theme ? theme.textColor : "black"
                                        font.pixelSize: inputFontSize
                                    }
                                }
                                
                                // 计算出的目标
                                Text {
                                    text: "计算目标:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 10
                                    
                                    Text {
                                        id: calculatedGoalText
                                        text: "¥1000.00"
                                        font.bold: true
                                        color: profitColor
                                        font.pixelSize: inputFontSize
                                    }
                                    
                                    CustomButton {
                                        text: "应用"
                                        implicitWidth: 70
                                        implicitHeight: inputHeight
                                        highlighted: true
                                        
                                        onClicked: {
                                            var goalValue = parseFloat(calculatedGoalText.text.replace("¥", ""));
                                            monthlyGoalInput.text = goalValue.toFixed(2);
                                            if (backend) {
                                                backend.setMonthlyGoal(goalValue);
                                            }
                                        }
                                    }
                                }
                                
                                // 说明文本 - 跨两列
                                Text {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    text: "复利模式下,根据您的初始投资和期望月收益率计算目标金额。"
                                    font.pixelSize: 12
                                    color: Qt.darker(textColor, 1.2)
                                    wrapMode: Text.WordWrap
                                }
                            }
                            
                            // 当前进度 - 常规显示，不管是什么模式都显示
                            Text {
                                text: "当前进度:"
                                font.pixelSize: labelFontSize
                                color: theme ? theme.textColor : "black"
                                visible: monthlyGoalSwitch.checked
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: monthlyGoalSwitch.checked
                                
                                // 进度文字
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Text {
                                        id: currentMonthProfitText
                                        text: "¥" + ((backend ? backend.getCurrentMonthProfit() : 0) || 0).toFixed(2)
                                        font.pixelSize: labelFontSize
                                        font.bold: true
                                        color: (currentMonthProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                    }
                                    
                                    Text {
                                        text: " / ¥" + monthlyGoalInput.text
                                        font.pixelSize: labelFontSize
                                        color: theme ? theme.textColor : "black"
                                    }
                            
                                    Item { Layout.fillWidth: true }
                                    
                                    Text {
                                        text: currentMonthProgressText.text + "%"
                                        font.pixelSize: labelFontSize
                                        font.bold: true
                                        color: (currentMonthProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                    }
                                    
                                    Text {
                                        id: currentMonthProgressText
                                        visible: false // 仅用于计算
                                        text: {
                                            try {
                                                const profit = parseFloat(currentMonthProfitText.text.replace("¥", ""));
                                                const goal = parseFloat(monthlyGoalInput.text);
                                                if (goal <= 0) return "0";
                                                return Math.min(100, Math.max(0, profit / goal * 100)).toFixed(0);
                                            } catch (e) {
                                                return "0";
                                            }
                                        }
                                    }
                                }
                                
                                // 进度条
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.7) : Qt.rgba(0.9, 0.9, 0.9, 1.0)) : "#f0f0f0"
                                    
                                    Rectangle {
                                        width: Math.max(0, Math.min(parent.width, parent.width * parseInt(currentMonthProgressText.text) / 100))
                                        height: parent.height
                                        radius: 4
                                        color: (currentMonthProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }
                            
                            // 删除旧控件的标记，保持功能函数
                            function recalculateMonthlyCompoundGoal() {
                                try {
                                    var initialInvestment = parseFloat(initialInvestmentInput.text) || 10000.0;
                                    var monthlyRate = monthlyRateSpinBox.value / 100.0;
                                    
                                    // 计算月度目标 = 初始投资 * 月收益率
                                    var calculatedGoal = initialInvestment * monthlyRate;
                                    calculatedGoalText.text = "¥" + calculatedGoal.toFixed(2);
                                } catch (e) {
                                    console.error("计算复利目标失败: " + e);
                                }
                            }
                        }
                    }
                    
                    // 年度目标设置卡片 - 使用相同风格
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: yearlyGoalContent.implicitHeight + 30
                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.3) : Qt.rgba(0.97, 0.97, 1.0, 0.7)) : "#f5f5f5"
                        radius: 8
                        border.width: 1
                        border.color: theme ? (theme.isDarkTheme ? Qt.rgba(0.3, 0.3, 0.5, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 1.0)) : "#d0d0d0"
                        
                        ColumnLayout {
                            id: yearlyGoalContent
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            
                            // 标题行
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                // 图标
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: width/2
                                    color: theme ? Qt.alpha(theme.primaryColor, 0.7) : "#4CAF50"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "📊"
                                        font.pixelSize: 14
                                    }
                                }
                                        
                                Text {
                                    text: "年度目标"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: theme ? (theme.isDarkTheme ? Qt.rgba(0.4, 0.4, 0.6, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 0.8)) : "#d0d0d0"
                                }
                                
                                // 开启/关闭切换
                                Rectangle {
                                    width: 50
                                    height: 24
                                    radius: height/2
                                    color: yearlyGoalSwitch.checked ? theme.primaryColor : 
                                           (theme.isDarkTheme ? "#2c3e50" : "#d0d0d0")
                                    
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: width/2
                                        color: "white"
                                        x: yearlyGoalSwitch.checked ? parent.width - width - 4 : 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        Behavior on x {
                                            NumberAnimation { duration: 150 }
                                        }
                                    }
                                            
                                    MouseArea {
                                        id: yearlyGoalSwitch
                                        anchors.fill: parent
                                        property bool checked: true
                                        onClicked: {
                                            checked = !checked;
                                            // TODO: Connect to backend
                                            if (backend) {
                                                backend.enableAnnualGoal(checked);
                                            }
                                        }
                                    }
                                }
                            }
                                
                            // 常规模式内容 - 条件显示
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                enabled: yearlyGoalSwitch.checked
                                opacity: yearlyGoalSwitch.checked ? 1.0 : 0.5
                                visible: !goalSettingsLayout.isCompoundMode // 只在常规模式下显示
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                // 年度目标金额
                                Text {
                                    text: "目标金额:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 10
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 180
                                        Layout.minimumWidth: 120
                                        height: inputHeight
                                        radius: inputRadius
                                        color: inputBgColor
                                        border.color: inputBorderColor
                                        border.width: 1
                                
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 0
                                    
                                            Text {
                                                text: "¥"
                                                color: inputTextColor
                                                font.pixelSize: inputFontSize
                                            }
                                            
                                            TextInput {
                                                id: yearlyGoalInput
                                                Layout.fillWidth: true
                                                horizontalAlignment: TextInput.AlignRight
                                                color: inputTextColor
                                                font.pixelSize: inputFontSize
                                                selectByMouse: true
                                                validator: DoubleValidator {
                                                    bottom: 0.0
                                                    notation: DoubleValidator.StandardNotation
                                                    decimals: 2
                                                }
                                                text: "12000.00" // Default value - should connect to backend
                                                
                                                onEditingFinished: {
                                                    if (backend) {
                                                        backend.setAnnualGoal(parseFloat(text) || 0);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 重置按钮
                                    CustomButton {
                                        text: "重置"
                                        implicitWidth: 70
                                        onClicked: {
                                            if (backend) {
                                                backend.resetAnnualGoal();
                                                yearlyGoalInput.text = "0.00";
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // 复利模式内容 - 条件显示
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                enabled: yearlyGoalSwitch.checked
                                opacity: yearlyGoalSwitch.checked ? 1.0 : 0.5
                                visible: goalSettingsLayout.isCompoundMode // 只在复利模式下显示
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                // 初始投资金额
                                Text {
                                    text: "初始投资:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.preferredWidth: 180
                                    height: inputHeight
                                    radius: inputRadius
                                    color: inputBgColor
                                    border.color: inputBorderColor
                                    border.width: 1
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 0
                                        
                                        Text {
                                            text: "¥"
                                            color: inputTextColor
                                            font.pixelSize: inputFontSize
                                        }
                                        
                                        TextInput {
                                            id: yearlyInitialInvestmentInput
                                            Layout.fillWidth: true
                                            horizontalAlignment: TextInput.AlignRight
                                            color: inputTextColor
                                            font.pixelSize: inputFontSize
                                            selectByMouse: true
                                            validator: DoubleValidator {
                                                bottom: 0.0
                                                notation: DoubleValidator.StandardNotation
                                                decimals: 2
                                            }
                                            text: "10000.00"
                                            
                                            onEditingFinished: {
                                                recalculateAnnualCompoundGoal();
                                            }
                                        }
                                    }
                                }
                                
                                // 年收益率
                                Text {
                                    text: "年收益率:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 5
                                    
                                    CustomSpinBox {
                                        id: yearlyRateSpinBox
                                        from: 1
                                        to: 100
                                        value: 20
                                        Layout.preferredWidth: 100
                                        textFromValue: function(value) { return value.toString() }
                                        valueFromText: function(text) { return parseInt(text) }
                                        
                                        onSpinValueChanged: {
                                            recalculateAnnualCompoundGoal();
                                        }
                                    }
                                    
                                    Text {
                                        text: "%"
                                        color: theme ? theme.textColor : "black"
                                        font.pixelSize: inputFontSize
                                    }
                                }
                                
                                // 计算出的目标
                                Text {
                                    text: "计算目标:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 10
                                    
                                    Text {
                                        id: calculatedYearlyGoalText
                                        text: "¥2000.00"
                                        font.bold: true
                                        color: profitColor
                                        font.pixelSize: inputFontSize
                                    }
                                    
                                    CustomButton {
                                        text: "应用"
                                        implicitWidth: 70
                                        implicitHeight: inputHeight
                                        highlighted: true
                                        
                                        onClicked: {
                                            var goalValue = parseFloat(calculatedYearlyGoalText.text.replace("¥", ""));
                                            yearlyGoalInput.text = goalValue.toFixed(2);
                                            if (backend) {
                                                backend.setAnnualGoal(goalValue);
                                            }
                                        }
                                    }
                                }
                                
                                // 说明文本 - 跨两列
                                Text {
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    text: "复利模式下,根据您的初始投资和期望年收益率计算目标金额。"
                                    font.pixelSize: 12
                                    color: Qt.darker(textColor, 1.2)
                                    wrapMode: Text.WordWrap
                                }
                            }
                                
                            // 当前进度
                            Text {
                                text: "当前进度:"
                                font.pixelSize: labelFontSize
                                color: theme ? theme.textColor : "black"
                                visible: yearlyGoalSwitch.checked
                            }
                                
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: yearlyGoalSwitch.checked
                                
                                // 进度文字
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    
                                    Text {
                                        id: currentYearProfitText
                                        text: "¥" + ((backend ? backend.getCurrentYearProfit() : 0) || 0).toFixed(2)
                                        font.pixelSize: labelFontSize
                                        font.bold: true
                                        color: (currentYearProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                    }
                                    
                                    Text {
                                        text: " / ¥" + yearlyGoalInput.text
                                        font.pixelSize: labelFontSize
                                        color: theme ? theme.textColor : "black"
                                    }
                                
                                    Item { Layout.fillWidth: true }
                                
                                    Text {
                                        text: currentYearProgressText.text + "%"
                                        font.pixelSize: labelFontSize
                                        font.bold: true
                                        color: (currentYearProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                    }
                                    
                                    Text {
                                        id: currentYearProgressText
                                        visible: false // 仅用于计算
                                        text: {
                                            try {
                                                const profit = parseFloat(currentYearProfitText.text.replace("¥", ""));
                                                const goal = parseFloat(yearlyGoalInput.text);
                                                if (goal <= 0) return "0";
                                                return Math.min(100, Math.max(0, profit / goal * 100)).toFixed(0);
                                            } catch (e) {
                                                return "0";
                                            }
                                        }
                                    }
                                }
                                
                                // 进度条
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 8
                                    radius: 4
                                    color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.7) : Qt.rgba(0.9, 0.9, 0.9, 1.0)) : "#f0f0f0"
                                    
                                    Rectangle {
                                        width: Math.max(0, Math.min(parent.width, parent.width * parseInt(currentYearProgressText.text) / 100))
                                        height: parent.height
                                        radius: 4
                                        color: (currentYearProfitText.text.indexOf("-") === -1) ? profitColor : lossColor
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }
                            
                            // 添加年度复利计算函数
                            function recalculateAnnualCompoundGoal() {
                                try {
                                    var initialInvestment = parseFloat(yearlyInitialInvestmentInput.text) || 10000.0;
                                    var yearlyRate = yearlyRateSpinBox.value / 100.0;
                                    
                                    // 计算年度目标 = 初始投资 * 年收益率
                                    var calculatedGoal = initialInvestment * yearlyRate;
                                    calculatedYearlyGoalText.text = "¥" + calculatedGoal.toFixed(2);
                                } catch (e) {
                                    console.error("计算年度复利目标失败: " + e);
                                }
                            }
                        }
                    }
                }
            }

            // 软件更新
            Rectangle {
                id: updateCard // Ensure unique ID
                Layout.fillWidth: true
                implicitHeight: updateLayout.implicitHeight + 30
                color: cardColor
                radius: 5 // Keep original radius or update to 10 for consistency
                 // ... DropShadow if needed ...
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
                id: aboutCard // Ensure unique ID
                Layout.fillWidth: true
                implicitHeight: aboutLayout.implicitHeight + 30
                color: cardColor
                radius: 5 // Keep original radius or update to 10 for consistency
                // ... DropShadow if needed ...
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

            // 其他设置
            Rectangle {
                id: otherSettingsCard // Renamed to avoid conflict with layout id
                Layout.fillWidth: true
                implicitHeight: otherSettingsLayout.implicitHeight + 30
                color: cardColor
                radius: 10
                 // ... DropShadow ...
                ColumnLayout {
                    id: otherSettingsLayout // This ID seems to be used for the content
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 16

                    // 卡片标题
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Text {
                            text: "其他设置"
                            font.pixelSize: 16
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme ? Qt.alpha(theme.borderColor, 0.5) : "#e0e0e0"
                        }
                    }
                    
                    // 说明文本
                    Text {
                        text: "其他系统设置和高级选项"
                        font.pixelSize: 12
                        color: Qt.darker(textColor, 1.2)
                        opacity: 0.8
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    // 添加分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: inputBorderColor
                        opacity: 0.5
                        Layout.topMargin: 5
                        Layout.bottomMargin: 5
                    }

                    // 其他设置内容 - 使用更现代的设计
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: miscSettingsContent.implicitHeight + 30
                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.2, 0.25, 0.3) : Qt.rgba(0.97, 0.97, 1.0, 0.7)) : "#f5f5f5"
                        radius: 8
                        border.width: 1
                        border.color: theme ? (theme.isDarkTheme ? Qt.rgba(0.3, 0.3, 0.5, 0.5) : Qt.rgba(0.8, 0.8, 0.9, 1.0)) : "#d0d0d0"
                        
                        ColumnLayout {
                            id: miscSettingsContent
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15
                            
                            // 数据安全设置
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 15
                                columnSpacing: 15
                                
                                // 自动保存间隔
                                Text {
                                    text: "自动保存间隔:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                RowLayout {
                                    spacing: 10
                                    
                                    CustomSpinBox {
                                        id: autoSaveIntervalInput
                                        value: 5
                                        from: 1
                                        to: 60
                                        stepSize: 1
                                        
                                        onValueChanged: {
                                            if (backend) {
                                                backend.setAutoSaveInterval(value);
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        text: "分钟"
                                        font.pixelSize: labelFontSize - 2
                                        color: Qt.darker(theme.textColor, 1.2)
                                    }
                                }
                                
                                // 登录时加载上次数据
                                Text {
                                    text: "登录时加载上次数据:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                CustomCheckBox {
                                    id: loadLastDataCheck
                                    text: ""
                                    checked: true
                                    
                                    onCheckClicked: {
                                        if (backend) {
                                            backend.setLoadLastDataOnStartup(checked);
                                        }
                                    }
                                }
                                
                                // 自动检查更新
                                Text {
                                    text: "自动检查更新:"
                                    font.pixelSize: labelFontSize
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                CustomCheckBox {
                                    id: autoCheckUpdateCheck
                                    text: ""
                                    checked: true
                                    
                                    onCheckClicked: {
                                        if (backend) {
                                            backend.setAutoCheckUpdate(checked);
                                        }
                                    }
                                }
                            }
                            
                            // 高级选项
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Text {
                                    text: "高级选项"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: theme ? theme.textColor : "black"
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: theme ? Qt.alpha(theme.borderColor, 0.3) : "#e0e0e0"
                                }
                                
                                // 高级选项按钮组
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    
                                    CustomButton {
                                        text: "导出数据"
                                        implicitWidth: 100
                                        
                                        onClicked: {
                                            if (backend) {
                                                backend.exportData();
                                            }
                                        }
                                    }
                                    
                                    CustomButton {
                                        text: "导入数据"
                                        implicitWidth: 100
                                        
                                        onClicked: {
                                            if (backend) {
                                                backend.importData();
                                            }
                                        }
                                    }
                                    
                                    CustomButton {
                                        text: "清理缓存"
                                        implicitWidth: 100
                                        
                                        onClicked: {
                                            if (backend) {
                                                backend.clearCache();
                                            }
                                        }
                                    }
                                }
                                
                                // 数据重置按钮组
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Layout.topMargin: 5
                                    
                                    CustomButton {
                                        text: "重置所有设置"
                                        implicitWidth: 130
                                        bgColor: "#ff9800"
                                        
                                        onClicked: {
                                            confirmResetSettingsDialog.open();
                                        }
                                    }
                                    
                                    Item { Layout.fillWidth: true }
                                    
                                    CustomButton {
                                        text: "删除所有数据"
                                        implicitWidth: 130
                                        bgColor: "#f44336"
                                        
                                        onClicked: {
                                            confirmDeleteDataDialog.open();
                                        }
                                    }
                                }
                            }
                            
                            // 版本信息
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 10
                                
                                Text {
                                    text: "当前版本:"
                                    font.pixelSize: 12
                                    color: Qt.darker(theme.textColor, 1.1)
                                }
                                
                                Text {
                                    id: versionText
                                    text: backend ? backend.getVersion() : "1.0.0"
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Qt.darker(theme.textColor, 1.1)
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Text {
                                    text: "<a href='https://github.com/username/invest-ledger'>GitHub</a>"
                                    font.pixelSize: 12
                                    color: theme.linkColor
                                    linkColor: theme.linkColor
                                    onLinkActivated: Qt.openUrlExternally(link)
                                }
                                
                                Text {
                                    text: "|"
                                    font.pixelSize: 12
                                    color: Qt.darker(theme.textColor, 1.1)
                                }
                                
                                Text {
                                    text: "<a href='https://example.com/docs'>文档</a>"
                                    font.pixelSize: 12
                                    color: theme.linkColor
                                    linkColor: theme.linkColor
                                    onLinkActivated: Qt.openUrlExternally(link)
                                }
                            }
                        }
                    }
                }
            }

            Item { height: 30 } // Bottom spacing
        }

        // Custom Scrollbar, placed as a sibling to Flickable, anchored to the main Item (settingsView)
        Rectangle {
            id: customScrollbar
            width: flickableArea.contentHeight > flickableArea.height ? 8 : 0 // Only show if scrollable, adjust width
            radius: width / 2
            color: "transparent"
            z: 1000

            // Anchor to the parent (settingsView) edges, then use flickableArea for positioning
            anchors.top: parent.top // Anchors to settingsView.top
            anchors.topMargin: flickableArea.y // Position relative to flickableArea's top
            height: flickableArea.height       // Match flickableArea's height

            // Position it to the right of flickableArea
            x: flickableArea.x + flickableArea.width - width - 2 // 2 for margin
            
            // opacity: flickableArea.contentHeight > flickableArea.height ? 
            //         (scrollbarMouseArea.containsMouse || scrollbarMouseArea.pressed ? 1.0 : 0.7) : 0.0
            // visible: opacity > 0


            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            // Behavior on width { // Animate width change for appearing/disappearing
            //     NumberAnimation { duration: 200 }
            // }

            // Ensure opacity and visible are correctly set based on original logic
            opacity: flickableArea.contentHeight > flickableArea.height ?
                    (scrollbarMouseArea.containsMouse || scrollbarMouseArea.pressed ? 1.0 : 0.7) : 0.0
            visible: opacity > 0


            Rectangle {
                // Scrollbar track background
                anchors.fill: parent
                color: theme ? (theme.isDarkTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)) : Qt.rgba(0, 0, 0, 0.08)
                radius: parent.radius
            }

            Rectangle {
                // Scrollbar handle
                id: scrollHandle
                width: parent.width
                radius: width / 2
                color: scrollbarMouseArea.pressed ? 
                       Qt.darker(theme ? theme.primaryColor : "#4CAF50", 1.2) : 
                       (theme ? theme.primaryColor : "#4CAF50")
                opacity: scrollbarMouseArea.containsMouse ? 0.9 : 0.7
                
                height: Math.max(30, flickableArea.height * (flickableArea.height / Math.max(1, flickableArea.contentHeight)))
                y: (flickableArea.height - height) * (flickableArea.contentY / Math.max(1, flickableArea.contentHeight - flickableArea.height))
                
                Behavior on y { enabled: !scrollbarMouseArea.pressed; NumberAnimation { duration: 50; easing.type: Easing.OutQuad } }
                Behavior on height { NumberAnimation { duration: 150 } }
            }
            
            MouseArea {
                id: scrollbarMouseArea
                anchors.fill: parent
                anchors.leftMargin: -parent.width // Make it easier to grab
                anchors.rightMargin: -parent.width / 2
                hoverEnabled: true
                preventStealing: true // Try to prevent Flickable from stealing events

                property real dragStartContentY: 0
                property real dragStartMouseY: 0
                
                onPressed: (mouse) => {
                    dragStartMouseY = mouse.y;
                    dragStartContentY = flickableArea.contentY;
                    mouse.accepted = true; // Accept the event
                }
                
                onMouseYChanged: (mouse) => { // Changed from onPositionChanged to be more specific
                    if (pressed) {
                        var scrollableHeight = flickableArea.contentHeight - flickableArea.height;
                        if (scrollableHeight <= 0) return;

                        var handleVisibleRatio = scrollHandle.height / customScrollbar.height;
                        var scrollbarEffectiveHeight = customScrollbar.height * (1 - handleVisibleRatio); // The range the top of the handle can travel
                        if (scrollbarEffectiveHeight <=0) return;
                        
                        var dy = mouse.y - dragStartMouseY;
                        var contentDelta = (dy / scrollbarEffectiveHeight) * scrollableHeight; 
                        flickableArea.contentY = Math.max(0, Math.min(scrollableHeight, dragStartContentY + contentDelta));
                        mouse.accepted = true;
                    }
                }
                
                onReleased: (mouse) => {
                     mouse.accepted = true; // Ensure event is consumed
                }

                onWheel: (wheel) => {
                    var newContentY = flickableArea.contentY - (wheel.angleDelta.y / 120 * 40); // Standard scroll speed
                    var scrollableHeight = flickableArea.contentHeight - flickableArea.height;
                    flickableArea.contentY = Math.max(0, Math.min(scrollableHeight, newContentY));
                    wheel.accepted = true;
                }
            }
        }

        // 添加Toast通知组件
        Toast {
            id: settingsToast
        }
        
        // 添加回到顶部按钮
        Rectangle {
            id: backToTopButton
            width: 50
            height: 50
            radius: width/2
            color: theme ? theme.primaryColor : "#3498db"
            opacity: flickableArea.contentY > 500 ? 1.0 : 0.0 // 当滚动超过500时显示
            visible: opacity > 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            anchors.bottomMargin: 20
            z: 100
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            
            Text {
                anchors.centerIn: parent
                text: "↑"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    flickableArea.contentY = 0;
                }
            }
        }
    }

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
            width: parent.width // Make ColumnLayout take the Dialog's content area width
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
        width: 300 // <--- 添加一个明确的宽度

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