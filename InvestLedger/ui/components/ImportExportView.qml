import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: importExportView
    
    property var importPreviewData: []
    property string importMode: "clipboard"  // clipboard 或 file
    
    // 当视图被加载时初始化
    Component.onCompleted: {
        // 初始化
    }
    
    function previewClipboardText() {
        var text = clipboardTextField.text.trim();
        if (!text) {
            errorDialog.showError("请先粘贴文本内容");
            return;
        }
        
        var result = backend.importClipboardText(text);
        if (result.success) {
            importResultDialog.show("导入成功", "已成功导入 " + result.success_count + " 条交易记录");
            clipboardTextField.text = "";
        } else {
            var errorMsg = "导入失败: " + result.message + "\n\n";
            if (result.errors && result.errors.length > 0) {
                errorMsg += "错误详情:\n";
                for (var i = 0; i < result.errors.length; i++) {
                    errorMsg += "行 " + result.errors[i].row + ": " + result.errors[i].message + "\n";
                }
            }
            errorDialog.showError(errorMsg);
        }
    }
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        spacing: 20
        
        // 顶部标题
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: cardColor
            radius: 5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                
                Text {
                    text: "数据导入与导出"
                    font.pixelSize: 18
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                TabBar {
                    id: importTypeTabs
                    Layout.preferredWidth: 300
                    
                    TabButton {
                        text: "剪贴板导入"
                        width: implicitWidth
                        onClicked: importMode = "clipboard"
                    }
                    
                    TabButton {
                        text: "文件导入"
                        width: implicitWidth
                        onClicked: importMode = "file"
                    }
                    
                    TabButton {
                        text: "数据导出"
                        width: implicitWidth
                        onClicked: importMode = "export"
                    }
                }
            }
        }
        
        // 中间内容区
        StackLayout {
            currentIndex: {
                if (importMode === "clipboard") return 0;
                if (importMode === "file") return 1;
                return 2; // export
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // 剪贴板导入
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Text {
                            text: "粘贴文本内容："
                            font.pixelSize: 14
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Text {
                            text: "支持格式: 项目名称：盈/亏XXX元，YYYY年MM月DD日"
                            font.pixelSize: 12
                            color: Qt.darker(textColor, 1.2)
                        }
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        TextArea {
                            id: clipboardTextField
                            placeholderText: "请粘贴要导入的文本"
                            wrapMode: TextEdit.WordWrap
                            selectByMouse: true
                        }
                    }
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Button {
                            text: "导入数据"
                            highlighted: true
                            onClicked: previewClipboardText()
                        }
                    }
                }
            }
            
            // 文件导入
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "文件导入功能尚未完全实现。请使用剪贴板导入。"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    // 文件选择按钮
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        TextField {
                            id: filePathField
                            Layout.fillWidth: true
                            readOnly: true
                            placeholderText: "请选择CSV文件"
                        }
                        
                        Button {
                            text: "选择文件"
                            onClicked: {
                                // 文件对话框
                                // 注意: 在实际实现中，这里需要使用Qt Quick的文件对话框
                                // 简化版本中，我们只显示一个未实现的消息
                                errorDialog.showError("文件选择功能尚未完全实现。请使用剪贴板导入。");
                            }
                        }
                    }
                    
                    // 分隔符设置
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        
                        Text {
                            text: "分隔符:"
                            font.pixelSize: 14
                        }
                        
                        ComboBox {
                            id: delimiterCombo
                            model: [
                                {text: "逗号(,)", value: ","},
                                {text: "制表符(\\t)", value: "\t"},
                                {text: "分号(;)", value: ";"}
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                            Layout.preferredWidth: 150
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Button {
                            text: "预览"
                            enabled: filePathField.text.length > 0
                            onClicked: {
                                errorDialog.showError("文件预览功能尚未完全实现。请使用剪贴板导入。");
                            }
                        }
                        
                        Button {
                            text: "导入"
                            highlighted: true
                            enabled: filePathField.text.length > 0
                            onClicked: {
                                errorDialog.showError("文件导入功能尚未完全实现。请使用剪贴板导入。");
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.lighter(bgColor, 1.02)
                        border.color: Qt.lighter(primaryColor, 1.5)
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "CSV预览区域"
                            font.pixelSize: 14
                            color: Qt.darker(textColor, 1.2)
                        }
                    }
                }
            }
            
            // 数据导出
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    Text {
                        text: "数据导出功能尚未完全实现。"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    
                    // 导出设置区域
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 20
                        
                        // 导出格式
                        Text { text: "导出格式:"; font.pixelSize: 14 }
                        ComboBox {
                            id: exportFormatCombo
                            model: ["CSV", "Excel", "PDF"]
                            currentIndex: 0
                            Layout.preferredWidth: 150
                        }
                        
                        // 开始日期
                        Text { text: "开始日期:"; font.pixelSize: 14 }
                        TextField {
                            id: exportStartDateField
                            placeholderText: "YYYY-MM-DD"
                            Layout.preferredWidth: 150
                        }
                        
                        // 结束日期
                        Text { text: "结束日期:"; font.pixelSize: 14 }
                        TextField {
                            id: exportEndDateField
                            placeholderText: "YYYY-MM-DD"
                            Layout.preferredWidth: 150
                        }
                        
                        // 资产类型
                        Text { text: "资产类型:"; font.pixelSize: 14 }
                        ComboBox {
                            id: exportAssetTypeCombo
                            model: ["全部"]
                            currentIndex: 0
                            Layout.preferredWidth: 150
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    // 导出按钮
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 10
                        
                        Button {
                            text: "导出数据"
                            highlighted: true
                            onClicked: {
                                errorDialog.showError("导出功能尚未完全实现。");
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 导入结果对话框
    Dialog {
        id: importResultDialog
        title: "导入结果"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property string resultTitle: ""
        property string resultMessage: ""
        
        contentItem: ColumnLayout {
            spacing: 15
            
            Text {
                id: resultTitleText
                text: importResultDialog.resultTitle
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Text {
                id: resultMessageText
                text: importResultDialog.resultMessage
                font.pixelSize: 14
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            
            Button {
                text: "确定"
                Layout.alignment: Qt.AlignRight
                onClicked: importResultDialog.close()
            }
        }
        
        function show(title, message) {
            resultTitle = title;
            resultMessage = message;
            open();
        }
    }
} 