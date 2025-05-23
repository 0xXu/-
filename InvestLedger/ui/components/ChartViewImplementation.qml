import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: chartImplementation
    
    // 基本属性
    property bool isLoading: false
    property bool hasData: false
    property string errorMessage: ""
    
    // 颜色定义
    property var colors: ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6"]
    
    // 数据模型
    ListModel { id: profitLossModel }
    ListModel { id: assetDistributionModel }
    
    // 初始视图状态
    Component.onCompleted: {
        console.log("ChartViewImplementation: 简化图表已初始化")
        try {
            // 生成简单的示例数据
            generateSampleData()
            hasData = true
        } catch (e) {
            console.error("初始化图表时出错:", e)
        }
    }
    
    // 生成示例数据
    function generateSampleData() {
        console.log("ChartViewImplementation: 生成示例数据")
        // 清空现有数据
        profitLossModel.clear()
        assetDistributionModel.clear()
        
        // 添加样本盈亏数据
        var months = ["1月", "2月", "3月", "4月", "5月", "6月"]
        for (var i = 0; i < months.length; i++) {
            var profit = Math.random() * 1000
            var loss = Math.random() * 500
            
            profitLossModel.append({
                period: months[i],
                profit: profit,
                loss: loss,
                net: profit - loss
            })
        }
        
        // 添加样本资产分布数据
        var assetTypes = ["股票", "基金", "债券", "外汇", "其他"]
        var totalPercentage = 0
        
        for (var j = 0; j < assetTypes.length - 1; j++) {
            var percentage = Math.floor(Math.random() * (100 - totalPercentage) / 2)
            totalPercentage += percentage
            
            assetDistributionModel.append({
                asset_type: assetTypes[j],
                percentage: percentage
            })
        }
        
        // 最后一项占余下的百分比
        assetDistributionModel.append({
            asset_type: assetTypes[assetTypes.length - 1],
            percentage: 100 - totalPercentage
        })

        // 更新UI绘制
        profitLossCanvas.requestPaint()
        pieChartCanvas.requestPaint()
    }
    
    // 主布局
    ScrollView {
        anchors.fill: parent
        clip: true
        
        ColumnLayout {
            width: parent.width - 20
            spacing: 20
            anchors.horizontalCenter: parent.horizontalCenter
            
            // 标题栏
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: "#f0f0f0"
                radius: 5
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Text {
                        text: "简单图表展示"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        text: "刷新"
                        onClicked: generateSampleData()
                    }
                }
            }
            
            // 盈亏趋势图（使用Canvas替代ChartView）
            Rectangle {
                Layout.fillWidth: true
                height: 300
                color: "#ffffff"
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
                    
                    Canvas {
                        id: profitLossCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            var width = profitLossCanvas.width
                            var height = profitLossCanvas.height
                            
                            // 清除画布
                            ctx.clearRect(0, 0, width, height)
                            
                            // 如果没有数据，不进行绘制
                            if (profitLossModel.count === 0) return
                            
                            // 计算坐标系范围
                            var maxProfit = 0
                            var maxLoss = 0
                            
                            for (var i = 0; i < profitLossModel.count; i++) {
                                var item = profitLossModel.get(i)
                                maxProfit = Math.max(maxProfit, item.profit)
                                maxLoss = Math.max(maxLoss, item.loss)
                            }
                            
                            var maxValue = Math.max(maxProfit, maxLoss) * 1.2
                            if (maxValue < 100) maxValue = 100
                            
                            // 绘制轴线
                            var marginLeft = 50
                            var marginBottom = 50
                            var marginTop = 30
                            var graphWidth = width - marginLeft - 20
                            var graphHeight = height - marginBottom - marginTop
                            
                            ctx.strokeStyle = "#cccccc"
                            ctx.lineWidth = 1
                            
                            // X轴
                            ctx.beginPath()
                            ctx.moveTo(marginLeft, height - marginBottom)
                            ctx.lineTo(width - 20, height - marginBottom)
                            ctx.stroke()
                            
                            // Y轴
                            ctx.beginPath()
                            ctx.moveTo(marginLeft, height - marginBottom)
                            ctx.lineTo(marginLeft, marginTop)
                            ctx.stroke()
                            
                            // 绘制刻度和网格线
                            ctx.textAlign = "right"
                            ctx.textBaseline = "middle"
                            ctx.fillStyle = "#666666"
                            ctx.font = "12px sans-serif"
                            
                            // Y轴刻度
                            var yStep = maxValue / 5
                            for (var y = 0; y <= 5; y++) {
                                var yPos = height - marginBottom - (y * graphHeight / 5)
                                var value = (y * yStep).toFixed(0)
                                
                                // 刻度文本
                                ctx.fillText(value, marginLeft - 5, yPos)
                                
                                // 网格线
                                ctx.beginPath()
                                ctx.strokeStyle = "#eeeeee"
                                ctx.moveTo(marginLeft, yPos)
                                ctx.lineTo(width - 20, yPos)
                                ctx.stroke()
                            }
                            
                            // X轴刻度
                            var barWidth = graphWidth / profitLossModel.count * 0.6
                            var barSpacing = graphWidth / profitLossModel.count
                            
                            ctx.textAlign = "center"
                            ctx.textBaseline = "top"
                            
                            for (var i = 0; i < profitLossModel.count; i++) {
                                var item = profitLossModel.get(i)
                                var xPos = marginLeft + i * barSpacing + barSpacing/2
                                
                                // 刻度文本
                                ctx.fillText(item.period, xPos, height - marginBottom + 5)
                            }
                            
                            // 绘制条形图
                            for (var i = 0; i < profitLossModel.count; i++) {
                                var item = profitLossModel.get(i)
                                var xPos = marginLeft + i * barSpacing + barSpacing/2 - barWidth/2
                                
                                // 盈利柱
                                var profitHeight = (item.profit / maxValue) * graphHeight
                                ctx.fillStyle = "#2ecc71"  // 绿色
                                ctx.fillRect(xPos, height - marginBottom - profitHeight, barWidth/2 - 2, profitHeight)
                                
                                // 亏损柱
                                var lossHeight = (item.loss / maxValue) * graphHeight
                                ctx.fillStyle = "#e74c3c"  // 红色
                                ctx.fillRect(xPos + barWidth/2 + 2, height - marginBottom - lossHeight, barWidth/2 - 2, lossHeight)
                            }
                            
                            // 绘制折线图 (净值)
                            ctx.beginPath()
                            ctx.strokeStyle = "#3498db"  // 蓝色
                            ctx.lineWidth = 2
                            
                            for (var i = 0; i < profitLossModel.count; i++) {
                                var item = profitLossModel.get(i)
                                var xPos = marginLeft + i * barSpacing + barSpacing/2
                                var yPos = height - marginBottom - (item.net / maxValue) * graphHeight
                                
                                if (i === 0) {
                                    ctx.moveTo(xPos, yPos)
                                } else {
                                    ctx.lineTo(xPos, yPos)
                                }
                            }
                            
                            ctx.stroke()
                            
                            // 绘制图例
                            var legendX = width - 120
                            var legendY = marginTop
                            
                            // 盈利
                            ctx.fillStyle = "#2ecc71"
                            ctx.fillRect(legendX, legendY, 12, 12)
                            ctx.fillStyle = "#666666"
                            ctx.textAlign = "left"
                            ctx.fillText("盈利", legendX + 16, legendY + 6)
                            
                            // 亏损
                            ctx.fillStyle = "#e74c3c"
                            ctx.fillRect(legendX, legendY + 20, 12, 12)
                            ctx.fillStyle = "#666666"
                            ctx.fillText("亏损", legendX + 16, legendY + 26)
                            
                            // 净值
                            ctx.strokeStyle = "#3498db"
                            ctx.beginPath()
                            ctx.moveTo(legendX, legendY + 40 + 6)
                            ctx.lineTo(legendX + 12, legendY + 40 + 6)
                            ctx.stroke()
                            ctx.fillStyle = "#666666"
                            ctx.fillText("净值", legendX + 16, legendY + 46)
                        }
                    }
                }
            }
            
            // 资产分布图（使用Canvas绘制饼图）
            Rectangle {
                Layout.fillWidth: true
                height: 300
                color: "#ffffff"
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
                    
                    Canvas {
                        id: pieChartCanvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        onPaint: {
                            var ctx = getContext("2d")
                            var width = pieChartCanvas.width
                            var height = pieChartCanvas.height
                            
                            // 清除画布
                            ctx.clearRect(0, 0, width, height)
                            
                            // 如果没有数据，不进行绘制
                            if (assetDistributionModel.count === 0) return
                            
                            // 绘制饼图
                            var centerX = width / 2
                            var centerY = height / 2
                            var radius = Math.min(width, height) * 0.35
                            
                            var startAngle = 0
                            var total = 0
                            
                            // 计算总百分比
                            for (var i = 0; i < assetDistributionModel.count; i++) {
                                total += assetDistributionModel.get(i).percentage
                            }
                            
                            if (total <= 0) total = 100
                            
                            // 绘制每个扇形
                            for (var i = 0; i < assetDistributionModel.count; i++) {
                                var item = assetDistributionModel.get(i)
                                var angle = (item.percentage / total) * Math.PI * 2
                                
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius, startAngle, startAngle + angle)
                                ctx.closePath()
                                
                                ctx.fillStyle = colors[i % colors.length]
                                ctx.fill()
                                
                                // 绘制标签
                                var midAngle = startAngle + angle/2
                                var labelRadius = radius * 1.2
                                var labelX = centerX + Math.cos(midAngle) * labelRadius
                                var labelY = centerY + Math.sin(midAngle) * labelRadius
                                
                                ctx.fillStyle = "#333333"
                                ctx.textAlign = "center"
                                ctx.textBaseline = "middle"
                                ctx.font = "12px sans-serif"
                                ctx.fillText(item.asset_type + " " + item.percentage + "%", labelX, labelY)
                                
                                // 更新起始角度
                                startAngle += angle
                            }
                            
                            // 绘制一个中心的白色圆形，形成环形图效果
                            ctx.beginPath()
                            ctx.arc(centerX, centerY, radius * 0.6, 0, Math.PI * 2)
                            ctx.fillStyle = "#ffffff"
                            ctx.fill()
                            
                            // 绘制中心文字
                            ctx.fillStyle = "#333333"
                            ctx.textAlign = "center"
                            ctx.textBaseline = "middle"
                            ctx.font = "14px sans-serif"
                            ctx.fillText("资产分布", centerX, centerY)
                        }
                    }
                }
            }
            
            // 底部间距
            Item {
                height: 20
                Layout.fillWidth: true
            }
        }
    }
} 