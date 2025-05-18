import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

// 全局错误对话框
Dialog {
    id: errorDialog
    title: "错误"
    width: 300
    height: 150
    anchors.centerIn: parent
    modal: true
    closePolicy: Popup.CloseOnEscape

    property string errorMessage: "发生未知错误"

    contentItem: ColumnLayout {
        spacing: 20

        Text {
            text: errorDialog.errorMessage
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
        errorMessage = message;
        open();
    }
}

// 确认对话框
Dialog {
    id: confirmDialog
    title: "确认操作"
    width: 350
    height: 180
    anchors.centerIn: parent
    modal: true
    closePolicy: Popup.CloseOnEscape

    property string confirmMessage: "您确定要执行此操作吗？"
    signal confirmed

    contentItem: ColumnLayout {
        spacing: 20

        Text {
            text: confirmDialog.confirmMessage
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "取消"
                Layout.fillWidth: true
                onClicked: confirmDialog.close()
            }

            Button {
                text: "确定"
                Layout.fillWidth: true
                highlighted: true
                onClicked: {
                    confirmDialog.confirmed();
                    confirmDialog.close();
                }
            }
        }
    }

    function show(message, onConfirm) {
        confirmMessage = message;
        // Disconnect previous signal handler if any to avoid multiple calls
        if (typeof confirmDialog.previousOnConfirm === 'function') {
            confirmDialog.confirmed.disconnect(confirmDialog.previousOnConfirm);
        }
        confirmDialog.confirmed.connect(onConfirm);
        confirmDialog.previousOnConfirm = onConfirm; // Store for later disconnect
        open();
    }
}

// 关于对话框
Dialog {
    id: aboutDialog
    title: "关于 InvestLedger"
    width: 400
    height: 300
    anchors.centerIn: parent
    modal: true
    closePolicy: Popup.CloseOnEscape

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Image {
            source: "qrc:/icons/app-icon.png" // 确保应用图标路径正确
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: "InvestLedger"
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "版本: " + appVersion // appVersion 从 main.py 传递
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "一个轻量级的个人投资记账程序。"
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "© 2024 Your Name/Company"
            font.pixelSize: 10
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: "关闭"
            Layout.alignment: Qt.AlignHCenter
            onClicked: aboutDialog.close()
        }
    }
}

// 帮助与支持对话框
Dialog {
    id: helpDialog
    title: "帮助与支持"
    width: 600
    height: 500
    anchors.centerIn: parent
    modal: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        TabBar {
            id: helpTabBar
            Layout.fillWidth: true

            TabButton { text: "功能指南" }
            TabButton { text: "快捷键" }
            TabButton { text: "常见问题" }
            TabButton { text: "关于" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: helpTabBar.currentIndex

            // 功能指南
            ScrollView {
                clip: true
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "功能指南内容暂时移除以测试解析错误。请后续恢复或替换为正确内容。"
                }
            }

            // 快捷键
            ScrollView {
                clip: true
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "# 快捷键列表\n\n" +
                          "- Ctrl + N: 新建交易\n" +
                          "- Ctrl + S: 保存当前操作\n" +
                          "- Ctrl + O: 打开文件/导入\n" +
                          "- Ctrl + Z: 撤销\n" +
                          "- Ctrl + Y: 重做\n" +
                          "- F1: 打开帮助文档\n" +
                          "- Esc: 关闭当前对话框/窗口"
                }
            }

            // 常见问题
            ScrollView {
                clip: true
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "# 常见问题 (FAQ)\n\n" +
                          "**Q1: 如何开始使用？**\n" +
                          "A1: 首次启动时，系统会引导您创建用户。创建用户后，即可开始添加交易记录。\n\n" +
                          "**Q2: 数据保存在哪里？**\n" +
                          "A2: 用户数据默认保存在您的用户配置文件夹下的 InvestLedger 目录中。具体路径可以在设置中查看。\n\n" +
                          "**Q3: 如何备份数据？**\n" +
                          "A3: 您可以在设置页面手动备份数据库，也可以设置自动备份天数。\n\n" +
                          "**Q4: 支持哪些导入格式？**\n" +
                          "A4: 目前主要支持从CSV文件导入交易数据。"
                }
            }

            // 关于 (复用上面的AboutDialog内容或单独实现)
            Item {
                AboutDialogContent { anchors.fill: parent } // 假设AboutDialog内容被封装
            }
        }
    }
}

// 简单的AboutDialog内容组件，用于HelpDialog
Item {
    id: aboutDialogContentComponent
    Component {
        id: aboutDialogContentProto
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Image {
                source: "qrc:/icons/app-icon.png"
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "InvestLedger"
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                // text: "版本: " + appVersion // appVersion可能在此处不可用，除非传递
                text: "版本: (请从主程序获取)"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "一个轻量级的个人投资记账程序。"
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
    Loader { sourceComponent: aboutDialogContentProto; anchors.fill: parent }
}

// 导入进度对话框
Dialog {
    id: importProgressDialog
    title: "导入进度"
    width: 400
    height: 200
    anchors.centerIn: parent
    modal: true
    standardButtons: Dialog.Cancel // 提供取消按钮

    property string currentFile: ""
    property int progressValue: 0
    property string statusText: "准备导入..."

    onRejected: { // 当用户点击取消时
        backend.cancelImport();
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        Text {
            text: "正在导入: " + importProgressDialog.currentFile
            wrapMode: Text.ElideRight
        }

        ProgressBar {
            Layout.fillWidth: true
            value: importProgressDialog.progressValue / 100 // ProgressBar通常接受0.0-1.0的值
        }

        Text {
            text: importProgressDialog.statusText
        }
    }

    function updateProgress(fileName, progress, status) {
        currentFile = fileName;
        progressValue = progress;
        statusText = status;
        if (!visible) {
            open();
        }
    }

    function closeDialog() {
        close();
    }
}

// 导入完成/错误报告对话框
Dialog {
    id: importReportDialog
    title: "导入报告"
    width: 500
    height: 400
    anchors.centerIn: parent
    modal: true

    property string reportTitle: "导入完成"
    property string summaryText: ""
    property var errorDetails: [] // [{row: 1, column: 'A', error: '格式错误'}]

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        Text {
            text: importReportDialog.reportTitle
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: importReportDialog.summaryText
            wrapMode: Text.WordWrap
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                model: importReportDialog.errorDetails
                delegate: ItemDelegate {
                    width: parent.width
                    text: "行: " + modelData.row + ", 列: " + modelData.column + " - 错误: " + modelData.error
                    // 可以添加更多样式或信息
                }
            }
        }

        Button {
            text: "确定"
            Layout.alignment: Qt.AlignRight
            onClicked: importReportDialog.close()
        }
    }

    function showReport(title, summary, errors) {
        reportTitle = title;
        summaryText = summary;
        errorDetails = errors;
        open();
    }
}