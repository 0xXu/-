import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform  // 添加对Platform的引用，用于StandardPaths
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
    property int currentTabIndex: 2 // 0: 导入, 1: 导出, 2: 手动录入 (默认显示手动录入)
    
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
    
    // 打开手动录入对话框
    function manualEntryTransaction() {
        manualEntryDialog.open();
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
            
            // 手动录入选项卡按钮
            Rectangle {
                width: 120
                height: 40
                color: currentTabIndex === 2 ? buttonBgColor : "transparent"
                border.color: inputBorderColor
                border.width: 1
                radius: buttonRadius
                
                Text {
                    anchors.centerIn: parent
                    text: "手动录入"
                    color: currentTabIndex === 2 ? "white" : (theme ? theme.textColor : "black")
                    font.pixelSize: buttonFontSize
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: currentTabIndex = 2
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
            
            // 手动录入内容
            Column {
                anchors.fill: parent
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                spacing: 20
                visible: currentTabIndex === 2
                clip: true  // 防止内容溢出
                
                // 手动录入标题
                Text {
                    text: "手动录入交易"
                    font.pixelSize: 16
                    font.bold: true
                    color: theme ? theme.textColor : "black"
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                }
                
                // 手动录入卡片 - 调整高度以适应内容
                Rectangle {
                    width: parent.width
                    height: 150 // 减小高度
                    color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                    border.color: inputBorderColor
                    border.width: 1
                    radius: 5
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 15
                        width: parent.width - 40
                        
                        Text {
                            text: "直接录入交易数据"
                            font.pixelSize: 16
                            color: theme ? theme.textColor : "black"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "填写交易表单，一次录入一条交易记录"
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
                                text: "新增交易"
                                color: "white"
                                font.pixelSize: 14
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: manualEntryTransaction()
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.8
                                onExited: parent.opacity = 1.0
                            }
                        }
                    }
                }
                
                // 快捷键提示
                Rectangle {
                    width: parent.width
                    height: 50
                    color: theme ? (theme.isDarkTheme ? Qt.rgba(0.1, 0.1, 0.2, 0.2) : Qt.rgba(0.95, 0.95, 1.0, 0.5)) : "#f5f5f5"
                    border.color: theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0"
                    border.width: 1
                    radius: 3
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        
                        Text {
                            text: "💡"
                            font.pixelSize: 18
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: "提示: 可以使用快捷键 Ctrl+N 快速打开新增交易对话框"
                            font.pixelSize: 12
                            color: theme ? theme.textColor : "black"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                
                // 最近录入记录
                Rectangle {
                    width: parent.width
                    height: 200
                    color: theme ? (theme.isDarkTheme ? Qt.darker(theme.cardColor, 1.1) : Qt.lighter(theme.cardColor, 1.1)) : "#f9f9f9"
                    border.color: inputBorderColor
                    border.width: 1
                    radius: 5
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "最近录入记录"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: inputBorderColor
                        }
                        
                        // 这里可以添加ListView来显示最近的交易记录
                        Text {
                            text: "暂无最近录入记录"
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
        currentFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
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
        currentFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
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
        property var previewData: null // 存储预览数据
        
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
            
            // 加载文件预览
            loadPreview();
        }
        
        function loadPreview() {
            // 调用后端生成预览
            var previewResult = backend.generateFilePreview(filePath, fileType, separator, 10);
            try {
                previewData = JSON.parse(previewResult);
            } catch (e) {
                previewData = { success: false, error: "预览生成失败" };
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
            
            // 分隔符选择 (仅对CSV/TSV有效)
            RowLayout {
                visible: fileImportDialog.fileType === "csv" || fileImportDialog.fileType === "tsv"
                
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
                        onTextChanged: {
                            fileImportDialog.separator = text;
                            // 重新加载预览
                            fileImportDialog.loadPreview();
                        }
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
                    onClicked: {
                        fileImportDialog.separator = ",";
                        fileImportDialog.loadPreview();
                    }
                }
                
                CustomButton {
                    text: "制表符"
                    onClicked: {
                        fileImportDialog.separator = "\t";
                        fileImportDialog.loadPreview();
                    }
                }
            }
            
            // 表头行设置
            RowLayout {
                visible: fileImportDialog.fileType !== "txt" // 对TXT文件无效
                
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
                        onTextChanged: {
                            fileImportDialog.headerRow = parseInt(text);
                            // 重新加载预览
                            fileImportDialog.loadPreview();
                        }
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
                clip: true
                
                // 文件预览内容
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 5
                    contentWidth: previewTable.width
                    contentHeight: previewTable.height
                    ScrollBar.vertical: ScrollBar {}
                    ScrollBar.horizontal: ScrollBar {}
                    
                    // 预览内容为表格形式
                    Column {
                        id: previewTable
                        width: parent.width
                        spacing: 2
                        
                        // 预览表头
                        Row {
                            id: tableHeader
                            spacing: 2
                            visible: fileImportDialog.previewData && fileImportDialog.previewData.success
                            
                            // 动态创建表头列
                            Component.onCompleted: {
                                if (fileImportDialog.previewData && fileImportDialog.previewData.success) {
                                    const headers = fileImportDialog.previewData.headers || [];
                                    for (let i = 0; i < headers.length; i++) {
                                        const headerComp = Qt.createComponent("PreviewHeaderCell.qml");
                                        if (headerComp.status === Component.Ready) {
                                            const headerObj = headerComp.createObject(tableHeader, {
                                                text: headers[i],
                                                width: Math.min(150, parent.width / headers.length)
                                            });
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 预览数据行
                        Repeater {
                            model: fileImportDialog.previewData && fileImportDialog.previewData.success ? 
                                   fileImportDialog.previewData.rows.length : 0
                            
                            Row {
                                spacing: 2
                                
                                // 创建每一行中的单元格
                                Component.onCompleted: {
                                    const rowData = fileImportDialog.previewData.rows[index];
                                    for (let i = 0; i < rowData.length; i++) {
                                        const cellComp = Qt.createComponent("PreviewCell.qml");
                                        if (cellComp.status === Component.Ready) {
                                            const cellObj = cellComp.createObject(this, {
                                                text: rowData[i] !== null ? String(rowData[i]) : "",
                                                width: Math.min(150, tableHeader.width / rowData.length)
                                            });
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 无预览或错误消息
                        Text {
                            visible: !fileImportDialog.previewData || !fileImportDialog.previewData.success
                            text: fileImportDialog.previewData ? 
                                  (fileImportDialog.previewData.error || "加载预览中...") : 
                                  "加载预览中..."
                            color: theme ? (theme.isDarkTheme ? "#e74c3c" : "#c0392b") : "#c0392b"
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }
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
                            fileImportDialog.headerRow,
                            fileImportDialog.fileType // 传递文件类型给后端
                        );
                        
                        fileImportDialog.close();
                        
                        if (success && success.success) {
                            importSuccessDialog.successCount = success.success_count;
                            importSuccessDialog.errorCount = success.error_count;
                            importSuccessDialog.errorDetails = success.errors || [];
                            importSuccessDialog.open();
                        } else {
                            errorDialog.showError(success.message || "导入失败，请检查文件格式。");
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
        width: 550
        height: 450
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
            
            // 标题区域
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "粘贴文本数据"
                    font.pixelSize: 16
                    font.bold: true
                    color: theme ? theme.textColor : "black"
                }
                
                Item {
                    Layout.fillWidth: true
                }
                
                Text {
                    text: "从剪贴板粘贴数据，支持多种格式"
                    font.pixelSize: 12
                    color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                }
            }
            
            // 文本输入区域
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
                        font.pixelSize: 14
                        
                        // 添加等宽字体以便更好地显示表格数据
                        font.family: "Consolas, Courier New, monospace"
                        
                        // 键盘快捷键
                        Keys.onPressed: function(event) {
                            if ((event.key === Qt.Key_V) && (event.modifiers & Qt.ControlModifier)) {
                                paste();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
            
            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: inputBorderColor
            }
            
            // 导入格式选择
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 15
                
                Text {
                    text: "数据格式："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    // 格式选择下拉框
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5
                        
                        Text {
                            id: formatText
                            property int formatIndex: 0 // 0: 自动识别, 1: CSV, 2: 自定义格式
                            property var formatTexts: ["自动识别", "CSV/TSV格式", "自定义格式"]
                            
                            Layout.fillWidth: true
                            text: formatTexts[formatIndex]
                            color: inputTextColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        Text {
                            text: "▼"
                            font.pixelSize: 10
                            color: inputTextColor
                            opacity: 0.7
                        }
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
                
                // 自动识别说明
                Text {
                    text: "格式说明："
                    font.pixelSize: 14
                    color: theme ? theme.textColor : "black"
                }
                
                Text {
                    text: formatText.formatIndex === 0 ? "系统自动检测文本格式" : 
                          formatText.formatIndex === 1 ? "CSV/TSV: 日期,资产类别,项目名称,数量,单价,币种,盈亏,备注" :
                          "自定义格式: 项目名称：盈/亏XXX元，日期"
                    font.pixelSize: 12
                    color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                
                // 按钮区
                Item {
                    // 占位符
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    layoutDirection: Qt.RightToLeft
                    
                    CustomButton {
                        text: "导入"
                        highlighted: true
                        Layout.preferredWidth: 100
                        onClicked: {
                            // 如果文本为空，显示提示
                            if (pasteTextArea.text.trim() === "") {
                                errorDialog.showError("请先粘贴要导入的数据");
                                return;
                            }
                            
                            // 执行文本导入
                            var success = backend.importFromText(
                                pasteTextArea.text,
                                formatText.formatIndex
                            );
                            
                            pasteImportDialog.close();
                            
                            if (success && success.success) {
                                importSuccessDialog.successCount = success.success_count;
                                importSuccessDialog.errorCount = success.error_count;
                                importSuccessDialog.errorDetails = success.errors || [];
                                importSuccessDialog.open();
                            } else {
                                errorDialog.showError(success.message || "导入失败，请检查文本格式。");
                            }
                        }
                    }
                    
                    CustomButton {
                        text: "取消"
                        Layout.preferredWidth: 100
                        onClicked: pasteImportDialog.close()
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    CustomButton {
                        text: "清空"
                        Layout.preferredWidth: 80
                        onClicked: pasteTextArea.clear()
                    }
                    
                    CustomButton {
                        text: "粘贴"
                        Layout.preferredWidth: 80
                        onClicked: pasteTextArea.paste()
                    }
                }
            }
            
            // 示例说明
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: theme ? (theme.isDarkTheme ? Qt.rgba(0.1, 0.1, 0.2, 0.2) : Qt.rgba(0.95, 0.95, 1.0, 0.5)) : "#f5f5f5"
                border.color: theme ? (theme.isDarkTheme ? "#34495e" : "#e0e0e0") : "#e0e0e0"
                border.width: 1
                radius: 3
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10
                    
                    Text {
                        text: "💡"
                        font.pixelSize: 18
                        color: theme ? theme.textColor : "black"
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: "自定义格式示例：若羽臣：盈310元，2025年4月10日\n导入时将自动去除多余空格"
                        font.pixelSize: 12
                        color: theme ? theme.textColor : "black"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
    
    // 导入成功对话框
    Dialog {
        id: importSuccessDialog
        title: "导入结果"
        modal: true
        width: 550 // 进一步增加宽度
        height: Math.min(importSuccessDialog.errorCount > 0 ? 500 : 300, parent.height * 0.8) // 动态高度
        standardButtons: Dialog.Ok
        anchors.centerIn: parent
        
        property int successCount: 0
        property int errorCount: 0
        property var errorDetails: []
        
        contentItem: ColumnLayout {
            spacing: 15
            
            // 导入结果摘要
            Rectangle {
                Layout.fillWidth: true
                color: importSuccessDialog.successCount > 0 ? 
                       (theme ? (theme.isDarkTheme ? "#1e462e" : "#e8f5e9") : "#e8f5e9") : 
                       (theme ? (theme.isDarkTheme ? "#4a2020" : "#ffebee") : "#ffebee")
                border.width: 1
                border.color: importSuccessDialog.successCount > 0 ?
                             (theme ? (theme.isDarkTheme ? "#2e7d32" : "#a5d6a7") : "#a5d6a7") : 
                             (theme ? (theme.isDarkTheme ? "#c62828" : "#ffcdd2") : "#ffcdd2")
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    // 成功/失败图标
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: importSuccessDialog.successCount > 0 ? 
                               (importSuccessDialog.errorCount === 0 ? "#4caf50" : "#ff9800") :
                               "#f44336"
                        
                        Text {
                            anchors.centerIn: parent
                            text: importSuccessDialog.successCount > 0 ? 
                                  (importSuccessDialog.errorCount === 0 ? "✓" : "!") :
                                  "✗"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                    
                    Column {
                        spacing: 5
                        Layout.fillWidth: true
                        
                        Text {
                            text: importSuccessDialog.successCount > 0 ? 
                                  (importSuccessDialog.errorCount === 0 ? "导入成功" : "部分导入成功") :
                                  "导入失败"
                            font.pixelSize: 18
                            font.bold: true
                            color: theme ? theme.textColor : "black"
                        }
                        
                        Text {
                            text: "成功导入: " + importSuccessDialog.successCount + " 条记录" + 
                                  (importSuccessDialog.errorCount > 0 ? "，失败: " + importSuccessDialog.errorCount + " 条记录" : "")
                            wrapMode: Text.WordWrap
                            color: theme ? theme.textColor : "black"
                            font.pixelSize: 14
                        }
                    }
                }
            }
            
            // 错误详情区域
            ColumnLayout {
                Layout.fillWidth: true
                visible: importSuccessDialog.errorCount > 0
                spacing: 10
                
                // 错误标题
                RowLayout {
                    spacing: 8
                    
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: "#f44336"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "!"
                            color: "white"
                            font.bold: true
                        }
                    }
                    
                    Text {
                        text: "错误详情："
                        font.pixelSize: 16
                        font.bold: true
                        color: theme ? theme.textColor : "black"
                    }
                }
                
                // 错误列表
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(300, importSuccessDialog.errorDetails.length * 100)
                    border.width: 1
                    border.color: inputBorderColor
                    color: inputBgColor
                    radius: 4
                    clip: true
                    
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 5
                        
                        ListView {
                            id: errorList
                            anchors.fill: parent
                            model: importSuccessDialog.errorDetails
                            spacing: 10
                            delegate: Rectangle {
                                width: errorList.width - 10
                                height: errorItemLayout.implicitHeight + 24
                                color: theme ? (theme.isDarkTheme ? Qt.rgba(0.2, 0.0, 0.0, 0.4) : Qt.rgba(1.0, 0.9, 0.9, 1.0)) : "#fff0f0"
                                border.color: "#ffcdd2"
                                border.width: 1
                                radius: 5
                                
                                ColumnLayout {
                                    id: errorItemLayout
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8
                                    
                                    // 错误行号
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 5
                                        
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: "#f44336"
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: "!"
                                                color: "white"
                                                font.bold: true
                                            }
                                        }
                                        
                                        Text {
                                            Layout.fillWidth: true
                                            text: "行 " + (modelData.row || "未知")
                                            font.bold: true
                                            font.pixelSize: 14
                                            color: "#c62828"
                                        }
                                    }
                                    
                                    // 错误数据
                                    Text {
                                        Layout.fillWidth: true
                                        text: "原始内容: " + (String(modelData.data || "").length > 100 ? 
                                              String(modelData.data || "").substring(0, 100) + "..." : 
                                              String(modelData.data || ""))
                                        font.pixelSize: 13
                                        color: theme ? theme.textColor : "black"
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 3
                                    }
                                    
                                    // 错误信息
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: errorMessageText.implicitHeight + 16
                                        color: theme ? (theme.isDarkTheme ? Qt.rgba(0.3, 0.0, 0.0, 0.4) : Qt.rgba(1.0, 0.8, 0.8, 0.7)) : "#ffebee"
                                        radius: 4
                                        
                                        Text {
                                            id: errorMessageText
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            text: "错误原因: " + (modelData.message || "未知错误")
                                            font.pixelSize: 13
                                            color: "#d32f2f"
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 导入规则提示
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: importTipsText.implicitHeight + 20
                color: theme ? (theme.isDarkTheme ? Qt.rgba(0.1, 0.2, 0.3, 0.5) : Qt.rgba(0.9, 0.95, 1.0, 0.5)) : "#e3f2fd"
                border.color: "#bbdefb"
                border.width: 1
                radius: 4
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Text {
                        text: "💡"
                        font.pixelSize: 18
                        color: theme ? theme.textColor : "black"
                    }
                    
                    Text {
                        id: importTipsText
                        Layout.fillWidth: true
                        text: importSuccessDialog.errorCount > 0 ? 
                              "提示: 导入时系统已自动清除前后空格。确保日期格式正确(如YYYY-MM-DD或YYYY年MM月DD日)，项目名称不为空，并且盈亏值为有效数字。\n支持格式：项目名称：盈/亏XXX元，YYYY年MM月DD日" : 
                              "提示: 系统已自动处理所有数据并清除前后空格。"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        color: theme ? theme.textColor : "black"
                    }
                }
            }
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
        width: 400 // 设置显式宽度
        
        function showError(message) {
            errorText.text = message;
            open();
        }
        
        contentItem: Text {
            id: errorText
            wrapMode: Text.WordWrap
        }
    }
    
    // 预览单元格组件 (会被动态创建)
    Component {
        id: previewCellComponent
        
        Rectangle {
            property string text: ""
            height: 24
            color: theme ? (theme.isDarkTheme ? "#34495e" : "#f0f0f0") : "#f0f0f0"
            
            Text {
                anchors.fill: parent
                anchors.margins: 4
                text: parent.text
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                color: theme ? theme.textColor : "black"
            }
        }
    }
    
    // 预览表头单元格组件 (会被动态创建)
    Component {
        id: previewHeaderComponent
        
        Rectangle {
            property string text: ""
            height: 26
            color: buttonBgColor
            
            Text {
                anchors.fill: parent
                anchors.margins: 4
                text: parent.text
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                font.bold: true
                color: "white"
            }
        }
    }
    
    // 手动录入交易对话框
    Dialog {
        id: manualEntryDialog
        title: "新增交易"
        // 设置一个更合适的固定宽度，不使用自适应
        width: 520  // 增加弹窗宽度
        anchors.centerIn: parent
        modal: true
        padding: 20
        
        background: Rectangle {
            color: theme ? theme.cardColor : "white"
            radius: 5
            border.color: inputBorderColor
            border.width: 1
            
            // 使用简化的阴影属性
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8.0
                samples: 17
                color: "#80000000"
            }
        }
        
        contentItem: ColumnLayout {
            spacing: 15
            // 不需要明确指定布局宽度，让Dialog控制宽度
            
            // 表单标题
            Text {
                text: "录入交易详情"
                font.pixelSize: 16
                font.bold: true
                color: theme ? theme.textColor : "black"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 5
            }
            
            // 表单区域
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 10
                Layout.fillWidth: true
                
                // 日期
                Text {
                    text: "日期*"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        id: dateInput
                        anchors.fill: parent
                        anchors.margins: 5
                        verticalAlignment: TextInput.AlignVCenter
                        color: inputTextColor
                        selectByMouse: true
                        font.pixelSize: inputFontSize
                        
                        // 设置当前日期作为默认值
                        Component.onCompleted: {
                            var today = new Date();
                            var dd = String(today.getDate()).padStart(2, '0');
                            var mm = String(today.getMonth() + 1).padStart(2, '0');
                            var yyyy = today.getFullYear();
                            text = yyyy + '-' + mm + '-' + dd;
                        }
                    }
                    
                    MouseArea {
                        anchors.right: parent.right
                        width: 30
                        height: parent.height
                        onClicked: {
                            // 这里可以添加日期选择器，但需要额外的组件
                            console.log("打开日期选择器");
                        }
                    }
                }
                
                // 名称 (原项目名称)
                Text {
                    text: "名称*"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        id: projectNameInput
                        anchors.fill: parent
                        anchors.margins: 5
                        verticalAlignment: TextInput.AlignVCenter
                        color: inputTextColor
                        selectByMouse: true
                        font.pixelSize: inputFontSize
                    }
                }
                
                // 盈亏选择 (使用下拉框选择盈利/亏损)
                Text {
                    text: "盈亏*"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    // 盈亏选择下拉框
                    Rectangle {
                        Layout.preferredWidth: 120  // 增加宽度
                        height: inputHeight
                        color: inputBgColor
                        border.color: inputBorderColor
                        border.width: 1
                        radius: inputRadius
                        
                        ComboBox {
                            id: profitLossTypeComboBox
                            anchors.fill: parent
                            model: ["盈利", "亏损"]
                            currentIndex: 0
                        }
                    }
                    
                    // 金额输入框
                    Rectangle {
                        Layout.fillWidth: true
                        height: inputHeight
                        color: inputBgColor
                        border.color: inputBorderColor
                        border.width: 1
                        radius: inputRadius
                        
                        TextInput {
                            id: profitLossInput
                            anchors.fill: parent
                            anchors.margins: 5
                            verticalAlignment: TextInput.AlignVCenter
                            color: inputTextColor
                            selectByMouse: true
                            font.pixelSize: inputFontSize
                            validator: DoubleValidator { bottom: 0 } // 只允许输入正数，正负由下拉框决定
                        }
                    }
                }
                
                // 币种
                Text {
                    text: "币种"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        id: currencyInput
                        anchors.fill: parent
                        anchors.margins: 5
                        verticalAlignment: TextInput.AlignVCenter
                        color: inputTextColor
                        selectByMouse: true
                        text: "CNY" // 默认人民币
                        font.pixelSize: inputFontSize
                    }
                }
                
                // 资产类别
                Text {
                    text: "资产类别"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    ComboBox {
                        id: assetTypeComboBox
                        anchors.fill: parent
                        model: ["股票", "基金", "债券", "期货", "外汇", "其他"]
                        currentIndex: 0
                    }
                }
                
                // 数量
                Text {
                    text: "数量"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextInput {
                        id: amountInput
                        anchors.fill: parent
                        anchors.margins: 5
                        verticalAlignment: TextInput.AlignVCenter
                        color: inputTextColor
                        selectByMouse: true
                        text: "1" // 默认数量1
                        font.pixelSize: inputFontSize
                        validator: DoubleValidator { bottom: 0 }
                    }
                }
                
                // 备注
                Text {
                    text: "备注"
                    color: theme ? theme.textColor : "black"
                    font.pixelSize: labelFontSize
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: inputHeight * 2
                    color: inputBgColor
                    border.color: inputBorderColor
                    border.width: 1
                    radius: inputRadius
                    
                    TextArea {
                        id: notesInput
                        anchors.fill: parent
                        anchors.margins: 5
                        wrapMode: TextEdit.WordWrap
                        color: inputTextColor
                        selectByMouse: true
                        font.pixelSize: inputFontSize
                    }
                }
            }
            
            // 必填字段提示
            Text {
                text: "* 必填字段"
                font.pixelSize: 12
                font.italic: true
                color: theme ? Qt.darker(theme.textColor, 1.3) : "#666666"
            }
            
            // 按钮区
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 5
                spacing: 10
                
                CustomButton {
                    text: "取消"
                    Layout.preferredWidth: 120  // 增加按钮宽度
                    onClicked: manualEntryDialog.close()
                }
                
                CustomButton {
                    text: "保存"
                    highlighted: true
                    Layout.preferredWidth: 120  // 增加按钮宽度
                    onClicked: {
                        // 验证表单
                        if (projectNameInput.text.trim() === "") {
                            errorDialog.showError("名称不能为空");
                            return;
                        }
                        
                        if (dateInput.text.trim() === "") {
                            errorDialog.showError("日期不能为空");
                            return;
                        }
                        
                        if (profitLossInput.text.trim() === "") {
                            errorDialog.showError("盈亏金额不能为空");
                            return;
                        }
                        
                        // 计算实际盈亏值（正数为盈利，负数为亏损）
                        var profitLossValue = parseFloat(profitLossInput.text) || 0;
                        if (profitLossTypeComboBox.currentIndex === 1) { // 如果选择"亏损"
                            profitLossValue = -profitLossValue;
                        }
                        
                        // 创建交易数据
                        var transaction = {
                            date: dateInput.text,
                            project_name: projectNameInput.text,
                            asset_type: assetTypeComboBox.currentText,
                            amount: parseFloat(amountInput.text) || 1,
                            profit_loss: profitLossValue,
                            currency: currencyInput.text,
                            notes: notesInput.text,
                            unit_price: profitLossValue // 假设单价暂时使用盈亏金额
                        };
                        
                        console.log("Saving transaction QML:", JSON.stringify(transaction));
                        
                        // 修复后端调用参数问题
                        try {
                            // 直接使用字段值分别传递，而不是将JSON对象作为参数传递
                            // 确保参数顺序和数量与后端定义一致
                            // Python: def addTransaction(self, date, asset_type, project_name, amount, unit_price, currency, profit_loss, notes)
                            // QML Call: date, asset_type, project_name, amount, unit_price, currency, profit_loss, notes
                            var success = backend.addTransaction(
                                transaction.date,           // date
                                transaction.asset_type,     // asset_type
                                transaction.project_name,   // project_name
                                transaction.amount,         // amount
                                transaction.unit_price,     // unit_price
                                transaction.currency,       // currency
                                transaction.profit_loss,    // profit_loss
                                transaction.notes || ""     // notes
                            );
                            
                            if (success) {
                                manualEntryDialog.close();
                                
                                // 清空表单，为下一次录入做准备
                                projectNameInput.text = "";
                                profitLossInput.text = "";
                                notesInput.text = "";
                                
                                // 显示成功消息
                                successDialog.showMessage("交易记录已成功保存");
                            } else {
                                errorDialog.showError("保存交易失败，请重试");
                            }
                        } catch (e) {
                            console.error("Error saving transaction:", e);
                            errorDialog.showError("保存交易失败: " + e.toString());
                        }
                    }
                }
            }
        }
    }
    
    // 成功消息对话框
    Dialog {
        id: successDialog
        title: "成功"
        standardButtons: Dialog.Ok
        modal: true
        
        function showMessage(message) {
            successText.text = message;
            open();
        }
        
        contentItem: Text {
            id: successText
            wrapMode: Text.WordWrap
            color: theme ? theme.textColor : "black"
        }
    }
    
    // 全局快捷键支持
    Shortcut {
        sequences: ["Ctrl+N"]
        onActivated: manualEntryTransaction()
    }
} 
