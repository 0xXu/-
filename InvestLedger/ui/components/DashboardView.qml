import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Item {
    id: dashboardView
    
    property bool hasData: false // 用于跟踪是否有数据
    property var totalStats: ({}) // 总体统计数据

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
        var lastYear = year - 1;
        
        // 获取月度和年度目标比较数据
        var monthlyGoal = backend.getMonthlyGoalComparison(year, month);
        var yearlyGoal = backend.getYearlyGoalComparison(year);
        
        // 获取去年同期数据
        var lastYearMonthlyGoal = backend.getMonthlyGoalComparison(lastYear, month);
        var lastYearYearlyGoal = backend.getYearlyGoalComparison(lastYear);
        
        // 更新界面显示
        monthlyGoalText.text = monthlyGoal.goal_amount.toFixed(2);
        monthlyActualText.text = monthlyGoal.actual_amount.toFixed(2);
        monthlyCompletionText.text = monthlyGoal.completion_percentage.toFixed(1) + "%";
        monthlyProgressBar.value = Math.min(Math.abs(monthlyGoal.completion_percentage), 100) / 100;
        
        // 去年同期月度数据
        if (lastYearMonthlyGoal && lastYearMonthlyGoal.actual_amount) {
            const yoyChange = ((monthlyGoal.actual_amount - lastYearMonthlyGoal.actual_amount) / Math.abs(lastYearMonthlyGoal.actual_amount)) * 100;
            monthlyYoYText.text = yoyChange.toFixed(1) + "%";
            monthlyYoYText.color = yoyChange >= 0 ? profitColor : lossColor;
        } else {
            monthlyYoYText.text = "无同期数据";
            monthlyYoYText.color = theme.textColor;
        }
        
        // 年度数据
        yearlyGoalText.text = yearlyGoal.goal_amount.toFixed(2);
        yearlyActualText.text = yearlyGoal.actual_amount.toFixed(2);
        yearlyCompletionText.text = yearlyGoal.completion_percentage.toFixed(1) + "%";
        yearlyProgressBar.value = Math.min(Math.abs(yearlyGoal.completion_percentage), 100) / 100;
        
        // 去年同期年度数据
        if (lastYearYearlyGoal && lastYearYearlyGoal.actual_amount) {
            const annualYoyChange = ((yearlyGoal.actual_amount - lastYearYearlyGoal.actual_amount) / Math.abs(lastYearYearlyGoal.actual_amount)) * 100;
            yearlyYoYText.text = annualYoyChange.toFixed(1) + "%";
            yearlyYoYText.color = annualYoyChange >= 0 ? profitColor : lossColor;
        } else {
            yearlyYoYText.text = "无同期数据";
            yearlyYoYText.color = theme.textColor;
        }
        
        // 计算目标合理性
        evaluateTargetReasonability(monthlyGoal, lastYearMonthlyGoal, "monthly");
        evaluateTargetReasonability(yearlyGoal, lastYearYearlyGoal, "yearly");
        
        // 颜色设置：根据盈亏情况设置文本颜色
        monthlyActualText.color = monthlyGoal.actual_amount >= 0 ? profitColor : lossColor;
        yearlyActualText.color = yearlyGoal.actual_amount >= 0 ? profitColor : lossColor;
        
        // 总体统计计算
        calculateTotalStatistics();
        
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
        // 获取所有交易数据，用null表示不限日期范围
        var allTransactions = backend.getTransactions(null, null, "", 999, 0);
        // 修改判断条件：有任何交易数据都算作有数据
        hasData = allTransactions.length > 0 || topProfitModel.count > 0 || topLossModel.count > 0 || trendData.length > 0;
        
        console.log("Dashboard data check: transactions=" + allTransactions.length + 
                    ", profit projects=" + topProfitModel.count + 
                    ", loss projects=" + topLossModel.count + 
                    ", trends=" + trendData.length);
        
        emptyStateOverlay.visible = !hasData;
        dashboardContent.visible = hasData;
    }
    
    // 计算目标合理性分析
    function evaluateTargetReasonability(currentGoal, lastYearGoal, type) {
        let targetTextElement = type === "monthly" ? monthlyTargetAnalysisText : yearlyTargetAnalysisText;
        let actualAmount = currentGoal.actual_amount;
        let goalAmount = currentGoal.goal_amount;
        
        if (goalAmount <= 0) {
            targetTextElement.text = "未设置目标";
            targetTextElement.color = theme.textColor;
            return;
        }
        
        let progressPercentage = actualAmount / goalAmount * 100;
        let timeProgress = 0;
        
        if (type === "monthly") {
            const today = new Date();
            const daysInMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
            timeProgress = (today.getDate() / daysInMonth) * 100;
        } else {
            const today = new Date();
            const startOfYear = new Date(today.getFullYear(), 0, 1);
            const endOfYear = new Date(today.getFullYear(), 11, 31);
            const daysPassed = Math.floor((today - startOfYear) / (1000 * 60 * 60 * 24));
            const daysInYear = Math.floor((endOfYear - startOfYear) / (1000 * 60 * 60 * 24)) + 1;
            timeProgress = (daysPassed / daysInYear) * 100;
        }
        
        let lastYearPerformance = lastYearGoal ? lastYearGoal.actual_amount : 0;
        
        // 分析目标合理性
        let analysis = "";
        let textColorValue = "black";
        
        if (Math.abs(progressPercentage) < timeProgress * 0.5) {
            analysis = "目标过于激进";
            textColorValue = "#d9534f"; // 红色
        } else if (Math.abs(progressPercentage) > timeProgress * 1.5) {
            analysis = "目标过于保守";
            textColorValue = "#5cb85c"; // 绿色
        } else {
            analysis = "目标设置合理";
            textColorValue = "#5bc0de"; // 蓝色
        }
        
        targetTextElement.text = analysis;
        targetTextElement.color = textColorValue;
    }
    
    // 计算总体统计
    function calculateTotalStatistics() {
        // 获取所有交易数据，用null表示不限日期范围
        var allTransactions = backend.getTransactions(null, null, "", 99999, 0);
        
        let totalProfit = 0;
        let totalLoss = 0;
        let totalNet = 0;
        let totalInvestment = 0;
        
        for (let i = 0; i < allTransactions.length; i++) {
            const profit = allTransactions[i].profit_loss;
            if (profit > 0) {
                totalProfit += profit;
            } else {
                totalLoss += Math.abs(profit);
            }
            totalNet += profit;
            
            // 假设交易金额（amount * unit_price）代表投资金额
            if (allTransactions[i].amount && allTransactions[i].unit_price) {
                totalInvestment += allTransactions[i].amount * allTransactions[i].unit_price;
            }
        }
        
        // 计算投资回报率
        let roi = totalInvestment > 0 ? (totalNet / totalInvestment) * 100 : 0;
        
        // 计算年化收益率
        // 假设第一笔交易的日期作为起始日期
        let annualizedReturn = 0;
        if (allTransactions.length > 0 && totalInvestment > 0) {
            const firstTransaction = allTransactions[allTransactions.length - 1]; // 假设按时间排序，最后一个是最早的
            const startDate = new Date(firstTransaction.date);
            const today = new Date();
            
            // 计算投资时间（以年为单位）
            const yearsInvested = (today - startDate) / (1000 * 60 * 60 * 24 * 365);
            
            if (yearsInvested > 0) {
                // 年化收益率计算公式：(1 + 总收益率)^(1/投资年数) - 1
                annualizedReturn = (Math.pow(1 + (totalNet / totalInvestment), 1 / yearsInvested) - 1) * 100;
            }
        }
        
        // 更新UI
        totalStatsProfit.text = totalProfit.toFixed(2);
        totalStatsLoss.text = totalLoss.toFixed(2);
        totalStatsNet.text = totalNet.toFixed(2);
        totalStatsNetColor.color = totalNet >= 0 ? profitColor : lossColor;
        totalStatsROI.text = roi.toFixed(2) + "%";
        totalStatsAnnualReturn.text = annualizedReturn.toFixed(2) + "%";
        
        // 保存到属性以便其他地方使用
        totalStats = {
            totalProfit: totalProfit,
            totalLoss: totalLoss,
            totalNet: totalNet,
            roi: roi,
            annualizedReturn: annualizedReturn
        };
    }
    
    // 空状态覆盖层
    Rectangle {
        id: emptyStateOverlay
        anchors.fill: parent
        color: Qt.rgba(theme.backgroundColor.r, theme.backgroundColor.g, theme.backgroundColor.b, 0.95) // 设置与背景相近的颜色
        visible: !hasData // 初始根据是否有数据和用户选择来决定可见性
        z: 1 // 确保在内容之上

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width * 0.8 // 控制宽度，确保文本换行
            visible: userSelected // 仅当用户已选择时显示此消息

            Text {
                text: "📊"
                font.pixelSize: 64
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: qsTr("仪表盘暂无数据")
                font.pixelSize: 18
                font.bold: true
                color: theme.textColor
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("尝试添加一些交易记录，或调整筛选条件。")
                font.pixelSize: 14
                color: Qt.darker(theme.textColor, 1.3)
                opacity: 0.8
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        // 未选择用户时显示的提示信息
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width * 0.8 // 控制宽度，确保文本换行
            visible: !userSelected // 仅当用户未选择时显示此消息

            Text {
                text: "👤"
                font.pixelSize: 64
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: qsTr("请先选择或创建一个用户")
                font.pixelSize: 18
                font.bold: true
                color: theme.textColor
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("选择用户后才能查看仪表盘数据")
                font.pixelSize: 14
                color: Qt.darker(theme.textColor, 1.3)
                opacity: 0.8
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
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
                        color: Qt.darker(theme.textColor, 1.2)
                    }
                }
            }
            
            // 总体统计卡片
            Rectangle {
                Layout.fillWidth: true
                height: 140
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
                    spacing: 10
                    
                    Text {
                        text: "投资总览"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 6
                        columnSpacing: 10
                        rowSpacing: 8
                        
                        // 第一行标题
                        Text { 
                            text: "总收益"; 
                            font.pixelSize: 12; 
                            color: Qt.darker(theme.textColor, 1.1);
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            text: "总亏损"; 
                            font.pixelSize: 12; 
                            color: Qt.darker(theme.textColor, 1.1);
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Rectangle {
                            id: totalStatsNetColor
                            Layout.preferredWidth: 4
                            Layout.fillHeight: true
                            color: profitColor
                            radius: 2
                        }
                        Text { 
                            text: "净收益"; 
                            font.pixelSize: 12; 
                            color: Qt.darker(theme.textColor, 1.1);
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            text: "投资回报率"; 
                            font.pixelSize: 12; 
                            color: Qt.darker(theme.textColor, 1.1);
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            text: "年化收益率"; 
                            font.pixelSize: 12; 
                            color: Qt.darker(theme.textColor, 1.1);
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        // 第二行数值
                        Text { 
                            id: totalStatsProfit
                            text: "0.00"; 
                            font.pixelSize: 16; 
                            font.bold: true;
                            color: profitColor;
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            id: totalStatsLoss
                            text: "0.00"; 
                            font.pixelSize: 16; 
                            font.bold: true;
                            color: lossColor;
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item { width: 4; height: 1 } // 占位
                        Text { 
                            id: totalStatsNet
                            text: "0.00"; 
                            font.pixelSize: 16; 
                            font.bold: true;
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            id: totalStatsROI
                            text: "0.00%"; 
                            font.pixelSize: 16; 
                            font.bold: true;
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { 
                            id: totalStatsAnnualReturn
                            text: "0.00%"; 
                            font.pixelSize: 16; 
                            font.bold: true;
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
            
            // 盈亏目标卡片
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 20
                rowSpacing: 20
                
                // 月度目标卡片
                Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 5
                        
                        RowLayout {
                            Layout.fillWidth: true
                        Text {
                            text: "本月盈亏目标"
                            font.pixelSize: 16
                            font.bold: true
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                id: monthlyTargetAnalysisText
                                text: "目标设置合理"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#5bc0de"
                            }
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
                            
                            Text { text: "完成比例:"; font.pixelSize: 14 }
                            Text { 
                                id: monthlyCompletionText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text { text: "同比变化:"; font.pixelSize: 14 }
                            Text { 
                                id: monthlyYoYText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                        
                        // 进度条
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            Layout.topMargin: 8
                            
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, 0.05)
                                radius: 3
                            }
                            
                            Rectangle {
                                id: monthlyProgressBar
                                property real value: 0
                                width: parent.width * value
                                height: parent.height
                                radius: 3
                                
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.lighter(profitColor, 1.1) }
                                    GradientStop { position: 1.0; color: profitColor }
                                }
                                
                                Behavior on width {
                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuad }
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: monthlyCompletionText.text
                                font.bold: true
                                color: monthlyProgressBar.value > 0.5 ? "white" : theme.textColor
                                z: 1
                            }
                        }
                    }
                }
                
                // 年度目标卡片
                Rectangle {
                    Layout.fillWidth: true
                    height: 180
                    radius: 5
                    color: cardColor
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 5
                        
                        RowLayout {
                            Layout.fillWidth: true
                        Text {
                            text: "本年盈亏目标"
                            font.pixelSize: 16
                            font.bold: true
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                id: yearlyTargetAnalysisText
                                text: "目标设置合理"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#5bc0de"
                            }
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
                            
                            Text { text: "完成比例:"; font.pixelSize: 14 }
                            Text { 
                                id: yearlyCompletionText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Text { text: "同比变化:"; font.pixelSize: 14 }
                            Text { 
                                id: yearlyYoYText
                                text: "0.0%"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }
                        
                        // 进度条
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            Layout.topMargin: 8
                            
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, 0.05)
                                radius: 3
                            }
                            
                            Rectangle {
                                id: yearlyProgressBar
                                property real value: 0
                                width: parent.width * value
                                height: parent.height
                                radius: 3
                                
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.lighter(profitColor, 1.1) }
                                    GradientStop { position: 1.0; color: profitColor }
                                }
                                
                                Behavior on width {
                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuad }
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: yearlyCompletionText.text
                                font.bold: true
                                color: yearlyProgressBar.value > 0.5 ? "white" : theme.textColor
                                z: 1
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
                                        color: Qt.darker(theme.textColor, 1.2)
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
                                        color: Qt.darker(theme.textColor, 1.2)
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

    // 监听交易数据变化，自动刷新仪表盘
    Connections {
        target: backend
        function onTransactionsChanged() {
            console.log("Transaction data changed, reloading dashboard...");
            loadData();
        }
    }
}