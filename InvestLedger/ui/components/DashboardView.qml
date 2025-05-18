import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Item {
    id: dashboardView
    
    property bool hasData: false // 用于跟踪是否有数据

    // 当视图被加载时获取数据
    Component.onCompleted: {
        loadData();
    }

    Timer {
        id: initialLoadTimer
        interval: 50 // 短暂延迟以确保UI元素准备好
        running: !userSelected // 如果没有用户选择，则启动计时器显示空状态
        repeat: false
        onTriggered: {
            if (!userSelected) {
                emptyStateOverlay.visible = true;
                dashboardContent.visible = false;
            }
        }
    }
    
    function loadData() {
        // 如果未选择用户，不加载数据，并确保显示空状态
        if (!userSelected) {
            hasData = false;
            emptyStateOverlay.visible = true;
            dashboardContent.visible = false;
            return;
        }
        
        // 获取当前日期
        var today = new Date();
        var year = today.getFullYear();
        var month = today.getMonth() + 1;
        
        // 获取月度和年度目标比较数据
        var monthlyGoal = backend.getMonthlyGoalComparison(year, month);
        var yearlyGoal = backend.getYearlyGoalComparison(year);
        
        // 更新界面显示
        monthlyGoalText.text = monthlyGoal.goal_amount.toFixed(2);
        monthlyActualText.text = monthlyGoal.actual_amount.toFixed(2);
        monthlyCompletionText.text = monthlyGoal.completion_percentage.toFixed(1) + "%";
        
        yearlyGoalText.text = yearlyGoal.goal_amount.toFixed(2);
        yearlyActualText.text = yearlyGoal.actual_amount.toFixed(2);
        yearlyCompletionText.text = yearlyGoal.completion_percentage.toFixed(1) + "%";
        
        // 颜色设置：根据盈亏情况设置文本颜色
        monthlyActualText.color = monthlyGoal.actual_amount >= 0 ? profitColor : lossColor;
        yearlyActualText.color = yearlyGoal.actual_amount >= 0 ? profitColor : lossColor;
        
        // 加载趋势数据
        var trendData = backend.getProfitLossSummary("month", null, null);
        
        // 加载顶级盈利项目
        var topProfitProjects = backend.getTopProjects(5, true, null, null);
        topProfitModel.clear();
        for (var i = 0; i < topProfitProjects.length; i++) {
            topProfitModel.append({
                name: topProfitProjects[i].project_name,
                amount: topProfitProjects[i].total_profit_loss,
                count: topProfitProjects[i].transaction_count
            });
        }
        
        // 加载顶级亏损项目
        var topLossProjects = backend.getTopProjects(5, false, null, null);
        topLossModel.clear();
        for (var j = 0; j < topLossProjects.length; j++) {
            topLossModel.append({
                name: topLossProjects[j].project_name,
                amount: Math.abs(topLossProjects[j].total_profit_loss),
                count: topLossProjects[j].transaction_count
            });
        }

        // 检查是否有有效数据
        // 这里可以根据实际情况定义何为“有数据”，例如检查关键列表模型是否为空
        hasData = topProfitModel.count > 0 || topLossModel.count > 0 || trendData.length > 0;
        emptyStateOverlay.visible = !hasData;
        dashboardContent.visible = hasData;
    }
    
    // 空状态覆盖层
    Rectangle {
        id: emptyStateOverlay
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.02) // 轻微的背景色，使其与内容区分
        visible: !hasData && !userSelected // 初始根据是否有数据和用户选择来决定可见性
        z: 1 // 确保在内容之上

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15

            Image {
                source: "qrc:/icons/empty-box.svg" // 假设有一个空状态图标
                Layout.alignment: Qt.AlignHCenter
                width: 128
                height: 128
                fillMode: Image.PreserveAspectFit
                // 如果没有SVG图标，可以使用Text图标或纯文本
                // Text {
                //     text: "📭"
                //     font.pixelSize: 64
                //     Layout.alignment: Qt.AlignHCenter
                // }
            }

            Text {
                text: !userSelected ? qsTr("请先选择或创建一个用户以查看仪表盘。") : qsTr("仪表盘暂无数据")
                font.pixelSize: 18
                color: Qt.darker(theme.textColor, 1.3)
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: userSelected && !hasData // 仅当已选择用户但无数据时显示
                text: qsTr("尝试添加一些交易记录，或调整筛选条件。")
                font.pixelSize: 14
                color: Qt.darker(theme.textColor, 1.5)
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    ScrollView {
        id: dashboardContent
        anchors.fill: parent
        clip: true
        visible: hasData // 根据是否有数据来决定可见性
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
        }
        ColumnLayout {
            width: dashboardView.width - 30
            spacing: 20
            
            // 欢迎信息
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 5
                color: cardColor
                opacity: 0.0
                SequentialAnimation on opacity {
                    NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuad }
                }
                Component.onCompleted: opacity = 1.0;
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5
                    
                    Text {
                        text: "欢迎回来 " + currentUser
                        font.pixelSize: 22
                        font.bold: true
                    }
                    
                    Text {
                        text: "今天是 " + new Date().toLocaleDateString(Qt.locale("zh_CN"), "yyyy年MM月dd日 dddd")
                        font.pixelSize: 14
                        color: Qt.darker(textColor, 1.2)
                    }
                }
            }
            
            // 快速添加交易区域
            Rectangle {
                Layout.fillWidth: true
                height: 100
                radius: 5
                color: cardColor
                y: 40
                SequentialAnimation on y {
                    NumberAnimation { to: 0; duration: 400; easing.type: Easing.OutQuad }
                }
                Component.onCompleted: y = 0;
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 5
                    
                    Text {
                        text: "快速添加交易"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        opacity: 0.0
                        Behavior on opacity {
                            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
                        }
                        Component.onCompleted: opacity = 1.0;
                        
                        TextField {
                            id: quickAddField
                            Layout.fillWidth: true
                            placeholderText: "格式: 项目名称:盈/亏XXX元, YYYY年MM月DD日"
                            
                            Keys.onEnterPressed: quickAddTransaction()
                            Keys.onReturnPressed: quickAddTransaction()
                        }
                        
                        Button {
                            text: "添加"
                            onClicked: quickAddTransaction()
                        }
                    }
                    
                    function quickAddTransaction() {
                        if (quickAddField.text.trim()) {
                            var result = backend.importClipboardText(quickAddField.text);
                            if (result.success) {
                                quickAddField.text = "";
                                loadData();
                            } else {
                                errorDialog.showError("解析失败: " + result.message);
                            }
                        }
                    }
                }
            }
            
            // 盈亏目标卡片
            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                
                // 月度目标卡片
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 5
                        
                        Text {
                            text: "本月盈亏目标"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 5
                            columnSpacing: 10
                            
                            Text { text: "目标金额:"; font.pixelSize: 14 }
                            Text { 
                                id: monthlyGoalText
                                text: "0.00"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text { text: "实际金额:"; font.pixelSize: 14 }
                            Text { 
                                id: monthlyActualText
                                text: "0.00"
                                font.pixelSize: 14
                                font.bold: true
                                color: profitColor
                            }
                            
                            Text { text: "完成百分比:"; font.pixelSize: 14 }
                            Text { 
                                id: monthlyCompletionText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                    }
                }
                
                // 年度目标卡片
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 5
                        
                        Text {
                            text: "本年盈亏目标"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 5
                            columnSpacing: 10
                            
                            Text { text: "目标金额:"; font.pixelSize: 14 }
                            Text { 
                                id: yearlyGoalText
                                text: "0.00"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text { text: "实际金额:"; font.pixelSize: 14 }
                            Text { 
                                id: yearlyActualText
                                text: "0.00"
                                font.pixelSize: 14
                                font.bold: true
                                color: profitColor
                            }
                            
                            Text { text: "完成百分比:"; font.pixelSize: 14 }
                            Text { 
                                id: yearlyCompletionText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                    }
                }
            }
            
            // 盈亏项目排行
            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                
                // 盈利排行
                Rectangle {
                    Layout.fillWidth: true
                    height: 250
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "盈利项目排行"
                            font.pixelSize: 16
                            font.bold: true
                            color: profitColor
                        }
                        
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: ListModel { id: topProfitModel }
                            delegate: Rectangle {
                                width: parent.width
                                height: 40
                                color: index % 2 === 0 ? "transparent" : Qt.lighter(bgColor, 1.02)
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    
                                    Text { 
                                        text: (index + 1) + "." 
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 20
                                    }
                                    
                                    Text { 
                                        text: name 
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text { 
                                        text: "+" + amount.toFixed(2)
                                        font.pixelSize: 14
                                        color: profitColor
                                        font.bold: true
                                        Layout.preferredWidth: 80
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    
                                    Text { 
                                        text: count + "笔"
                                        font.pixelSize: 12
                                        color: Qt.darker(textColor, 1.2)
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 亏损排行
                Rectangle {
                    Layout.fillWidth: true
                    height: 250
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        
                        Text {
                            text: "亏损项目排行"
                            font.pixelSize: 16
                            font.bold: true
                            color: lossColor
                        }
                        
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: ListModel { id: topLossModel }
                            delegate: Rectangle {
                                width: parent.width
                                height: 40
                                color: index % 2 === 0 ? "transparent" : Qt.lighter(bgColor, 1.02)
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    
                                    Text { 
                                        text: (index + 1) + "." 
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 20
                                    }
                                    
                                    Text { 
                                        text: name 
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    
                                    Text { 
                                        text: "-" + amount.toFixed(2)
                                        font.pixelSize: 14
                                        color: lossColor
                                        font.bold: true
                                        Layout.preferredWidth: 80
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    
                                    Text { 
                                        text: count + "笔"
                                        font.pixelSize: 12
                                        color: Qt.darker(textColor, 1.2)
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Item { height: 20 } // 底部间距
        }
    }
}