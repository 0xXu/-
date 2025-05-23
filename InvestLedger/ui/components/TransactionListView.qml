import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic as Controls
import Qt5Compat.GraphicalEffects


Item {
    id: transactionListView
    
    // QML 属性定义
    property string startDateFilter: ""
    property string endDateFilter: ""
    property string assetTypeFilter: "全部"
    property string nameFilter: ""
    property string profitLossState: "全部"
    property bool hasData: false
    property bool isLoading: false
    property int totalCount: 0
    property bool userSelected: mainWindow ? mainWindow.userSelected : false
    
    // 主题颜色
    property color primaryColor: theme ? theme.primaryColor : "#4CAF50"
    property color backgroundColor: theme ? theme.backgroundColor : "#F5F5F5"
    property color cardColor: theme ? theme.cardColor : "#FFFFFF"
    property color textColor: theme ? theme.textColor : "#333333"
    property color borderColor: theme ? theme.borderColor : "#E0E0E0"
    property color profitColor: theme ? theme.profitColor : "#4CAF50"
    property color lossColor: theme ? theme.lossColor : "#F44336"
    
    // 内部模型定义
    ListModel {
        id: assetTypeModel
    }
    
    ListModel {
        id: transactionModel
    }
    
    // 组件加载完成后执行
    Component.onCompleted: {
        if (userSelected) {
            loadAssetTypes();
            loadTransactions();
        } else {
            hasData = false;
            emptyStateOverlay.visible = true;
        }
    }
    
    // 监听后端事件
    Connections {
        target: backend
        function onTransactionsChanged() {
            loadTransactions();
        }
    }
    
    // 加载资产类型
    function loadAssetTypes() {
        try {
            var types = backend.getAssetTypes();
            assetTypeModel.clear();
            
            // 添加"全部"选项
            assetTypeModel.append({name: "全部", value: ""});
            
            if (types && types.length > 0) {
                for (var i = 0; i < types.length; i++) {
                    assetTypeModel.append({name: types[i], value: types[i]});
                }
            } else {
                // 使用默认类型列表
                var defaultTypes = ["股票", "基金", "债券", "期货", "外汇", "加密货币", "房地产", "其他"];
                for (var j = 0; j < defaultTypes.length; j++) {
                    assetTypeModel.append({name: defaultTypes[j], value: defaultTypes[j]});
                }
            }
            
            // 校验当前资产类型过滤器是否有效
            var validType = false;
            for (var k = 0; k < assetTypeModel.count; k++) {
                if (assetTypeModel.get(k).name === assetTypeFilter) {
                    validType = true;
                    break;
                }
            }
            
            if (!validType) {
                assetTypeFilter = "全部";
            }
        } catch (e) {
            console.error("加载资产类型失败: " + e);
        }
    }
    
    // 加载交易数据
    function loadTransactions() {
        isLoading = true;
        
        // 判断用户是否选择
        if (!userSelected && !backend.getCurrentUserSelected()) {
            transactionModel.clear();
            hasData = false;
            emptyStateOverlay.visible = true;
            isLoading = false;
            return;
        }
        
        // 使用计时器确保加载动画能够渲染
        loadTimer.start();
    }
    
    Timer {
        id: loadTimer
        interval: 300
        repeat: false
        onTriggered: {
            try {
                // 准备过滤参数
                var typeFilter = assetTypeFilter === "全部" ? "" : assetTypeFilter;
                var plFilter = "";
                if (profitLossState === "盈利") {
                    plFilter = "profit";
                } else if (profitLossState === "亏损") {
                    plFilter = "loss";
                }
                
                // 清空模型并获取数据
                transactionModel.clear();
                
                // 调用后端API获取过滤后的交易数据
                var transactions = backend.getFilteredTransactions(
                    startDateFilter, 
                    endDateFilter, 
                    typeFilter, 
                    nameFilter, 
                    plFilter, 
                    1000, 
                    0
                );
                
                // 填充模型
                if (transactions && transactions.length > 0) {
                    console.log("加载交易数据成功, 数量:", transactions.length);
                    for (var i = 0; i < transactions.length; i++) {
                        // 确保所有必要字段都存在
                        var tx = transactions[i];
                        var transaction = {
                            id: tx.id || 0,
                            date: tx.date || "",
                            assetType: tx.asset_type || "",
                            name: tx.project_name || "",
                            profitLoss: tx.profit_loss !== undefined ? tx.profit_loss : 0,
                            note: tx.notes || ""
                        };
                        
                        // 日志调试用
                        console.log("交易数据:", JSON.stringify(transaction));
                        
                        transactionModel.append(transaction);
                    }
                } else {
                    console.log("没有找到交易数据");
                }
                
                // 获取总数
                totalCount = backend.getFilteredTransactionsCount(
                    startDateFilter, 
                    endDateFilter, 
                    typeFilter, 
                    nameFilter, 
                    plFilter
                );
                
                // 更新数据状态
                hasData = transactionModel.count > 0;
                emptyStateOverlay.visible = !hasData;
                
            } catch (e) {
                console.error("加载交易数据失败: " + e);
                errorDialog.showError("加载交易数据失败", e.toString());
                hasData = false;
                emptyStateOverlay.visible = true;
            } finally {
                isLoading = false;
            }
        }
    }
    
    // 应用过滤器
    function applyFilters() {
        loadTransactions();
    }
    
    // 重置过滤器
    function resetFilters() {
        startDateFilter = "";
        endDateFilter = "";
        assetTypeFilter = "全部";
        nameFilter = "";
        profitLossState = "全部";
        
        // 清空日期输入框
        startDateInput.text = "";
        endDateInput.text = "";
        nameFilterInput.text = "";
        
        // 重新加载数据
        loadTransactions();
    }
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // 过滤和操作栏
        Rectangle {
            id: filterCard
            Layout.fillWidth: true
            color: cardColor
            radius: 8
            implicitHeight: filterLayout.implicitHeight + 24 // Add padding
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.15)
            }
            
            ColumnLayout {
                id: filterLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                
                // 第一行：日期和资产类型过滤
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // 起始日期
                    ColumnLayout {
                        Layout.preferredWidth: 180
                        spacing: 4
                        
                        Text { 
                            text: "起始日期"
                            color: textColor
                            font.pixelSize: 12
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: "white"
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            
                            TextInput {
                                id: startDateInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                text: startDateFilter
                                color: textColor
                                selectByMouse: true
                                maximumLength: 10 // YYYY-MM-DD
                                
                                onEditingFinished: {
                                    startDateFilter = text;
                                }
                            }
                            
                            MouseArea {
                                anchors.right: parent.right
                                width: 32
                                height: parent.height
                                onClicked: startDateCalendar.visible = !startDateCalendar.visible
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "📅"
                                    color: textColor
                                }
                            }
                            
                            // 日历弹窗
                            Popup {
                                id: startDateCalendar
                                x: 0
                                y: parent.height
                                width: 250 
                                height: 300 
                                padding: 8
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                

                                Rectangle {
                            anchors.fill: parent
                            color: cardColor
                            radius: 8
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8
                                // 头部：月份切换
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Button {
                                        text: "◀"
                                        onClicked: startDateCalendar.currentMonth.setMonth(startDateCalendar.currentMonth.getMonth() - 1)
                                    }
                                     Text {
                                        text: Qt.formatDate(startDateCalendar.currentMonth, "yyyy年MM月")
                                        font.bold: true
                                        color: textColor
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Button {
                                        text: "▶"
                                        onClicked: startDateCalendar.currentMonth.setMonth(startDateCalendar.currentMonth.getMonth() + 1)
                                    }
                                }
                                // 星期栏
                                RowLayout {
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: ["日","一","二","三","四","五","六"]
                                        Text {
                                            text: modelData
                                            color: textColor
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                                // 日期网格
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    rowSpacing: 0; columnSpacing: 0
                                    Repeater {
                                        model: {
                                            var date = new Date(startDateCalendar.currentMonth);
                                            date.setDate(1);
                                            var firstDay = date.getDay();
                                            var daysInMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
                                            var prefixDays = (firstDay + 6) % 7;
                                            return Math.ceil((daysInMonth + prefixDays) / 7) * 7;
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 40
                                            border.color: borderColor
                                            property int dayIndex: index
                                            property int dayNumber: {
                                                var date = new Date(startDateCalendar.currentMonth);
                                                date.setDate(1);
                                                var firstDay = date.getDay();
                                                var prefixDays = (firstDay + 6) % 7;
                                                if (index < prefixDays || index >= prefixDays + new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()) return -1;
                                                return index - prefixDays + 1;
                                            }
                                            Text {
                                                text: parent.dayNumber > 0 ? parent.dayNumber : ""
                                                anchors.centerIn: parent
                                                color: textColor
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.dayNumber > 0
                                                onClicked: {
                                                    var selectedDate = new Date(startDateCalendar.currentMonth);
                                                    selectedDate.setDate(parent.dayNumber);
                                                    startDateInput.text = Qt.formatDate(selectedDate, "yyyy-MM-dd");
                                                    startDateFilter = startDateInput.text;
                                                    startDateCalendar.close();
                                                }
                                            }
                                        }
                                    }
                                }
                                Button { // 关闭按钮
                                    text: "关闭"
                                    Layout.fillWidth: true
                                    onClicked: startDateCalendar.close()
                                }
                            }
                        }
                        property date currentMonth: startDateFilter ? new Date(startDateFilter) : new Date()
                            }
                        }
                    }
                    
                    // 结束日期
                    ColumnLayout {
                        Layout.preferredWidth: 180
                        spacing: 4
                        
                        Text { 
                            text: "结束日期"
                            color: textColor
                            font.pixelSize: 12
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: "white"
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            
                            TextInput {
                                id: endDateInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                text: endDateFilter
                                color: textColor
                                selectByMouse: true
                                maximumLength: 10 // YYYY-MM-DD
                                
                                onEditingFinished: {
                                    endDateFilter = text;
                                }
                            }
                            
                            MouseArea {
                                anchors.right: parent.right
                                width: 32
                                height: parent.height
                                onClicked: endDateCalendar.visible = !endDateCalendar.visible
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "📅"
                                    color: textColor
                                }
                            }
                            
                            // 日历弹窗
                           Popup {
                        id: endDateCalendar
                        width: 300; height: 360
                        padding: 8
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        Rectangle {
                            anchors.fill: parent
                            color: cardColor
                            radius: 8
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Button {
                                        text: "◀"
                                        onClicked: endDateCalendar.currentMonth.setMonth(endDateCalendar.currentMonth.getMonth() - 1)
                                    }
                                    Text {
                                        text: Qt.formatDate(endDateCalendar.currentMonth, "yyyy年MM月")
                                        font.bold: true
                                        color: textColor
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Button {
                                        text: "▶"
                                        onClicked: endDateCalendar.currentMonth.setMonth(endDateCalendar.currentMonth.getMonth() + 1)
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: ["日","一","二","三","四","五","六"]
                                        Text {
                                            text: modelData
                                            color: textColor
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    Repeater {
                                        model: {
                                            var date = new Date(endDateCalendar.currentMonth);
                                            date.setDate(1);
                                            var firstDay = date.getDay();
                                            var daysInMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
                                            var prefixDays = (firstDay + 6) % 7;
                                            return Math.ceil((daysInMonth + prefixDays) / 7) * 7;
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 40
                                            border.color: borderColor
                                            property int dayNumber: {
                                                var date = new Date(endDateCalendar.currentMonth);
                                                date.setDate(1);
                                                var firstDay = date.getDay();
                                                var prefixDays = (firstDay + 6) % 7;
                                                if (index < prefixDays || index >= prefixDays + new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()) return -1;
                                                return index - prefixDays + 1;
                                            }
                                            Text {
                                                text: parent.dayNumber > 0 ? parent.dayNumber : ""
                                                anchors.centerIn: parent
                                                color: textColor
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.dayNumber > 0
                                                onClicked: {
                                                    var selectedDate = new Date(endDateCalendar.currentMonth);
                                                    selectedDate.setDate(parent.dayNumber);
                                                    endDateInput.text = Qt.formatDate(selectedDate, "yyyy-MM-dd");
                                                    endDateFilter = endDateInput.text;
                                                    endDateCalendar.close();
                                                }
                                            }
                                        }
                                    }
                                }
                                Button {
                                    text: "关闭"
                                    Layout.fillWidth: true
                                    onClicked: endDateCalendar.close()
                                }
                            }
                        }
                        property date currentMonth: endDateFilter ? new Date(endDateFilter) : new Date()
                    }
                        }
                    }
                    
                    // 资产类型
                    ColumnLayout {
                        Layout.preferredWidth: 140
                        spacing: 4
                        
                        Text {
                            text: "资产类型"
                            color: textColor
                            font.pixelSize: 12
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: "white"
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: assetTypeFilter
                                color: textColor
                            }
                            
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▼"
                                color: textColor
                                font.pixelSize: 10
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: assetTypeMenu.popup()
                            }
                            
                            Menu {
                                id: assetTypeMenu
                                y: parent.height
                                
                                Repeater {
                                    model: assetTypeModel
                                    
                                    MenuItem {
                                        text: model.name
                                        onTriggered: {
                                            assetTypeFilter = model.name;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 盈亏状态
                    ColumnLayout {
                        Layout.preferredWidth: 140
                        spacing: 4
                        
                        Text {
                            text: "盈亏状态"
                            color: textColor
                            font.pixelSize: 12
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: "white"
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: profitLossState
                                color: textColor
                            }
                            
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "▼"
                                color: textColor
                                font.pixelSize: 10
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: plMenu.popup()
                            }
                            
                            Menu {
                                id: plMenu
                                y: parent.height
                                
                                MenuItem {
                                    text: "全部"
                                    onTriggered: profitLossState = "全部"
                                }
                                
                                MenuItem {
                                    text: "盈利"
                                    onTriggered: profitLossState = "盈利"
                                }
                                
                                MenuItem {
                                    text: "亏损"
                                    onTriggered: profitLossState = "亏损"
                                }
                            }
                        }
                    }
                }
                
                // 第二行：名称关键字与操作按钮
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // 名称关键字
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text { 
                            text: "名称关键字"
                            color: textColor
                            font.pixelSize: 12
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            color: "white"
                            border.color: borderColor
                            border.width: 1
                            radius: 4
                            
                            TextInput {
                                id: nameFilterInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                text: nameFilter
                                color: textColor
                                selectByMouse: true
                                
                                onEditingFinished: {
                                    nameFilter = text;
                                }
                            }
                        }
                    }
                    
                    // 按钮区域
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignBottom
                        
                        // 筛选按钮
                        Rectangle {
                            width: 100
                            height: 32
                            color: Qt.rgba(0.2, 0.6, 1.0, 0.8)
                            radius: 4
                            border.width: 1
                            border.color: Qt.rgba(0.2, 0.6, 1.0, 1.0)

                            Text {
                                anchors.centerIn: parent
                                text: "筛选"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: applyFilters()
                                hoverEnabled: true
                                onEntered: parent.color = Qt.rgba(0.2, 0.6, 1.0, 1.0)
                                onExited: parent.color = Qt.rgba(0.2, 0.6, 1.0, 0.8)
                            }
                        }
                        
                        // 重置按钮
                        Rectangle {
                            width: 100
                            height: 32
                            color: Qt.rgba(0.6, 0.6, 0.6, 0.8)
                            radius: 4
                            border.width: 1
                            border.color: Qt.rgba(0.6, 0.6, 0.6, 1.0)

                            Text {
                                anchors.centerIn: parent
                                text: "重置"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: resetFilters()
                                hoverEnabled: true
                                onEntered: parent.color = Qt.rgba(0.6, 0.6, 0.6, 1.0)
                                onExited: parent.color = Qt.rgba(0.6, 0.6, 0.6, 0.8)
                            }
                        }
                    }
                }
            }
        }
        
        // 交易记录表格
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: cardColor
            radius: 8
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.15)
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0
                
                // 表头
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: Qt.lighter(primaryColor, 1.6)
                    radius: 8
                    
                    // 只让顶部有圆角
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.radius
                        color: parent.color
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12  // 固定列间距
                        
                        Text {
                            Layout.preferredWidth: 90
                            text: "日期"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                        
                        Text {
                            Layout.preferredWidth: 80
                            text: "类型"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                        
                        Text {
                            Layout.preferredWidth: 120
                            text: "名称"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                        
                        Text {
                            Layout.preferredWidth: 100
                            text: "盈亏"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 200
                            text: "备注"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                        
                        Text {
                            Layout.preferredWidth: 100
                            text: "操作"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter  // 居中对齐
                        }
                    }
                }
                
                // 交易列表
                ListView {
                    id: transactionModelListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: transactionModel
                    
                    // 自定义滚动条的实现
                    ScrollBar.vertical: null // 禁用原生滚动条
                    
                    // 自定义滚动条
                    Rectangle {
                        id: customScrollbar
                        width: 6
                        radius: width / 2
                        color: "transparent" // 默认透明
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        opacity: transactionModelListView.moving || scrollbarMouseArea.containsMouse ? 1.0 : 0.0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 300 }
                        }

                        // 滚动条轨道背景
                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, 0.1)
                            radius: parent.radius
                            visible: customScrollbar.opacity > 0
                        }

                        // 滚动条滑块
                        Rectangle {
                            id: scrollHandle
                            width: parent.width
                            radius: width / 2
                            color: scrollbarMouseArea.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor
                            opacity: 0.7
                            y: Math.max(0, Math.min(
                                parent.height - height,
                                transactionModelListView.contentY * parent.height / Math.max(1, transactionModelListView.contentHeight - transactionModelListView.height)
                            ))
                            height: Math.max(
                                20, // 最小高度
                                parent.height * transactionModelListView.height / Math.max(1, transactionModelListView.contentHeight)
                            )
                            visible: transactionModelListView.contentHeight > transactionModelListView.height
                        }
                        
                        // 滚动条交互区域
                        MouseArea {
                            id: scrollbarMouseArea
                            anchors.fill: parent
                            anchors.leftMargin: -8
                            anchors.rightMargin: -4
                            hoverEnabled: true
                            
                            property int dragStartY: 0
                            property int startContentY: 0
                            
                            onPressed: {
                                dragStartY = mouseY;
                                startContentY = transactionModelListView.contentY;
                            }
                            
                            onPositionChanged: {
                                if (pressed && transactionModelListView.contentHeight > transactionModelListView.height) {
                                    var contentDelta = (mouseY - dragStartY) * transactionModelListView.contentHeight / parent.height;
                                    transactionModelListView.contentY = Math.max(0, Math.min(
                                        transactionModelListView.contentHeight - transactionModelListView.height,
                                        startContentY + contentDelta
                                    ));
                                }
                            }
                            
                            onWheel: (wheel) => {
                                var delta = wheel.angleDelta.y / 120 * 40;
                                transactionModelListView.contentY = Math.max(0, Math.min(
                                    transactionModelListView.contentHeight - transactionModelListView.height,
                                    transactionModelListView.contentY - delta
                                ));
                            }
                        }
                    }
                    
                    delegate: Rectangle {
                        id: rowDelegate
                        width: transactionModelListView.width
                        height: 50
                        color: index % 2 === 0 ? cardColor : Qt.lighter(backgroundColor, 1.02)
                        property bool isHovered: false
                        
                        MouseArea {
                            id: rowMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: rowDelegate.isHovered = true
                            onExited: rowDelegate.isHovered = false
                        }
                        
                        // Update color based on isHovered property
                        states: [
                            State {
                                name: "hovered"
                                when: rowDelegate.isHovered
                                PropertyChanges {
                                    target: rowDelegate
                                    color: Qt.lighter(primaryColor, 1.9)
                                }
                            }
                        ]
                        
                        transitions: Transition {
                            ColorAnimation { duration: 150 }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12  // 固定列间距
                            
                            // 日期
                            Text {
                                Layout.preferredWidth: 90
                                text: model.date || ""
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter  // 居中对齐
                            }
                            
                            // 类型
                            Text {
                                Layout.preferredWidth: 80
                                text: model.assetType || ""
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter  // 居中对齐
                            }
                            
                            // 名称
                            Text {
                                Layout.preferredWidth: 120
                                text: model.name || ""
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter  // 居中对齐
                            }
                            
                            // 盈亏
                            Item {
                                Layout.preferredWidth: 100
                                height: parent.height
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: profitLossText.width + 16
                                    height: 28
                                    radius: 4
                                    color: (model.profitLoss >= 0) ? Qt.rgba(0.3, 0.8, 0.3, 0.1) : Qt.rgba(0.8, 0.3, 0.3, 0.1)
                                    border.width: 1
                                    border.color: (model.profitLoss >= 0) ? Qt.rgba(0.3, 0.8, 0.3, 0.2) : Qt.rgba(0.8, 0.3, 0.3, 0.2)
                                    visible: model.profitLoss !== undefined
                                    
                                    Text {
                                        id: profitLossText
                                        anchors.centerIn: parent
                                        text: (model.profitLoss !== undefined) ? 
                                              ((model.profitLoss >= 0 ? "+" : "") + model.profitLoss.toFixed(2)) : 
                                              ""
                                        color: (model.profitLoss >= 0) ? profitColor : lossColor
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                            }
                            
                            // 备注
                            Text {
                                Layout.preferredWidth: 200
                                Layout.fillWidth: true
                                text: model.note || ""
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter  // 居中对齐
                            }
                            
                            // 操作按钮
                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 8
                                
                                // 编辑按钮
                                Rectangle {
                                    id: editButton
                                    width: 36
                                    height: 28
                                    radius: 4
                                    color: editButtonMouseArea.containsMouse ? Qt.rgba(0.2, 0.6, 1.0, 0.2) : Qt.rgba(0.2, 0.6, 1.0, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.2, 0.6, 1.0, 0.3)
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "编辑"
                                        color: Qt.rgba(0.2, 0.6, 1.0, 1.0)
                                        font.pixelSize: 12
                                    }
                                    
                                    MouseArea {
                                        id: editButtonMouseArea
                                        anchors.fill: parent
                                        onClicked: {
                                            editTransactionDialog.transactionId = model.id;
                                            editTransactionDialog.transactionDate = model.date || "";
                                            editTransactionDialog.transactionAssetType = model.assetType || "";
                                            editTransactionDialog.transactionName = model.name || "";
                                            editTransactionDialog.transactionProfitLoss = model.profitLoss || 0;
                                            editTransactionDialog.transactionNote = model.note || "";
                                            editTransactionDialog.open();
                                        }
                                        
                                        hoverEnabled: true
                                        // 不再改变父级的 opacity，而是控制自己的颜色
                                        onEntered: rowDelegate.isHovered = true
                                        onExited: if (!deleteButtonMouseArea.containsMouse) rowDelegate.isHovered = false
                                    }
                                }
                                
                                // 删除按钮
                                Rectangle {
                                    id: deleteButton
                                    width: 36
                                    height: 28
                                    radius: 4
                                    color: deleteButtonMouseArea.containsMouse ? Qt.rgba(0.9, 0.3, 0.3, 0.2) : Qt.rgba(0.9, 0.3, 0.3, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.9, 0.3, 0.3, 0.3)
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "删除"
                                        color: Qt.rgba(0.9, 0.3, 0.3, 1.0)
                                        font.pixelSize: 12
                                    }
                                    
                                    MouseArea {
                                        id: deleteButtonMouseArea
                                        anchors.fill: parent
                                        onClicked: {
                                            deleteConfirmDialog.transactionId = model.id;
                                            deleteConfirmDialog.transactionName = model.name || "此交易";
                                            deleteConfirmDialog.open();
                                        }
                                        
                                        hoverEnabled: true
                                        // 不再改变父级的 opacity，而是控制自己的颜色
                                        onEntered: rowDelegate.isHovered = true
                                        onExited: if (!editButtonMouseArea.containsMouse) rowDelegate.isHovered = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 空状态覆盖层
    Rectangle {
        id: emptyStateOverlay
        anchors.fill: parent
        color: backgroundColor
        visible: false
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userSelected ? "📄" : "👤"
                font.pixelSize: 48
                color: Qt.rgba(0, 0, 0, 0.3)
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userSelected ? "暂无交易记录" : "请先选择或创建一个用户"
                font.pixelSize: 18
                color: textColor
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userSelected ? "尝试调整上方的筛选条件。" : "选择用户后才能查看交易记录"
                font.pixelSize: 14
                color: Qt.rgba(0, 0, 0, 0.5)
            }
        }
    }
    
    // 加载状态覆盖层
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.7)
        visible: isLoading
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "正在加载数据..."
                font.pixelSize: 14
                color: textColor
            }
        }
    }
    
    // 编辑交易弹窗
    Dialog {
        id: editTransactionDialog
        title: "编辑交易"
        modal: true
        standardButtons: Dialog.Save | Dialog.Cancel
        // Adjust dialog width for better spacing
        width: Math.min(mainWindow.width * 0.8, 480) 
        
        property int transactionId: 0
        property string transactionDate: ""
        property string transactionAssetType: ""
        property string transactionName: ""
        property real transactionProfitLoss: 0
        property string transactionNote: ""

        // Custom header for better styling
        header: Rectangle {
            implicitWidth: parent.width
            implicitHeight: 48
            color: primaryColor // Use theme color

            Text {
                anchors.centerIn: parent
                text: editTransactionDialog.title
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
        }
        
        // Content area with improved layout
        ColumnLayout {
            width: parent.width - 32 // Add some padding
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16
            
            // 日期
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "日期 (YYYY-MM-DD)"
                    color: textColor
                    font.pixelSize: 12
                }
                
                TextField {
                    id: editDateInput
                    Layout.fillWidth: true
                    height: 36
                    text: editTransactionDialog.transactionDate
                    validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ }
                    placeholderText: "例如: 2023-01-15"
                    selectByMouse: true
                    // 样式设置
                    background: Rectangle {
                        color: "white"
                        border.width: 1
                        border.color: borderColor
                        radius: 4
                    }
                }
            }
            
            // 资产类型
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "资产类型"
                    color: textColor
                    font.pixelSize: 12
                }
                
                ComboBox {
                    id: editAssetTypeCombo
                    Layout.fillWidth: true
                    height: 36
                    model: assetTypeModel
                    textRole: "name"
                    background: Rectangle {
                        color: "white"
                        border.color: borderColor
                        border.width: 1
                        radius: 4
                    }
                    currentIndex: {
                        for (var i = 0; i < assetTypeModel.count; i++) {
                            if (assetTypeModel.get(i).name === editTransactionDialog.transactionAssetType) {
                                return i;
                            }
                        }
                        // Try to find by value if name match fails or is '全部'
                        for (var k = 0; k < assetTypeModel.count; k++) {
                             if (assetTypeModel.get(k).value === editTransactionDialog.transactionAssetType) {
                                return k;
                            }
                        }
                        return 0; // Default to first item if not found
                    }
                }
            }
            
            // 名称
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "名称"
                    color: textColor
                    font.pixelSize: 12
                }
                
                TextField {
                    id: editNameInput
                    Layout.fillWidth: true
                    height: 36
                    text: editTransactionDialog.transactionName
                    placeholderText: "例如: 阿里巴巴股票"
                    selectByMouse: true
                    // 样式设置
                    background: Rectangle {
                        color: "white" 
                        border.width: 1
                        border.color: borderColor
                        radius: 4
                    }
                }
            }
            
            // 盈亏
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "盈亏 (正数为盈利, 负数为亏损)"
                    color: textColor
                    font.pixelSize: 12
                }
                
                TextField {
                    id: editProfitLossInput
                    Layout.fillWidth: true
                    height: 36
                    text: editTransactionDialog.transactionProfitLoss.toFixed(2) // Format to 2 decimal places
                    validator: DoubleValidator { bottom: -Infinity; top: Infinity; decimals: 2; notation: DoubleValidator.StandardNotation }
                    placeholderText: "例如: 100.50 或 -50.25"
                    selectByMouse: true
                    // 样式设置
                    background: Rectangle {
                        color: "white"
                        border.width: 1
                        border.color: borderColor
                        radius: 4
                    }
                }
            }
            
            // 备注
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "备注 (可选)"
                    color: textColor
                    font.pixelSize: 12
                }
                
                TextArea {
                    id: editNoteInput
                    Layout.fillWidth: true
                    height: 72
                    text: editTransactionDialog.transactionNote
                    wrapMode: TextArea.Wrap
                    placeholderText: "输入备注信息..."
                    selectByMouse: true
                    
                    background: Rectangle {
                        color: "white"
                        border.width: 1
                        border.color: borderColor
                        radius: 4
                    }
                }
            }
        }
        
        // Save and Cancel buttons styling (using standard buttons for now)
        // If further customization is needed, we can replace standardButtons
        // with custom styled Rectangles and MouseAreas similar to Filter/Reset buttons.

        // 保存编辑
        onAccepted: {
            try {
                var result = backend.updateTransaction(
                    editTransactionDialog.transactionId,
                    editDateInput.text,
                    editAssetTypeCombo.currentText,
                    editNameInput.text,
                    parseFloat(editProfitLossInput.text),
                    editNoteInput.text
                );
                
                if (result) {
                    loadTransactions();
                } else {
                    errorDialog.showError("更新交易失败", "无法更新交易记录。");
                }
            } catch (e) {
                errorDialog.showError("更新交易失败", e.toString());
            }
        }
    }
    
    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        width: Math.min(mainWindow.width * 0.5, 400)
        
        property int transactionId: 0
        property string transactionName: ""
        
        header: Rectangle {
            implicitWidth: deleteConfirmDialog.width
            implicitHeight: 48
            color: lossColor
            
            Text {
                anchors.centerIn: parent
                text: "确认删除"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }
        }
        
        ColumnLayout {
            width: parent.width - 32
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            
            Text {
                Layout.fillWidth: true
                text: "确定要删除 '" + deleteConfirmDialog.transactionName + "' 这条交易记录吗？此操作不可撤销。"
                wrapMode: Text.Wrap
                color: textColor
                font.pixelSize: 14
            }
        }
        
        onAccepted: {
            try {
                var result = backend.deleteTransaction(deleteConfirmDialog.transactionId);
                
                if (result) {
                    loadTransactions();
                } else {
                    errorDialog.showError("删除交易失败", "无法删除交易记录。");
                }
            } catch (e) {
                errorDialog.showError("删除交易失败", e.toString());
            }
        }
    }
    
    // 错误对话框（假设已在主窗口定义）
    Connections {
        target: errorDialog
        // 监听错误对话框关闭
    }
}
