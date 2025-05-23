import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebView 1.1  // 使用WebView来加载Plotly

// 避免直接导入QtCharts模块
Item {
    id: chartView
    
    // 基本属性
    property bool isLoading: false
    property bool hasError: false
    property string errorMessage: ""
    
    // 初始化
    Component.onCompleted: {
        console.log("ChartView: Plotly图表视图已初始化")
    }
    
    // 开始加载数据（从主窗口调用）
    function startLoading() {
        console.log("ChartView: 开始加载图表数据")
        
        if (isLoading) {
            console.log("ChartView: 已经在加载中，忽略")
            return
        }
        
        try {
            // 设置状态
            isLoading = true
            hasError = false
            errorMessage = ""
            
            // 显示加载指示器
            loadingIndicator.visible = true
            chartContainer.visible = false
            emptyView.visible = false
            
            // 延迟执行加载操作，允许UI更新
            loadTimer.restart()
        } catch (e) {
            console.error("ChartView: 启动加载过程出错:", e)
            setError("启动加载过程出错: " + e)
        }
    }
    
    // 加载定时器
    Timer {
        id: loadTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            loadChartData()
        }
    }
    
    // 加载图表数据
    function loadChartData() {
        try {
            console.log("ChartView: 加载图表数据")
            
            // 生成样本数据
            var profitLossData = generateProfitLossData()
            var assetDistributionData = generateAssetDistributionData()
            
            // 将数据转换为JSON字符串
            var plotlyData = {
                profitLoss: profitLossData,
                assetDistribution: assetDistributionData
            }
            
            // 传递数据给WebView
            var dataJson = JSON.stringify(plotlyData)
            var js = "updateCharts(" + dataJson + ");"
            webView.runJavaScript(js)
            
            // 完成加载
            chartContainer.visible = true
            isLoading = false
            loadingIndicator.visible = false
            
        } catch (e) {
            console.error("ChartView: 加载图表数据出错:", e)
            setError("加载图表数据时出错: " + e)
        }
    }
    
    // 生成盈亏数据
    function generateProfitLossData() {
        var months = ["1月", "2月", "3月", "4月", "5月", "6月"]
        var profits = []
        var losses = []
        var netValues = []
        
        for (var i = 0; i < months.length; i++) {
            var profit = Math.random() * 1000
            var loss = Math.random() * 500
            
            profits.push(profit)
            losses.push(loss)
            netValues.push(profit - loss)
        }
        
        return {
            months: months,
            profits: profits,
            losses: losses,
            netValues: netValues
        }
    }
    
    // 生成资产分布数据
    function generateAssetDistributionData() {
        var assetTypes = ["股票", "基金", "债券", "外汇", "其他"]
        var percentages = []
        var totalPercentage = 0
        
        for (var i = 0; i < assetTypes.length - 1; i++) {
            var percentage = Math.floor(Math.random() * (100 - totalPercentage) / 2)
            percentages.push(percentage)
            totalPercentage += percentage
        }
        
        // 最后一项占余下的百分比
        percentages.push(100 - totalPercentage)
        
        return {
            types: assetTypes,
            percentages: percentages
        }
    }
    
    // 设置错误状态
    function setError(message) {
        console.error("ChartView错误: " + message)
        errorMessage = message
        hasError = true
        isLoading = false
        
        loadingIndicator.visible = false
        chartContainer.visible = false
        emptyView.visible = true
    }
    
    // 主布局
    ScrollView {
        id: chartScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        
        ColumnLayout {
            width: chartScrollView.width
            spacing: 20
            
            // 图表容器
            Item {
                id: chartContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 700
                visible: !isLoading && !hasError
                
                // 使用WebView加载Plotly图表
                WebView {
                    id: webView
                    anchors.fill: parent
                    url: "qrc:/html/charts.html"  // 加载包含Plotly的HTML页面
                    
                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebView.LoadSucceededStatus) {
                            console.log("WebView加载成功，准备显示图表")
                            
                            // 在加载完成后直接加载数据
                            if (chartContainer.visible) {
                                var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: 500; repeat: false; running: true; }', chartView);
                                timer.triggered.connect(function() {
                                    loadChartData();
                                });
                            }
                        } else if (loadRequest.status === WebView.LoadFailedStatus) {
                            console.error("WebView加载失败:", loadRequest.errorString)
                            setError("加载图表页面失败: " + loadRequest.errorString)
                        }
                    }
                }
            }
        }
    }
    
    // 加载指示器
    Rectangle {
        id: loadingIndicator
        anchors.fill: parent
        color: "#f5f5f5"
        visible: isLoading
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            BusyIndicator {
                width: 80
                height: 80
                anchors.horizontalCenter: parent.horizontalCenter
                running: loadingIndicator.visible
            }
            
            Text {
                text: "正在加载图表数据..."
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // 空或错误状态视图
    Rectangle {
        id: emptyView
        anchors.fill: parent
        color: "#f5f5f5"
        visible: !isLoading && hasError
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.8
            
            Text {
                text: "📊"
                font.pixelSize: 72
                color: hasError ? "#e74c3c" : "#7f8c8d" 
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: hasError ? "加载图表时出错" : "图表数据暂时不可用"
                font.pixelSize: 20
                font.bold: true
                color: hasError ? "#e74c3c" : "#2c3e50"
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }
            
            Text {
                text: hasError ? errorMessage : "请确保已安装WebView模块，并添加一些交易数据"
                font.pixelSize: 16
                color: "#7f8c8d"
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: parent.width
            }
            
            Button {
                text: "重试"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: startLoading()
            }
        }
    }
}