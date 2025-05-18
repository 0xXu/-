import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Item {
    id: chartView
    
    // 过滤属性
    property string startDateFilter: ""
    property string endDateFilter: ""
    property string assetTypeFilter: "全部"
    property string periodFilter: "monthly" // monthly, weekly, daily
    
    // 数据模型
    ListModel { id: profitLossModel }
    ListModel { id: assetDistributionModel }
    
    property bool hasProfitLossData: false
    property bool hasAssetDistributionData: false

    // 当视图被加载时获取数据
    Component.onCompleted: {
        if (userSelected) {
            loadChartData();
        } else {
            // 初始空状态，如果未选择用户
            emptyStateOverlay.visible = true;
            chartContent.visible = false;
        }
    }

    Timer {
        id: initialLoadTimer
        interval: 50
        running: !userSelected && (!hasProfitLossData || !hasAssetDistributionData)
        repeat: false
        onTriggered: {
            if (!userSelected) {
                emptyStateOverlay.visible = true;
                chartContent.visible = false;
            }
        }
    }
    
    function loadChartData() {
        if (!userSelected) {
            hasProfitLossData = false;
            hasAssetDistributionData = false;
            emptyStateOverlay.visible = true;
            chartContent.visible = false;
            return;
        }
        // 加载盈亏趋势数据
        loadProfitLossTrend();
        
        // 加载资产分布数据
        loadAssetDistribution();

        // 更新整体空状态
        updateEmptyStateVisibility();
    }
    
    function loadProfitLossTrend() {
        // 如果未选择用户，不加载数据
        if (!userSelected) return;
        
        var data = backend.getProfitLossSummary(
            periodFilter,
            startDateFilter,
            endDateFilter
        );
        
        // 清空现有数据
        profitLossModel.clear();
        
        // 如果没有数据，添加默认值以显示图表
        if (data.length === 0) {
            var defaultMonths = ["1月", "2月", "3月", "4月", "5月", "6月"];
            for (var j = 0; j < defaultMonths.length; j++) {
                profitLossModel.append({
                    period: defaultMonths[j],
                    profit: 0,
                    loss: 0,
                    net: 0
                });
            }
            return;
        }
        
        // 添加数据
        for (var i = 0; i < data.length; i++) {
            profitLossModel.append({
                period: data[i].period,
                profit: data[i].total_profit,
                loss: Math.abs(data[i].total_loss),
                net: data[i].net_profit_loss
            });
        }
        
        // 更新趋势图表
        updateProfitLossChart();
        hasProfitLossData = profitLossModel.count > 0 && !(profitLossModel.count === 6 && profitLossModel.get(0).profit === 0 && profitLossModel.get(0).loss === 0); // 检查是否为真实数据而非默认填充
        updateEmptyStateVisibility();
    }
    
    function loadAssetDistribution() {
        // 如果未选择用户，不加载数据
        if (!userSelected) return;
        
        var distribution = backend.getAssetTypeDistribution(
            startDateFilter,
            endDateFilter
        );
        
        // 清空现有数据
        assetDistributionModel.clear();
        
        // 如果没有数据，添加默认值以显示图表
        if (distribution.length === 0) {
            var defaultTypes = ["股票", "基金", "债券", "外汇", "其他"];
            for (var j = 0; j < defaultTypes.length; j++) {
                assetDistributionModel.append({
                    asset_type: defaultTypes[j],
                    count: 0,
                    total_amount: 0,
                    percentage: 20
                });
            }
            return;
        }
        
        // 添加数据
        for (var i = 0; i < distribution.length; i++) {
            assetDistributionModel.append({
                asset_type: distribution[i].asset_type,
                count: distribution[i].count,
                total_amount: distribution[i].total_amount,
                percentage: distribution[i].percentage
            });
        }
        
        // 更新饼图
        updateAssetDistributionChart();
        hasAssetDistributionData = assetDistributionModel.count > 0 && !(assetDistributionModel.count === 5 && assetDistributionModel.get(0).count === 0 ); // 检查是否为真实数据而非默认填充
        updateEmptyStateVisibility();
    }
    
    function updateProfitLossChart() {
        // 更新柱状图
        profitSeries.clear();
        lossSeries.clear();
        netSeries.clear();
        
        var categories = [];
        var maxValue = 0;
        
        for (var i = 0; i < profitLossModel.count; i++) {
            var item = profitLossModel.get(i);
            categories.push(item.period);
            
            profitSeries.append(i, item.profit);
            lossSeries.append(i, -item.loss);  // 使用负值表示亏损
            netSeries.append(i, item.net);
            
            // 计算最大值以调整轴范围
            maxValue = Math.max(maxValue, item.profit, item.loss, Math.abs(item.net));
        }
        
        // 更新坐标轴
        profitLossAxisX.categories = categories;
        profitLossAxisY.max = maxValue * 1.2;
        profitLossAxisY.min = -maxValue * 1.2;
    }
    
    function updateAssetDistributionChart() {
        // 清除现有系列
        if (distributionPieSeries.count > 0) {
            for (var i = distributionPieSeries.count - 1; i >= 0; i--) {
                distributionPieSeries.remove(distributionPieSeries.at(i));
            }
        }
        
        // 添加新系列
        for (var j = 0; j < assetDistributionModel.count; j++) {
            var item = assetDistributionModel.get(j);
            var slice = distributionPieSeries.append(item.asset_type, item.percentage);
            
            // 根据资产类型设置不同颜色
            var colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"];
            slice.color = colors[j % colors.length];
            
            // 显示标签
            slice.labelVisible = true;
            slice.labelPosition = PieSlice.LabelOutside;
            slice.labelArmLengthFactor = 0.15;
            slice.exploded = true;
            slice.explodeDistanceFactor = 0.05;
        }
    }
    
    // 空状态覆盖层
    Rectangle {
        id: emptyStateOverlay
        anchors.fill: parent
        color: Qt.rgba(0,0,0,0.02)
        visible: (!hasProfitLossData && !hasAssetDistributionData) || !userSelected
        z: 1 // 在内容之上

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15

            Image {
                source: "qrc:/icons/empty-chart.svg" // 假设有空图表图标
                Layout.alignment: Qt.AlignHCenter
                width: 128
                height: 128
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: !userSelected ? qsTr("请先选择用户以查看图表统计。") : qsTr("图表暂无数据")
                font.pixelSize: 18
                color: Qt.darker(theme.textColor, 1.3)
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                visible: userSelected && (!hasProfitLossData && !hasAssetDistributionData)
                text: qsTr("尝试添加一些交易记录或调整筛选条件以生成图表。")
                font.pixelSize: 14
                color: Qt.darker(theme.textColor, 1.5)
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    ScrollView {
        id: chartContent
        anchors.fill: parent
        clip: true
        visible: (hasProfitLossData || hasAssetDistributionData) && userSelected
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        
        ColumnLayout {
            width: chartView.width - 30
            spacing: 20
            
            // 过滤器
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: cardColor
                radius: 5
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    // 起始日期过滤
                    ColumnLayout {
                        Layout.preferredWidth: 120
                        spacing: 2
                        
                        Text {
                            text: "起始日期"
                            font.pixelSize: 12
                        }
                        
                        TextField {
                            id: startDateField
                            placeholderText: "YYYY-MM-DD"
                            Layout.fillWidth: true
                            text: startDateFilter
                            
                            onEditingFinished: {
                                startDateFilter = text;
                                loadChartData();
                            }
                        }
                    }
                    
                    // 结束日期过滤
                    ColumnLayout {
                        Layout.preferredWidth: 120
                        spacing: 2
                        
                        Text {
                            text: "结束日期"
                            font.pixelSize: 12
                        }
                        
                        TextField {
                            id: endDateField
                            placeholderText: "YYYY-MM-DD"
                            Layout.fillWidth: true
                            text: endDateFilter
                            
                            onEditingFinished: {
                                endDateFilter = text;
                                loadChartData();
                            }
                        }
                    }
                    
                    // 时间周期过滤
                    ColumnLayout {
                        Layout.preferredWidth: 100
                        spacing: 2
                        
                        Text {
                            text: "时间周期"
                            font.pixelSize: 12
                        }
                        
                        ComboBox {
                            id: periodComboBox
                            Layout.fillWidth: true
                            model: [
                                { text: "按月", value: "monthly" },
                                { text: "按周", value: "weekly" },
                                { text: "按日", value: "daily" }
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                            
                            onActivated: {
                                periodFilter = model[currentIndex].value;
                                loadChartData();
                            }
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        text: "刷新数据"
                        onClicked: loadChartData()
                    }
                }
            }
            
            // 盈亏趋势图
            Rectangle {
                Layout.fillWidth: true
                height: 350
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    
                    Text {
                        text: "盈亏趋势"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    ChartView {
                        id: profitLossChartView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        antialiasing: true
                        legend.visible: true
                        legend.alignment: Qt.AlignBottom
                        animationOptions: ChartView.SeriesAnimations
                        
                        BarSeries {
                            id: profitSeries
                            name: "盈利"
                            axisX: profitLossAxisX
                            axisY: profitLossAxisY
                            barWidth: 0.3
                        }
                        
                        BarSeries {
                            id: lossSeries
                            name: "亏损"
                            axisX: profitLossAxisX
                            axisY: profitLossAxisY
                            barWidth: 0.3
                        }
                        
                        LineSeries {
                            id: netSeries
                            name: "净盈亏"
                            axisX: profitLossAxisX
                            axisY: profitLossAxisY
                            width: 2
                            color: "black"
                        }
                        
                        BarCategoryAxis {
                            id: profitLossAxisX
                            categories: ["1月", "2月", "3月", "4月", "5月", "6月"]
                        }
                        
                        ValueAxis {
                            id: profitLossAxisY
                            min: -1000
                            max: 1000
                        }
                    }
                }
            }
            
            // 资产分布图
            Rectangle {
                Layout.fillWidth: true
                height: 350
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    
                    Text {
                        text: "资产分布"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    ChartView {
                        id: distributionChartView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        antialiasing: true
                        legend.visible: true
                        legend.alignment: Qt.AlignRight
                        animationOptions: ChartView.SeriesAnimations
                        
                        PieSeries {
                            id: distributionPieSeries
                            size: 0.9
                        }
                    }
                }
            }
            
            // 目标达成情况
            Rectangle {
                Layout.fillWidth: true
                height: 150
                color: cardColor
                radius: 5
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    
                    Text {
                        text: "目标达成情况"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    
                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // 月度目标
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 5
                            
                            Text {
                                text: "月度目标"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            ProgressBar {
                                id: monthlyGoalProgress
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: 35
                            }
                            
                            Text {
                                text: "¥ 350.00 / ¥ 1,000.00 (35%)"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                        
                        // 年度目标
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 5
                            
                            Text {
                                text: "年度目标"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            ProgressBar {
                                id: yearlyGoalProgress
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: 28
                            }
                            
                            Text {
                                text: "¥ 3,350.00 / ¥ 12,000.00 (28%)"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 全局信号处理
    Connections {
        target: backend
        
        function onTransactionsChanged() {
            loadChartData();
        }
    }

    function updateEmptyStateVisibility() {
        var chartsHaveData = hasProfitLossData || hasAssetDistributionData;
        emptyStateOverlay.visible = !chartsHaveData || !userSelected;
        chartContent.visible = chartsHaveData && userSelected;
    }
}