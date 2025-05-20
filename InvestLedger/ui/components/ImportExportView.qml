import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects

Item {
    id: importExportView
    
    // 主题属性，由main.qml传入
    property var theme
    
    // 控件样式属性
    property int buttonHeight: 36
    property int buttonWidth: 120
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
    
    // 当前选中的导入/导出标签
    property int currentTabIndex: 0 // 0: 导入, 1: 导出
    
    // 提供文件导入功能，包括选择文件、选择分隔符等
    function importFromFile() {
        fileDialog.open();
    }
    
    // 提供文本粘贴导入功能
    function importFromText() {
        pasteImportDialog.open();
    }
    
    // 导出数据到文件
    function exportToFile() {
        saveFileDialog.open();
    }
    
    // 自定义按钮组件
    component CustomButton: Rectangle {
        id: customBtn
        property string text: "按钮"
        property bool highlighted: false
        property bool isPressed: false
        property string iconSource: ""
        signal clicked()

        width: buttonWidth
        height: buttonHeight
        radius: buttonRadius
        color: highlighted ? buttonBgColor : (theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0")
        border.color: highlighted ? buttonBorderColor : inputBorderColor
        border.width: 1
        
        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            
            Image {
                source: iconSource
                width: 16
                height: 16
                visible: iconSource !== ""
                sourceSize.width: 16
                sourceSize.height: 16
                Layout.alignment: Qt.AlignVCenter
            }
            
            Text {
                text: parent.parent.text
                font.family: buttonFontFamily
                font.pixelSize: buttonFontSize
                color: highlighted ? buttonTextColor : (theme ? (theme.isDarkTheme ? "white" : "#333333") : "#333333")
            }
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
    
    // 整个页面使用一个简单的列布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // 标题
        Text {
            text: "数据导入导出"
            font.pixelSize: 24
            font.bold: true
            color: theme ? theme.textColor : "black"
        }
        
        // 导入/导出选项卡
        Row {
            spacing: 10
            Layout.fillWidth: true
            
            // 导入选项卡按钮
            Rectangle {
                width: 120
                height: 40
                color: currentTabIndex === 0 ? buttonBgColor : "transparent"
                border.color: inputBorderColor
                border.width: 1
                radius: buttonRadius
                
                Text {
                    anchors.centerIn: parent
                    text: "导入"
                    color: currentTabIndex === 0 ? "white" : (theme ? theme.textColor : "black")
                    font.pixelSize: buttonFontSize
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: currentTabIndex = 0
                }
            }
            
            // 导出选项卡按钮
            Rectangle {
                width: 120
                height: 40
                color: currentTabIndex === 1 ? buttonBgColor : "transparent"
                border.color: inputBorderColor
                border.width: 1
                radius: buttonRadius
                
                Text {
                    anchors.centerIn: parent
                    text: "导出"
                    color: currentTabIndex === 1 ? "white" : (theme ? theme.textColor : "black")
                    font.pixelSize: buttonFontSize
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: currentTabIndex = 1
                }
            }
        }
        
        // 内容区
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            // 导入内容
            Column {
                anchors.fill: parent
                spacing: 20
                visible: currentTabIndex === 0
                
                // 选择导入方式标题
                Text {
                    text: "选择导入方式"
                    font.pixelSize: 16
                    font.bold: true
                    color: theme ? theme.textColor : "black"
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                }
                
                // 导入选项区域
                Row {
                    width: parent.width
                    spacing: 20
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // 文件导入卡片
                    Rectangle {
                        width: (parent.width - 20) / 2
                        height: 140
                        color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                        border.color: inputBorderColor
                        border.width: 1
                        radius: 5
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            width: parent.width - 20
                            
                            Text {
                                text: "文件导入"
                                font.pixelSize: 16
                                color: theme ? theme.textColor : "black"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "支持CSV/TSV/Excel/TXT格式文件"
                                font.pixelSize: 12
                                color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Rectangle {
                                width: 120
                                height: 36
                                radius: 4
                                color: buttonBgColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "选择文件"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: importFromFile()
                                    hoverEnabled: true
                                    onEntered: parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                }
                            }
                        }
                    }
                    
                    // 粘贴导入卡片
                    Rectangle {
                        width: (parent.width - 20) / 2
                        height: 140
                        color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                        border.color: inputBorderColor
                        border.width: 1
                        radius: 5
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            width: parent.width - 20
                            
                            Text {
                                text: "粘贴导入"
                                font.pixelSize: 16
                                color: theme ? theme.textColor : "black"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "从剪贴板粘贴文本数据"
                                font.pixelSize: 12
                                color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Rectangle {
                                width: 120
                                height: 36
                                radius: 4
                                color: buttonBgColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "粘贴文本"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: importFromText()
                                    hoverEnabled: true
                                    onEntered: parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                }
                            }
                        }
                    }
                }
                
                // 导入格式说明卡片
                Rectangle {
                    width: parent.width
                    height: 220
                    color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                    border.color: inputBorderColor
                    border.width: 1
                    radius: 5
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "支持的导入格式"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Text {
                            width: parent.width
                            text: "1. CSV/TSV/Excel文件：日期、资产类别、项目名称、数量、单价、币种、备注"
                            font.pixelSize: 12
                            color: theme ? theme.textColor : "black"
                            wrapMode: Text.WordWrap
                        }
                        
                        Text {
                            width: parent.width
                            text: "2. 自定义文本格式："
                            font.pixelSize: 12
                            color: theme ? theme.textColor : "black"
                            wrapMode: Text.WordWrap
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 60
                            color: theme ? (theme.isDarkTheme ? "#2c3e50" : "#f0f0f0") : "#f0f0f0"
                            radius: 3
                            
                            Text {
                                anchors.fill: parent
                                anchors.margins: 5
                                text: "若羽臣：盈310元， 2025年4月10日\n正海磁材：亏212元， 2025年4月14日"
                                font.pixelSize: 12
                                font.family: "Courier"
                                color: theme ? theme.textColor : "black"
                            }
                        }
                        
                        Text {
                            width: parent.width
                            text: "规则：项目名称在冒号前；盈/亏表示收益或亏损；逗号后为日期"
                            font.pixelSize: 12
                            color: theme ? theme.textColor : "black"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
            
            // 导出内容
            Column {
                anchors.fill: parent
                spacing: 20
                visible: currentTabIndex === 1
                
                // 导出选项标题
                Text {
                    text: "数据导出"
                    font.pixelSize: 16
                    font.bold: true
                    color: theme ? theme.textColor : "black"
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                }
                
                // 导出功能卡片
                Rectangle {
                    width: parent.width
                    height: 180
                    color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                    border.color: inputBorderColor
                    border.width: 1
                    radius: 5
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 15
                        width: parent.width - 40
                        
                        Text {
                            text: "导出所有交易数据"
                            font.pixelSize: 16
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Rectangle {
                                width: 120
                                height: 36
                                radius: 4
                                color: buttonBgColor
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "导出CSV"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: exportToFile()
                                    hoverEnabled: true
                                    onEntered: parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                }
                            }
                            
                            Rectangle {
                                width: 120
                                height: 36
                                radius: 4
                                color: buttonBgColor
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "导出Excel"
                                    color: "white"
                                    font.pixelSize: 14
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: exportToFile()
                                    hoverEnabled: true
                                    onEntered: parent.opacity = 0.8
                                    onExited: parent.opacity = 1.0
                                }
                            }
                        }
                        
                        Text {
                            text: "导出的文件将包含所有交易记录和相关统计信息"
                            font.pixelSize: 12
                            color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // 导出历史卡片
                Rectangle {
                    width: parent.width
                    height: 120
                    color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                    border.color: inputBorderColor
                    border.width: 1
                    radius: 5
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "最近导出记录"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Text {
                            text: "暂无导出记录"
                            font.pixelSize: 12
                            font.italic: true
                            color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                        }
                    }
                }
            }
        }
    }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: "选择导入文件"
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        fileMode: FileDialog.OpenFile
        nameFilters: ["CSV文件 (*.csv)", "TSV文件 (*.tsv)", "Excel文件 (*.xlsx *.xls)", "文本文件 (*.txt)", "所有文件 (*)"]
        
        onAccepted: {
            // 打开文件导入配置对话框
            fileImportDialog.filePath = selectedFile.toString();
            fileImportDialog.detectFileType(selectedFile.toString());
            fileImportDialog.open();
        }
    }
    
    // 保存文件对话框
    FileDialog {
        id: saveFileDialog
        title: "保存导出文件"
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV文件 (*.csv)", "Excel文件 (*.xlsx)", "所有文件 (*)"]
        
        onAccepted: {
            // 调用后端保存文件
            var success = backend.exportData(selectedFile.toString());
            if (success) {
                exportSuccessDialog.open();
            } else {
                errorDialog.showError("导出数据失败，请重试。");
            }
        }
    }
    
    // 文件导入配置对话框
    Dialog {
        id: fileImportDialog
        title: "导入配置"
        width: 500
        height: 400
        anchors.centerIn: parent
        modal: true
        
        property string filePath: ""
        property string separator: ","
        property int headerRow: 0
        property var columnMapping: ({})
        property string fileType: "" // 存储文件类型：csv, tsv, excel, txt
        
        // 根据文件扩展名设置初始文件类型和分隔符
        function detectFileType(path) {
            if (path.toLowerCase().endsWith(".csv")) {
                fileType = "csv";
                separator = ",";
            } else if (path.toLowerCase().endsWith(".tsv")) {
                fileType = "tsv";
                separator = "\t";
            } else if (path.toLowerCase().endsWith(".xlsx") || path.toLowerCase().endsWith(".xls")) {
                fileType = "excel";
                separator = ","; // Excel默认导出为CSV时通常用逗号
            } else if (path.toLowerCase().endsWith(".txt")) {
                fileType = "txt";
                separator = "\t"; // 文本文件通常用tab作为分隔符
            } else {
                fileType = "unknown";
                separator = ",";
            }
        }
        
        background: Rectangle {
            color: theme ? theme.cardColor : "white"
            radius: 5
            border.color: inputBorderColor
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            spacing: 15
            anchors.margins: 20
            
            Text {
                text: "文件："+ fileImportDialog.filePath
                font.pixelSize: 14
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                color: theme ? theme.textColor : "black"
            }
            
            // 文件类型显示
            RowLayout {
                Text {
                    text: "文件类型："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Text {
                    text: {
                        switch(fileImportDialog.fileType) {
                            case "csv": return "CSV (逗号分隔值)";
                            case "tsv": return "TSV (制表符分隔值)";
                            case "excel": return "Excel 电子表格";
                            case "txt": return "文本文件";
                            default: return "未识别格式";
                        }
                    }
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                    font.italic: true
                }
            }
            
            // 分隔符选择
            RowLayout {
                Text {
                    text: "分隔符："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Rectangle {
                    width: 100
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 5
                        verticalAlignment: TextInput.AlignVCenter
                        text: fileImportDialog.separator
                        color: inputTextColor
                        selectByMouse: true
                        onTextChanged: fileImportDialog.separator = text
                    }
                }
                
                // 常用分隔符快捷按钮
                Text {
                    text: "常用："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                CustomButton {
                    text: "逗号"
                    onClicked: fileImportDialog.separator = ","
                }
                
                CustomButton {
                    text: "制表符"
                    onClicked: fileImportDialog.separator = "\t"
                }
            }
            
            // 表头行设置
            RowLayout {
                Text {
                    text: "表头行："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Rectangle {
                    width: 60
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 5
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        text: fileImportDialog.headerRow.toString()
                        color: inputTextColor
                        selectByMouse: true
                        validator: IntValidator { bottom: 0; top: 10 }
                        onTextChanged: fileImportDialog.headerRow = parseInt(text)
                    }
                }
            }
            
            // 预览区域
            Text {
                text: "文件预览："
                font.pixelSize: 14
                font.bold: true
                color: theme ? theme.textColor : "black"
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: inputBgColor
                border.color: inputBorderColor
                border.width: 1
                radius: inputRadius
                
                // 文件预览内容将在这里显示
                Text {
                    anchors.centerIn: parent
                    text: "加载预览..."
                    font.pixelSize: 14
                    color: inputTextColor
                }
            }
            
            // 确认按钮
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                CustomButton {
                    text: "取消"
                    onClicked: fileImportDialog.close()
                }
                
                CustomButton {
                    text: "导入"
                    highlighted: true
                    onClicked: {
                        // 执行实际导入
                        var success = backend.importFromFile(
                            fileImportDialog.filePath, 
                            fileImportDialog.separator,
                            fileImportDialog.headerRow,
                            fileImportDialog.columnMapping,
                            fileImportDialog.fileType // 传递文件类型给后端
                        );
                        
                        fileImportDialog.close();
                        
                        if (success) {
                            importSuccessDialog.open();
                        } else {
                            errorDialog.showError("导入失败，请检查文件格式。");
                        }
                    }
                }
            }
        }
    }
    
    // 粘贴导入对话框
    Dialog {
        id: pasteImportDialog
        title: "粘贴导入"
        width: 500
        height: 400
        anchors.centerIn: parent
        modal: true
        
        background: Rectangle {
            color: theme ? theme.cardColor : "white"
            radius: 5
            border.color: inputBorderColor
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            spacing: 15
            anchors.margins: 20
            
            Text {
                text: "粘贴文本数据："
                font.pixelSize: 14
                font.bold: true
                color: theme ? theme.textColor : "black"
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: inputBgColor
                border.color: inputBorderColor
                border.width: 1
                radius: inputRadius
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    
                    TextArea {
                        id: pasteTextArea
                        wrapMode: TextEdit.WordWrap
                        selectByMouse: true
                        color: inputTextColor
                        placeholderText: "在此粘贴文本数据..."
                        
                        // 支持两种格式：
                        // 1. CSV格式数据
                        // 2. 自定义格式：项目名称：盈/亏金额， 日期
                    }
                }
            }
            
            // 导入格式选择
            RowLayout {
                Text {
                    text: "数据格式："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Rectangle {
                    width: 200
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    // 格式选择下拉框
                    Text {
                        id: formatText
                        property int formatIndex: 0 // 0: 自动识别, 1: CSV, 2: 自定义格式
                        property var formatTexts: ["自动识别", "CSV/TSV格式", "自定义格式"]
                        
                        anchors.fill: parent
                        anchors.margins: 10
                        verticalAlignment: Text.AlignVCenter
                        text: formatTexts[formatIndex]
                        color: inputTextColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: formatMenu.open()
                    }
                    
                    Menu {
                        id: formatMenu
                        y: parent.height
                        
                        MenuItem {
                            text: "自动识别"
                            onTriggered: formatText.formatIndex = 0
                        }
                        
                        MenuItem {
                            text: "CSV/TSV格式"
                            onTriggered: formatText.formatIndex = 1
                        }
                        
                        MenuItem {
                            text: "自定义格式"
                            onTriggered: formatText.formatIndex = 2
                        }
                    }
                }
            }
            
            Text {
                text: "系统将自动解析数据并识别格式。自定义格式示例：\n若羽臣：盈310元， 2025年4月10日"
                font.pixelSize: 12
                color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            // 确认按钮
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                CustomButton {
                    text: "取消"
                    onClicked: pasteImportDialog.close()
                }
                
                CustomButton {
                    text: "导入"
                    highlighted: true
                    onClicked: {
                        // 执行文本导入
                        var success = backend.importFromText(
                            pasteTextArea.text,
                            formatText.formatIndex
                        );
                        
                        pasteImportDialog.close();
                        
                        if (success) {
                            importSuccessDialog.open();
                        } else {
                            errorDialog.showError("导入失败，请检查文本格式。");
                        }
                    }
                }
            }
        }
    }
    
    // 导入成功对话框
    Dialog {
        id: importSuccessDialog
        title: "导入成功"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: "数据导入成功！"
            wrapMode: Text.WordWrap
        }
    }
    
    // 导出成功对话框
    Dialog {
        id: exportSuccessDialog
        title: "导出成功"
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: "数据导出成功！"
            wrapMode: Text.WordWrap
        }
    }
    
    // 错误对话框
    Dialog {
        id: errorDialog
        title: "错误"
        standardButtons: Dialog.Ok
        modal: true
        
        function showError(message) {
            errorText.text = message;
            open();
        }
        
        contentItem: Text {
            id: errorText
            wrapMode: Text.WordWrap
        }
    }
} 
} 