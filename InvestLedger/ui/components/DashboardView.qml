import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Item {
    id: dashboardView
    
    property bool hasData: false // 用于跟踪是否有数据
    property var totalStats: ({}) // 总体统计数据
    property bool userSelected: mainWindow ? mainWindow.userSelected : false // 绑定到主窗口的userSelected属性

    // 添加格式化大数字的函数
    function formatLargeNumber(value) {
        if (value === undefined || value === null) return "0.00";
        
        // 转换为数字确保格式化正确
        let num = Number(value);
        
        // 检查是否为有效数字
        if (isNaN(num)) return "0.00";
        
        // 格式化逻辑：大于1百万显示为x.xx M，大于1千显示为x.xx K
        if (Math.abs(num) >= 1000000) {
            return (num / 1000000).toFixed(2) + " M";
        } else if (Math.abs(num) >= 1000) {
            return (num / 1000).toFixed(2) + " K";
        } else {
            return num.toFixed(2);
        }
    }

    // 当视图被加载时获取数据
    Component.onCompleted: {
        loadData();
        
        // 添加延迟重新加载计时器，而不是使用setTimeout
        secondLoadTimer.start();
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
    
    // 添加数据刷新定时器
    Timer {
        id: refreshTimer
        interval: 2000 // 2秒后检查数据
        running: true
        repeat: false
        onTriggered: {
            if (!hasData && backend.getCurrentUserSelected()) {
                console.log("刷新计时器触发数据加载");
                loadData();
            }
        }
    }
    
    // 二次加载计时器
    Timer {
        id: secondLoadTimer
        interval: 1000  // 延迟1秒
        repeat: false
        onTriggered: {
            if (!hasData && backend.getCurrentUserSelected()) {
                console.log("尝试二次加载仪表盘数据...");
                loadData();
            }
        }
    }
    
    function loadData() {
        console.log("开始加载仪表盘数据...");
        
        // 修改为强制检查外部用户选择状态
        var externalUserSelected = true; // 假设外部状态为选择了用户
        try {
            // 尝试访问main.qml中的userSelected属性
            externalUserSelected = backend.getCurrentUserSelected();
            console.log("外部用户选择状态: " + externalUserSelected);
        } catch (e) {
            console.error("获取外部用户选择状态失败: " + e);
        }
        
        // 使用本地状态和外部状态的组合决定
        if (!userSelected && !externalUserSelected) {
            console.log("未选择用户，显示空状态");
            hasData = false;
            emptyStateOverlay.visible = true;
            dashboardContent.visible = false;
            return;
        }
        
        try {
            // 获取当前日期
            var today = new Date();
            var year = today.getFullYear();
            var month = today.getMonth() + 1;
            var lastYear = year - 1;
            
            console.log("获取月度和年度目标数据");
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
            
            // 先计算总体统计，确保在任何情况下都会执行
            console.log("计算总体统计数据");
            calculateTotalStatistics();
            
            console.log("加载趋势和项目数据");
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

            console.log("检查交易数据");
            // 检查是否有有效数据 - 有任何数据就显示
            hasData = topProfitModel.count > 0 || topLossModel.count > 0 || trendData.length > 0 || totalStats.totalTrades > 0;
            
            console.log("Dashboard data check: profit projects=" + topProfitModel.count + 
                        ", loss projects=" + topLossModel.count + 
                        ", trends=" + trendData.length +
                        ", total trades=" + (totalStats.totalTrades || 0));
            console.log("仪表盘有数据: " + hasData);
            
            // 强制刷新状态显示
            emptyStateOverlay.visible = !hasData;
            dashboardContent.visible = hasData;
            
        } catch (e) {
            console.error("加载仪表盘数据失败: " + e);
            // 出错时显示空状态
            hasData = false;
            emptyStateOverlay.visible = true;
            dashboardContent.visible = false;
        }
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
        try {
            // 获取所有交易数据，用null表示不限日期范围
            var allTransactions = backend.getTransactions(null, null, "", 99999, 0);
            
            let totalProfit = 0;
            let totalLoss = 0;
            let totalNet = 0;
            let totalInvestment = 0;
            let winningTrades = 0;
            let losingTrades = 0;
            let totalTrades = allTransactions.length;
            
            for (let i = 0; i < allTransactions.length; i++) {
                const profit = allTransactions[i].profit_loss;
                if (profit > 0) {
                    totalProfit += profit;
                    winningTrades++;
                } else if (profit < 0) {
                    totalLoss += Math.abs(profit);
                    losingTrades++;
                }
                totalNet += profit;
                
                // 假设交易金额（amount * unit_price）代表投资金额
                if (allTransactions[i].amount && allTransactions[i].unit_price) {
                    totalInvestment += allTransactions[i].amount * allTransactions[i].unit_price;
                }
            }
            
            // 计算胜率和盈亏比
            const winRate = (winningTrades + losingTrades > 0) ? (winningTrades / (winningTrades + losingTrades) * 100) : 0;
            const profitLossRatio = (losingTrades > 0 && totalLoss > 0) ? (totalProfit / winningTrades) / (totalLoss / losingTrades) : 0;
            
            // 计算其他指标
            const roi = (totalInvestment > 0) ? (totalNet / totalInvestment * 100) : 0;
            
            // 更新界面显示 - 收益亏损
            if (totalStatsProfitValue) totalStatsProfitValue.text = formatLargeNumber(totalProfit);
            if (totalStatsLossValue) totalStatsLossValue.text = formatLargeNumber(totalLoss);
            if (totalStatsNetValue) totalStatsNetValue.text = formatLargeNumber(totalNet);
            
            // 更新胜率和盈亏比
            if (totalStatsWinRateValue) totalStatsWinRateValue.text = winRate.toFixed(1) + "%";
            if (totalStatsPLRatioValue) totalStatsPLRatioValue.text = profitLossRatio.toFixed(2);
            
            // 更新ROI
            if (totalStatsROIValue) totalStatsROIValue.text = roi.toFixed(2) + "%";
            
            // 更新交易统计
            if (totalTradesCountValue) totalTradesCountValue.text = totalTrades.toString();
            if (winningTradesCountValue) winningTradesCountValue.text = winningTrades.toString();
            if (losingTradesCountValue) losingTradesCountValue.text = losingTrades.toString();
            
            // 设置颜色
            if (totalStatsNetValue) totalStatsNetValue.color = totalNet >= 0 ? profitColor : lossColor;
            if (totalStatsROIValue) totalStatsROIValue.color = roi >= 0 ? profitColor : lossColor;
            
            // 设置净收益条的颜色
            if (totalStatsNetColor) {
                totalStatsNetColor.color = totalNet >= 0 ? profitColor : lossColor;
            }
            
            totalStats = {
                net: totalNet,
                profit: totalProfit,
                loss: totalLoss,
                winRate: winRate,
                plRatio: profitLossRatio,
                roi: roi,
                totalTrades: totalTrades,
                winningTrades: winningTrades,
                losingTrades: losingTrades
            };
        } catch (e) {
            console.error("计算总体统计失败: " + e);
        }
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
                        columns: 3 // 调整为3列布局
                        rowSpacing: 15
                        columnSpacing: 20
                        
                        // 第一列：总收益和总亏损
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            // 总收益
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsProfitLabel
                                    text: "总收益"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsProfitValue
                                    text: "0.00"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: profitColor
                                }
                            }
                            
                            // 总亏损
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsLossLabel
                                    text: "总亏损"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsLossValue
                                    text: "0.00"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: lossColor
                                }
                            }
                            
                            // 胜率
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsWinRateLabel
                                    text: "胜率"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsWinRateValue
                                    text: "0.0%"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: theme.textColor
                                }
                            }
                        }
                        
                        // 第二列：净收益和ROI
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            // 净收益
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsNetLabel
                                    text: "净收益"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsNetValue
                                    text: "0.00"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: theme.textColor
                                }
                            }
                            
                            // ROI
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsROILabel
                                    text: "ROI"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsROIValue
                                    text: "0.00%"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: theme.textColor
                                }
                            }
                            
                            // 盈亏比
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    id: totalStatsPLRatioLabel
                                    text: "盈亏比"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalStatsPLRatioValue
                                    text: "0.00"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: theme.textColor
                                }
                            }
                        }
                        
                        // 第三列：交易统计
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            // 总交易
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "总交易笔数"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: totalTradesCountValue
                                    text: "0"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: theme.textColor
                                }
                            }
                            
                            // 盈利交易
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "盈利交易"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: winningTradesCountValue
                                    text: "0"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: profitColor
                                }
                            }
                            
                            // 亏损交易
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "亏损交易"
                                    font.pixelSize: 14
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    id: losingTradesCountValue
                                    text: "0"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: lossColor
                                }
                            }
                        }
                        
                        // 净收益色条 - 占据所有列
                        Rectangle {
                            id: totalStatsNetColor
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            height: 4
                            color: theme.primaryColor
                            radius: 2
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
                                width: parent ? parent.width : 0
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
                                width: parent ? parent.width : 0
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
            // 使用计时器延迟加载数据，而不是使用setTimeout
            delayedReloadTimer.start();
        }
    }
    
    // 延迟加载计时器
    Timer {
        id: delayedReloadTimer
        interval: 300  // 延迟300毫秒
        repeat: false
        onTriggered: {
            loadData();
        }
    }
}