import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebEngine 1.8
import QtWebChannel 1.0

// 避免直接导入QtCharts模块
Item {
    id: chartView
    
    // 当ChartView的可见性发生变化时触发
    onVisibleChanged: {
        if (visible) {
            console.log("ChartView: 视图变为可见，设置加载状态。");
            
            // 停止任何正在进行的操作
            loadTimer.stop();
            
            // 重置状态
            isLoading = true;       // 进入加载状态
            hasError = false;
            errorMessage = "";

            loadingIndicator.visible = true; // 显示加载动画
            // 不在这里设置 chartContainer.visible = false，以避免与 chartsRendered 冲突
            emptyView.visible = false;    // 隐藏错误/空状态视图
            
            if (webViewInitialized) {
                // 如果WebView已经初始化，无需重新加载，直接触发数据加载
                console.log("ChartView: WebView已初始化，直接触发数据加载。");
                loadTimer.restart(); // 使用定时器加载数据，允许UI更新
            } else {
                console.log("ChartView: 首次加载，重载WebView。");
                // 首次加载时，重载WebView (pageLoaded会在WebView加载完成后被调用，然后触发loadChartData)
                webView.reload(); 
                webViewInitialized = true;
            }
        } else {
            console.log("ChartView: 视图变为隐藏。");
            // 如果有活动的定时器或操作，可以在这里停止它们
            loadTimer.stop();
            // 注意：即使隐藏视图，我们也不重置图表状态，这样在再次显示时可以快速显示旧数据
        }
    }
    
    // 控制WebView初始化状态的标志
    property bool webViewInitialized: false
    
    property int reportedHtmlHeight: 600 // Default initial height
    
    // 基本属性
    property bool isLoading: false
    property bool hasError: false
    property string errorMessage: ""
    
    // 公开给JavaScript的函数 
    function pageLoaded() {
        console.log("ChartView QML: pageLoaded() 被JS调用，表明WebView和WebChannel已就绪。");
        // WebView已加载，WebChannel已准备好，现在可以安全地启动数据加载流程
        if (visible && isLoading) { // 只在视图可见且处于加载状态时触发加载
            loadTimer.restart(); // 触发 loadChartData
        } else {
            console.log("ChartView QML: pageLoaded() 被调用，但视图不可见或不在加载状态。等待视图变为可见。");
        }
    }
    
    // Function called by JavaScript to set the content height
    function setHtmlContentHeight(newHeight) {
        console.log("QML: Received HTML content height:", newHeight);
        if (reportedHtmlHeight !== newHeight && newHeight > 0) {
            reportedHtmlHeight = newHeight;
        }
    }
    
    // NEW function: Called by JavaScript after Plotly charts are fully rendered
    function chartsRendered() {
        console.log("ChartView QML: chartsRendered() called from JS. Charts should be ready.");
        
        // 先将状态设为非加载中
        isLoading = false;
        loadingIndicator.visible = false;
        
        // 设置图表容器为可见 (确保在状态变更后执行)
        chartContainer.visible = true;
        
        console.log("ChartView QML: 设置 chartContainer.visible = true");
        // 使用定时器在下一帧再次确认可见状态
        Qt.callLater(function() {
            if (!chartContainer.visible) {
                console.log("ChartView QML: 警告! chartContainer仍然不可见，强制设置为可见");
                chartContainer.visible = true;
            }
            console.log("ChartView QML: chartContainer visible:", chartContainer.visible, 
                       "width:", chartContainer.width, "height:", chartContainer.height);
            console.log("ChartView QML: webView width:", webView.width, 
                       "height:", webView.height, "url:", webView.url);
        });
    }
    
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
            // 不在这里设置 chartContainer.visible = false，以避免与 chartsRendered 冲突
            emptyView.visible = false
            
            // 如果WebView已初始化，直接加载数据；否则，WebView的onLoadingChanged会触发pageLoaded
            if (webViewInitialized) {
                // 延迟执行加载操作，允许UI更新
                loadTimer.restart()
            } else {
                // 首次加载时，重载WebView
                webView.reload()
                webViewInitialized = true
            }
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
            console.log("ChartView: 从数据库加载图表数据")
            
            // 获取数据 - 从后端获取实际数据
            var chartData = {
                profitLoss: loadProfitLossData(),
                stockRanking: loadStockRankingData(),
                monthlyVolume: loadMonthlyVolumeData(),
                winLossRatio: loadWinLossRatioData()
            }
            
            // 检查是否有数据
            if (!chartData.profitLoss.months || chartData.profitLoss.months.length === 0) {
                console.log("ChartView: 图表数据为空");
                setError("没有可用的数据来生成图表。请添加一些交易记录后再试。");
                return;
            }
            
            // 将数据转换为JSON字符串
            var dataJson = JSON.stringify(chartData)
            
            // 使用 WebEngine 的 runJavaScript 方法
            // updateCharts 函数现在应该在它完成绘图后调用 chartView.chartsRendered()
            var js = "if (typeof updateCharts === 'function') { updateCharts(" + dataJson + "); console.log('图表更新函数命令已发送'); } else { console.error('updateCharts 函数未找到'); }";
            
            webView.runJavaScript(js, function(result) {
                console.log("JS snippet for updateCharts executed, result (if any):", result);
                // Actual chart visibility and loading state are now handled by chartsRendered()
                // when called back from JavaScript after Plotly rendering.
                // If 'result' contains an error message, it might indicate an immediate problem
                // with the JS snippet itself, though async errors in updateCharts won't show here.
            });
            
        } catch (e) {
            console.error("ChartView: 加载图表数据出错:", e)
            setError("加载图表数据时出错: " + e)
        }
    }
    
    // 加载盈亏趋势数据 - 从后端获取
    function loadProfitLossData() {
        console.log("加载盈亏趋势数据")
        
        try {
            // 获取过去12个月的数据
            var monthlyData = backend.getMonthlyProfitLossLastYear()
            
            // 处理数据
            var months = []
        var profits = []
        var losses = []
        var netValues = []
        
            for (var i = 0; i < monthlyData.length; i++) {
                var item = monthlyData[i]
                // 提取月份信息
                var yearMonth = item.month.split("-")
                var monthLabel = yearMonth[0] + "年" + parseInt(yearMonth[1]) + "月"
                months.push(monthLabel)
                
                // 计算盈亏
                var profitLoss = item.profitLoss
                if (profitLoss > 0) {
                    profits.push(profitLoss)
                    losses.push(0)
                } else {
                    profits.push(0)
                    losses.push(Math.abs(profitLoss))
                }
                netValues.push(profitLoss)
        }
        
        return {
            months: months,
            profits: profits,
            losses: losses,
            netValues: netValues
        }
        } catch (e) {
            console.error("加载盈亏趋势数据出错:", e)
            return { months: [], profits: [], losses: [], netValues: [] }
        }
    }
    
    // 加载个股盈亏排名数据
    function loadStockRankingData() {
        console.log("加载个股盈亏排名数据")
        
        try {
            // 获取盈利最多的项目（取前5名）
            var topProfit = backend.getTopProjects(5, true, null, null)
            
            // 获取亏损最多的项目（取前3名）
            var topLoss = backend.getTopProjects(3, false, null, null)
            
            var stocks = []
            var values = []
            
            // 添加盈利项目
            for (var i = 0; i < topProfit.length; i++) {
                stocks.push(topProfit[i].project_name)
                values.push(topProfit[i].total_profit_loss)
            }
            
            // 添加亏损项目
            for (var j = 0; j < topLoss.length; j++) {
                stocks.push(topLoss[j].project_name)
                values.push(topLoss[j].total_profit_loss) // 亏损已经是负值
            }
            
            return {
                stocks: stocks,
                values: values
            }
        } catch (e) {
            console.error("加载个股盈亏排名数据出错:", e)
            return { stocks: [], values: [] }
        }
    }
    
    // 加载月度交易量数据
    function loadMonthlyVolumeData() {
        console.log("加载月度交易量数据")
        
        try {
            // 获取过去12个月的数据
            var today = new Date()
            var months = []
            var volumes = []
            
            // 获取最近半年的月份
            for (var i = 5; i >= 0; i--) {
                var month = today.getMonth() - i
                var year = today.getFullYear()
                
                // 处理月份为负的情况
                if (month < 0) {
                    month += 12
                    year -= 1
                }
                
                // 格式化日期为YYYY-MM-DD
                var startDate = year + "-" + String(month + 1).padStart(2, '0') + "-01"
                
                // 计算月末日期
                var endMonth = month + 1
                var endYear = year
                if (endMonth > 11) {
                    endMonth = 0
                    endYear += 1
                }
                
                var lastDay = new Date(endYear, endMonth, 0).getDate()
                var endDate = year + "-" + String(month + 1).padStart(2, '0') + "-" + String(lastDay).padStart(2, '0')
                
                // 获取该月交易数量
                var transactions = backend.getTransactions(startDate, endDate, "", 999, 0)
                var monthLabel = year + "年" + (month + 1) + "月"
                
                months.push(monthLabel)
                volumes.push(transactions.length)
            }
            
            return {
                months: months,
                volumes: volumes
            }
        } catch (e) {
            console.error("加载月度交易量数据出错:", e)
            return { months: [], volumes: [] }
        }
    }
    
    // 加载盈亏比率趋势数据
    function loadWinLossRatioData() {
        console.log("加载盈亏比率趋势数据")
        
        try {
            // 获取过去6个月的数据
            var today = new Date()
            var months = []
            var winRates = []
            var profitLossRatios = []
            
            // 获取最近半年的月份
            for (var i = 5; i >= 0; i--) {
                var month = today.getMonth() - i
                var year = today.getFullYear()
                
                // 处理月份为负的情况
                if (month < 0) {
                    month += 12
                    year -= 1
                }
                
                // 格式化日期为YYYY-MM-DD
                var startDate = year + "-" + String(month + 1).padStart(2, '0') + "-01"
                
                // 计算月末日期
                var endMonth = month + 1
                var endYear = year
                if (endMonth > 11) {
                    endMonth = 0
                    endYear += 1
                }
                
                var lastDay = new Date(endYear, endMonth, 0).getDate()
                var endDate = year + "-" + String(month + 1).padStart(2, '0') + "-" + String(lastDay).padStart(2, '0')
                
                // 获取该月交易数据
                var transactions = backend.getTransactions(startDate, endDate, "", 999, 0)
                var monthLabel = year + "年" + (month + 1) + "月"
                
                // 计算胜率和盈亏比
                var winCount = 0
                var lossCount = 0
                var totalProfit = 0
                var totalLoss = 0
                
                for (var j = 0; j < transactions.length; j++) {
                    var profit = transactions[j].profit_loss
                    if (profit > 0) {
                        winCount++
                        totalProfit += profit
                    } else if (profit < 0) {
                        lossCount++
                        totalLoss += Math.abs(profit)
                    }
                }
                
                // 计算胜率
                var winRate = 0
                if (winCount + lossCount > 0) {
                    winRate = (winCount / (winCount + lossCount)) * 100
        }
        
                // 计算盈亏比
                var profitLossRatio = 0
                if (lossCount > 0 && totalLoss > 0 && winCount > 0) {
                    profitLossRatio = (totalProfit / winCount) / (totalLoss / lossCount)
                }
                
                months.push(monthLabel)
                winRates.push(parseFloat(winRate.toFixed(1)))
                profitLossRatios.push(parseFloat(profitLossRatio.toFixed(2)))
            }
        
        return {
                months: months,
                winRates: winRates,
                profitLossRatios: profitLossRatios
            }
        } catch (e) {
            console.error("加载盈亏比率趋势数据出错:", e)
            return { months: [], winRates: [], profitLossRatios: [] }
        }
    }
    
    // 设置错误状态
    function setError(message) {
        console.error("ChartView错误: " + message)
        errorMessage = message
        hasError = true
        isLoading = false
        
        loadingIndicator.visible = false
        // 只在必要时隐藏图表容器，如果已经有图表数据则不隐藏
        if (message.includes("没有可用的数据") || !chartContainer.visible) {
            chartContainer.visible = false
            emptyView.visible = true
        } else {
            // 如果是其他错误，但图表已经显示，则保留图表但也显示错误视图
            emptyView.visible = true
        }
    }
    
    // 主布局
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: "#f5f5f5"
        
        Flickable {
            id: chartFlickable
            anchors.fill: parent
            contentWidth: width
            contentHeight: chartsColumn.height
            clip: true
            
            // 启用滚动条
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: 12
                active: true
            }
        
            Column {
                id: chartsColumn
                width: chartFlickable.width - 15 // 减去滚动条宽度
            spacing: 20
            
            // 图表容器
                Rectangle {
                id: chartContainer
                    width: parent.width
                    height: chartView.reportedHtmlHeight // Bind to the reported height
                    color: "white"
                    visible: false // 初始设置为不可见，由chartsRendered函数控制
                    radius: 4
                    
                    // WebChannel设置
                    WebChannel {
                        id: webChannel
                        
                        // 注册当前QML对象，使JavaScript可以调用
                        Component.onCompleted: {
                            webChannel.registerObject("chartView", chartView)
                        }
                    }
                
                    // 使用WebEngineView加载Plotly图表
                    WebEngineView {
                    id: webView
                    anchors.fill: parent
                        url: Qt.resolvedUrl("../html/charts.html")
                        webChannel: webChannel
                        
                        // 启用WebChannel支持
                        settings.javascriptEnabled: true
                        settings.allowRunningInsecureContent: true
                        settings.localContentCanAccessRemoteUrls: true
                    
                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                            console.log("ChartView WebEngineView: LoadSucceededStatus - HTML页面已加载/重载。");
                            // JS内部的DOMContentLoaded和WebChannel初始化会调用QML的pageLoaded()
                        } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                            console.error("ChartView WebEngineView: LoadFailedStatus - 加载 '", loadRequest.url, "' 失败: ", loadRequest.errorString);
                            setError("加载图表核心页面失败: " + loadRequest.errorString);
                        }
                    }
                        
                    onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceId) {
                        var levelStr = "信息"
                        if (level === WebEngineView.InfoMessageLevel) levelStr = "信息";
                        else if (level === WebEngineView.WarningMessageLevel) levelStr = "警告";
                        else if (level === WebEngineView.ErrorMessageLevel) levelStr = "错误";
                        
                        console.log("JS控制台 [" + levelStr + "] " + message + " (行: " + lineNumber + ", 源: " + sourceId + ")");
                    }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton // 只处理滚轮，不处理点击，让点击穿透到WebView
                        onWheel: (wheel) => {
                            // wheel.angleDelta.y 通常是 120 的倍数
                            // 正值表示向下滚轮（内容向上滚动），负值表示向上滚轮（内容向下滚动）
                            let scrollAmount = wheel.angleDelta.y * 0.5; // 滚动灵敏度因子，可以调整
                            chartFlickable.contentY -= scrollAmount; // 更新Flickable的滚动位置
                            wheel.accepted = true; // 事件已处理，不再向下传递
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
                text: hasError ? errorMessage : "请确保已安装WebEngine模块，并添加一些交易数据"
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
