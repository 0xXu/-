import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
                    for (var i = 0; i < transactions.length; i++) {
                        transactionModel.append(transactions[i]);
                    }
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
            Layout.fillWidth: true
            height: 120
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
                                width: 250 // May need adjustment for DatePicker
                                height: 300 // May need adjustment for DatePicker
                                padding: 8
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                
                                // DatePicker组件替换Calendar
                                DatePicker {
                                    id: startDatePicker
                                    anchors.fill: parent
                                    // Keep selectedDate in sync with the filter
                                    selectedDate: startDateFilter ? new Date(startDateFilter) : new Date()

                                    onAccepted: { // Use onAccepted to confirm selection
                                        var date = selectedDate;
                                        var dateStr = date.toLocaleDateString(Qt.locale(), "yyyy-MM-dd");
                                        startDateInput.text = dateStr;
                                        startDateFilter = dateStr;
                                        startDateCalendar.close();
                                    }
                                    // Optional: Add a button to explicitly close/cancel or use Popup's closePolicy
                                }
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
                                x: 0
                                y: parent.height
                                width: 250 // May need adjustment for DatePicker
                                height: 300 // May need adjustment for DatePicker
                                padding: 8
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                
                                // DatePicker组件替换Calendar
                                DatePicker {
                                    id: endDatePicker
                                    anchors.fill: parent
                                    // Keep selectedDate in sync with the filter
                                    selectedDate: endDateFilter ? new Date(endDateFilter) : new Date()

                                    onAccepted: { // Use onAccepted to confirm selection
                                        var date = selectedDate;
                                        var dateStr = date.toLocaleDateString(Qt.locale(), "yyyy-MM-dd");
                                        endDateInput.text = dateStr;
                                        endDateFilter = dateStr;
                                        endDateCalendar.close();
                                    }
                                    // Optional: Add a button to explicitly close/cancel or use Popup's closePolicy
                                }
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
                        
                        // 筛选按钮
                        Button {
                            text: "筛选"
                            implicitWidth: 100
                            implicitHeight: 32
                            
                            onClicked: {
                                applyFilters();
                            }
                        }
                        
                        // 重置按钮
                        Button {
                            text: "重置"
                            implicitWidth: 100
                            implicitHeight: 32
                            
                            onClicked: {
                                resetFilters();
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
                        spacing: 0
                        
                        Text {
                            Layout.preferredWidth: 100
                            text: "日期"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            Layout.preferredWidth: 80
                            text: "类型"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            Layout.preferredWidth: 200
                            Layout.fillWidth: true
                            text: "名称"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            Layout.preferredWidth: 120
                            text: "盈亏"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            Layout.preferredWidth: 200
                            Layout.fillWidth: true
                            text: "备注"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        
                        Text {
                            Layout.preferredWidth: 100
                            text: "操作"
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }
                
                // 交易列表
                ListView {
                    id: transactionListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: transactionModel
                    
                    delegate: Rectangle {
                        width: transactionListView.width
                        height: 50
                        color: index % 2 === 0 ? cardColor : Qt.lighter(backgroundColor, 1.02)
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.color = Qt.lighter(primaryColor, 1.9)
                            onExited: parent.color = index % 2 === 0 ? cardColor : Qt.lighter(backgroundColor, 1.02)
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 0
                            
                            // 日期
                            Text {
                                Layout.preferredWidth: 100
                                text: model.date
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            
                            // 类型
                            Text {
                                Layout.preferredWidth: 80
                                text: model.assetType
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            
                            // 名称
                            Text {
                                Layout.preferredWidth: 200
                                Layout.fillWidth: true
                                text: model.name
                                color: textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                            
                            // 盈亏
                            Item {
                                Layout.preferredWidth: 120
                                height: parent.height
                                
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: profitLossText.width + 16
                                    height: 28
                                    radius: 4
                                    color: model.profitLoss >= 0 ? Qt.rgba(0.3, 0.8, 0.3, 0.1) : Qt.rgba(0.8, 0.3, 0.3, 0.1)
                                    border.width: 1
                                    border.color: model.profitLoss >= 0 ? Qt.rgba(0.3, 0.8, 0.3, 0.2) : Qt.rgba(0.8, 0.3, 0.3, 0.2)
                                    
                                    Text {
                                        id: profitLossText
                                        anchors.centerIn: parent
                                        text: (model.profitLoss >= 0 ? "+" : "") + model.profitLoss.toFixed(2)
                                        color: model.profitLoss >= 0 ? profitColor : lossColor
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
                            }
                            
                            // 操作按钮
                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 8
                                
                                // 编辑按钮
                                Rectangle {
                                    width: 36
                                    height: 28
                                    radius: 4
                                    color: Qt.rgba(0.2, 0.6, 1.0, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.2, 0.6, 1.0, 0.3)
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "编辑"
                                        color: Qt.rgba(0.2, 0.6, 1.0, 1.0)
                                        font.pixelSize: 12
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            editTransactionDialog.transactionId = model.id;
                                            editTransactionDialog.transactionDate = model.date;
                                            editTransactionDialog.transactionAssetType = model.assetType;
                                            editTransactionDialog.transactionName = model.name;
                                            editTransactionDialog.transactionProfitLoss = model.profitLoss;
                                            editTransactionDialog.transactionNote = model.note || "";
                                            editTransactionDialog.open();
                                        }
                                        
                                        hoverEnabled: true
                                        onEntered: parent.opacity = 0.8
                                        onExited: parent.opacity = 1.0
                                    }
                                }
                                
                                // 删除按钮
                                Rectangle {
                                    width: 36
                                    height: 28
                                    radius: 4
                                    color: Qt.rgba(0.9, 0.3, 0.3, 0.1)
                                    border.width: 1
                                    border.color: Qt.rgba(0.9, 0.3, 0.3, 0.3)
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "删除"
                                        color: Qt.rgba(0.9, 0.3, 0.3, 1.0)
                                        font.pixelSize: 12
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            deleteConfirmDialog.transactionId = model.id;
                                            deleteConfirmDialog.transactionName = model.name;
                                            deleteConfirmDialog.open();
                                        }
                                        
                                        hoverEnabled: true
                                        onEntered: parent.opacity = 0.8
                                        onExited: parent.opacity = 1.0
                                    }
                                }
                            }
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        active: true
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
        
        property int transactionId: 0
        property string transactionDate: ""
        property string transactionAssetType: ""
        property string transactionName: ""
        property real transactionProfitLoss: 0
        property string transactionNote: ""
        
        // 内容区域
        ColumnLayout {
            width: 400
            spacing: 16
            
            // 日期
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "日期"
                    color: textColor
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    border.width: 1
                    border.color: borderColor
                    radius: 4
                    
                    TextInput {
                        id: editDateInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: textColor
                        selectByMouse: true
                        text: editTransactionDialog.transactionDate
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
                }
                
                ComboBox {
                    id: editAssetTypeCombo
                    Layout.fillWidth: true
                    model: assetTypeModel
                    textRole: "name"
                    currentIndex: {
                        for (var i = 0; i < assetTypeModel.count; i++) {
                            if (assetTypeModel.get(i).name === editTransactionDialog.transactionAssetType) {
                                return i;
                            }
                        }
                        return 0;
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
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    border.width: 1
                    border.color: borderColor
                    radius: 4
                    
                    TextInput {
                        id: editNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: textColor
                        selectByMouse: true
                        text: editTransactionDialog.transactionName
                    }
                }
            }
            
            // 盈亏
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "盈亏"
                    color: textColor
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    border.width: 1
                    border.color: borderColor
                    radius: 4
                    
                    TextInput {
                        id: editProfitLossInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: textColor
                        selectByMouse: true
                        text: editTransactionDialog.transactionProfitLoss.toString()
                        validator: DoubleValidator {}
                    }
                }
            }
            
            // 备注
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: "备注"
                    color: textColor
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 72
                    border.width: 1
                    border.color: borderColor
                    radius: 4
                    
                    TextArea {
                        id: editNoteInput
                        anchors.fill: parent
                        anchors.margins: 8
                        color: textColor
                        text: editTransactionDialog.transactionNote
                        wrapMode: TextArea.Wrap
                    }
                }
            }
        }
        
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
        
        Text {
            width: 400
            text: "确定要删除 '" + deleteConfirmDialog.transactionName + "' 这条交易记录吗？此操作不可撤销。"
            wrapMode: Text.Wrap
            color: textColor
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
