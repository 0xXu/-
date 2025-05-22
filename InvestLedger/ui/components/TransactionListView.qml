import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects 

Item {
    id: transactionListView
    
    // 去掉分页属性，保留过滤属性
    property string startDateFilter: ""
    property string endDateFilter: ""
    property string assetTypeFilter: "全部"
    property string nameFilter: ""
    property string profitLossState: "全部" // "全部", "盈利", "亏损"
    
    property bool hasData: false // 用于跟踪是否有数据
    property bool isLoading: false // 新增：加载状态标志

    // 当视图被加载时获取数据
    Component.onCompleted: {
        if (userSelected) {
            loadAssetTypes();
            loadTransactions();
        } else {
            // 如果没有选择用户，则初始显示空状态
            hasData = false;
            emptyStateOverlay.visible = true;
            transactionContent.visible = false;
        }
    }

    Timer {
        id: initialLoadTimer // 用于在未选择用户时延迟显示空状态，确保UI渲染完成
        interval: 50
        running: !userSelected && !hasData // 仅当未选择用户且无数据时运行一次
        repeat: false
        onTriggered: {
            if (!userSelected) {
                hasData = false;
                emptyStateOverlay.visible = true;
                transactionContent.visible = false;
            }
        }
    }
    
    function loadAssetTypes() {
        if (!userSelected) return;
        
        var assetTypesFromBackend = backend.getAssetTypes();
        console.log("Backend getAssetTypes() returned:", JSON.stringify(assetTypesFromBackend));
        
        assetTypeModel.clear();
        assetTypeModel.append({name: "全部", id: -1});
        
        if (assetTypesFromBackend && assetTypesFromBackend.length > 0) {
            for (var i = 0; i < assetTypesFromBackend.length; i++) {
                var item = assetTypesFromBackend[i];
                // Ensure 'name' and 'id' properties exist, provide fallbacks if necessary
                var itemName = item.name || item.asset_type || "未知类型"; // Fallback for name
                var itemId = item.id !== undefined ? item.id : -(i + 2); // Fallback for id, ensuring uniqueness
            assetTypeModel.append({
                    name: itemName,
                    id: itemId
                });
            }
        } else {
            // Fallback if backend returns nothing or empty array
            console.log("Backend returned no asset types, using default fallback values.");
            assetTypeModel.append({name: "股票", id: 1});
            assetTypeModel.append({name: "基金", id: 2});
            assetTypeModel.append({name: "债券", id: 3});
            assetTypeModel.append({name: "外汇", id: 4});
            assetTypeModel.append({name: "其他", id: 5});
        }
        
        // Ensure that the selectedAssetType is valid, otherwise reset to "全部"
        var currentFilterExists = false;
        for(var j = 0; j < assetTypeModel.count; j++) {
            if(assetTypeModel.get(j).name === assetTypeFilter) {
                currentFilterExists = true;
                break;
            }
        }
        if (!currentFilterExists) {
            assetTypeFilter = "全部";
            selectedTypeText.text = "全部"; // Update the display text as well
        }

        // No need to reload all transactions here, only when filter button is clicked
        // totalCount = backend.getTransactionsCount(startDateFilter, endDateFilter, assetTypeFilter);
        // hasData = totalCount > 0;
        // emptyStateOverlay.visible = !hasData;
        // transactionContent.visible = hasData;
    }
    
    function loadTransactions() {
        // 开始加载状态
        isLoading = true;
        
        // 如果未选择用户，不加载数据，并确保显示空状态
        if (!userSelected) {
            hasData = false;
            transactionModel.clear();
            totalCount = 0;
            emptyStateOverlay.visible = true;
            transactionContent.visible = false;
            isLoading = false; // 结束加载状态
            return;
        }
        
        // 使用延时器让UI有时间显示加载指示器
        loadTimer.start();
    }
    
    // 添加一个延时加载计时器
    Timer {
        id: loadTimer
        interval: 300 // 300毫秒后执行加载操作
        repeat: false
        onTriggered: {
            // 处理盈利/亏损筛选条件
            var profitLossFilter = "";
            if (profitLossState === "盈利") {
                profitLossFilter = "profit";
            } else if (profitLossState === "亏损") {
                profitLossFilter = "loss";
            }
            
            // 不使用分页，一次性加载更多数据
            var transactions = backend.getFilteredTransactions(
            startDateFilter, 
            endDateFilter, 
            assetTypeFilter,
                nameFilter,
                profitLossFilter,
                1000, // 获取更多数据
                0
        );
        
        transactionModel.clear();
        for (var i = 0; i < transactions.length; i++) {
            transactionModel.append({
                id: transactions[i].id,
                date: transactions[i].date,
                asset_type: transactions[i].asset_type,
                project_name: transactions[i].project_name,
                profit_loss: transactions[i].profit_loss,
                notes: transactions[i].notes
            });
        }
            // 获取总交易数用于判断是否有数据
            totalCount = backend.getFilteredTransactionsCount(
                startDateFilter, 
                endDateFilter, 
                assetTypeFilter,
                nameFilter,
                profitLossFilter
            );
        hasData = transactionModel.count > 0;
        
        emptyStateOverlay.visible = !hasData;
        transactionContent.visible = hasData;
            
            // 结束加载状态
            isLoading = false;
        }
    }
    
    // 空状态覆盖层
    Rectangle {
        id: emptyStateOverlay
        anchors.fill: parent
        color: Qt.rgba(theme.backgroundColor.r, theme.backgroundColor.g, theme.backgroundColor.b, 0.95) // 设置与背景相近的颜色
        visible: !hasData // 初始根据是否有数据决定
        z: 1 // 确保在内容之上

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width * 0.8 // 控制宽度，确保文本换行
            visible: userSelected // 仅当用户已选择时显示此消息

            Text {
                text: "📄"
                font.pixelSize: 64
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: qsTr("暂无交易记录")
                font.pixelSize: 18
                font.bold: true
                color: theme.textColor
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("尝试调整上方的筛选条件。") // 去掉了添加交易的提示
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
            width: parent.width * 0.8
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
                text: qsTr("选择用户后才能查看交易记录")
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

    ColumnLayout {
        id: transactionContent
        anchors.fill: parent
        spacing: 10
        visible: hasData // 根据是否有数据来决定可见性
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
        
        // 过滤和操作栏 - 美化样式
        Rectangle {
            Layout.fillWidth: true
            height: 70 // 增加高度
            color: cardColor
            radius: 8 // 增加圆角
            
            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 6.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.12)
            }
            
            y: 40
            SequentialAnimation on y {
                NumberAnimation { to: 0; duration: 400; easing.type: Easing.OutQuad }
            }
            Component.onCompleted: y = 0;
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16
                
                // 起始日期过滤 - 自定义样式
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 3
                    
                    Text {
                        text: "起始日期"
                        font.pixelSize: 12
                        color: theme.textColor
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "white"
                        radius: 4
                        border.color: startDateField.activeFocus ? theme.primaryColor : "#E0E0E0"
                        
                        TextInput {
                            id: startDateField
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                        text: startDateFilter
                            clip: true
                            readOnly: true // 设置为只读
                            
                            // 占位符文本
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "YYYY-MM-DD"
                                font.pixelSize: 12
                                color: "#AAAAAA"
                                visible: !parent.text
                            }
                        }
                        
                        // 日历图标
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "📅"
                            font.pixelSize: 14
                            color: "#888888"
                        }
                        
                        // 鼠标区域，处理点击事件
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                startDateCalendar.visible = !startDateCalendar.visible
                                if (startDateCalendar.visible) {
                                    endDateCalendar.visible = false
                                }
                            }
                        }
                    }
                }
                
                // 结束日期过滤 - 自定义样式
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 3
                    
                    Text {
                        text: "结束日期"
                        font.pixelSize: 12
                        color: theme.textColor
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "white"
                        radius: 4
                        border.color: endDateField.activeFocus ? theme.primaryColor : "#E0E0E0"
                        
                        TextInput {
                            id: endDateField
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                        text: endDateFilter
                            clip: true
                            readOnly: true // 设置为只读
                            
                            // 占位符文本
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "YYYY-MM-DD"
                                font.pixelSize: 12
                                color: "#AAAAAA"
                                visible: !parent.text
                            }
                        }
                        
                        // 日历图标
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "📅"
                            font.pixelSize: 14
                            color: "#888888"
                        }
                        
                        // 鼠标区域，处理点击事件
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                endDateCalendar.visible = !endDateCalendar.visible
                                if (endDateCalendar.visible) {
                                    startDateCalendar.visible = false
                                }
                            }
                        }
                    }
                }
                
                // 资产类型过滤 - 自定义下拉框样式
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 3
                    
                    Text {
                        text: "资产类型"
                        font.pixelSize: 12
                        color: theme.textColor
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        id: assetTypeDropdown
                        Layout.fillWidth: true
                        height: 36
                        color: "white"
                        radius: 4
                        border.color: "#E0E0E0"
                        
                        Text {
                            id: selectedTypeText
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            text: assetTypeFilter
                        }
                        
                        // 下拉箭头
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▼"
                            font.pixelSize: 12
                            color: "#888888"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (assetTypeMenu.visible)
                                    assetTypeMenu.close()
                                else
                                    assetTypeMenu.open()
                            }
                        }
                        
                        // 自定义下拉菜单
                        Menu {
                            id: assetTypeMenu
                            y: assetTypeDropdown.height
                            
                            Repeater {
                                model: assetTypeModel
                                
                                MenuItem {
                                    text: name
                                    onTriggered: {
                                        assetTypeFilter = name;
                                        selectedTypeText.text = name;
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 名称筛选输入框
            ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 3
                    
                    Text {
                        text: "名称"
                        font.pixelSize: 12
                        color: theme.textColor
                        opacity: 0.8
                    }
                    
                Rectangle {
                    Layout.fillWidth: true
                        height: 36
                        color: "white"
                        radius: 4
                        border.color: nameFilterField.activeFocus ? theme.primaryColor : "#E0E0E0"
                        
                        TextInput {
                            id: nameFilterField
                        anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            text: nameFilter
                            clip: true
                            
                            // 焦点边框效果
                            Rectangle {
                                anchors.fill: parent
                                z: -1
                                color: "transparent"
                                border.color: parent.focus ? theme.primaryColor : "transparent"
                                border.width: 2
                                radius: 4
                            }
                            
                            // 占位符文本
                        Text { 
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "输入名称关键字"
                                font.pixelSize: 12
                                color: "#AAAAAA"
                                visible: !parent.text
                            }
                        }
                    }
                }
                
                // 盈利/亏损筛选下拉框
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 3
                    
                        Text { 
                        text: "盈亏状态"
                        font.pixelSize: 12
                        color: theme.textColor
                        opacity: 0.8
                    }
                    
                    Rectangle {
                        id: profitLossDropdown
                        Layout.fillWidth: true
                        height: 36
                        color: "white"
                        radius: 4
                        border.color: "#E0E0E0"
                        
                        Text { 
                            id: selectedProfitLossText
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            text: profitLossState
                        }
                        
                        // 下拉箭头
                        Text { 
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▼"
                            font.pixelSize: 12
                            color: "#888888"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (profitLossMenu.visible)
                                    profitLossMenu.close()
                                else
                                    profitLossMenu.open()
                            }
                        }
                        
                        // 自定义下拉菜单
                        Menu {
                            id: profitLossMenu
                            y: profitLossDropdown.height
                            
                            MenuItem {
                                text: "全部"
                                onTriggered: {
                                    profitLossState = "全部";
                                    selectedProfitLossText.text = "全部";
                                }
                            }
                            MenuItem {
                                text: "盈利"
                                onTriggered: {
                                    profitLossState = "盈利";
                                    selectedProfitLossText.text = "盈利";
                                }
                            }
                            MenuItem {
                                text: "亏损"
                                onTriggered: {
                                    profitLossState = "亏损";
                                    selectedProfitLossText.text = "亏损";
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillWidth: true } // 空白填充
                
                // 筛选按钮
                Rectangle {
                    width: 80
                    height: 36
                    radius: 4
                    color: theme.primaryColor
                    
                            Text { 
                        text: "筛选"
                                font.pixelSize: 14
                        color: "white"
                        anchors.centerIn: parent
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                            // 更新筛选条件
                            startDateFilter = startDateField.text;
                            endDateFilter = endDateField.text;
                            nameFilter = nameFilterField.text;
                            // 其他筛选条件已在UI交互中设置
                            
                            // 执行筛选
                            loadTransactions();
                        }
                    }
                }
                
                // 刷新按钮
                Rectangle {
                    width: 36
                    height: 36
                    radius: 4
                    color: Qt.rgba(theme.primaryColor.r, theme.primaryColor.g, theme.primaryColor.b, 0.1)
                    
                    Text {
                        text: "⟳"
                        font.pixelSize: 20
                        anchors.centerIn: parent
                        color: theme.primaryColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                            // 清除所有筛选条件
                            startDateField.text = "";
                            endDateField.text = "";
                            nameFilterField.text = "";
                            assetTypeFilter = "全部";
                            selectedTypeText.text = "全部";
                            profitLossState = "全部";
                            selectedProfitLossText.text = "全部";
                            
                            // 更新筛选条件
                            startDateFilter = "";
                            endDateFilter = "";
                            nameFilter = "";
                            
                            // 重新加载数据
                            loadTransactions();
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
            radius: 8 // 增加圆角
            clip: true // 防止内容溢出圆角
            
            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.12)
            }
            
            opacity: 0.0
            SequentialAnimation on opacity {
                NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuad }
            }
            Component.onCompleted: opacity = 1.0;
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // 表头 - 美化样式
                Rectangle {
                    Layout.fillWidth: true
                    height: 48 // 增加高度提供更多空间
                    color: Qt.lighter(theme.primaryColor, 1.7)
                    
                    Rectangle {
                        height: 1
                        width: parent.width
                        color: Qt.darker(theme.primaryColor, 1.1)
                        anchors.bottom: parent.bottom
                    }
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 0 // 控制列之间的间距
                        
                        Item { // 日期
                            width: parent.width * 0.12
                            height: parent.height
                            Text { text: "日期"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item { // 类型
                            width: parent.width * 0.10
                            height: parent.height
                            Text { text: "类型"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item { // 名称
                            width: parent.width * 0.26 // 增加名称列宽度
                            height: parent.height
                            Text { text: "名称"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item { // 盈亏
                            width: parent.width * 0.12
                            height: parent.height
                            Text { text: "盈亏"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 5 }
                        }
                        Item { // 备注
                            width: parent.width * 0.28 // 增加备注列宽度
                            height: parent.height
                            Text { text: "备注"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 5 }
                        }
                        Item { // 操作
                            width: parent.width * 0.12
                            height: parent.height
                            Text { text: "操作"; font.pixelSize: 14; font.bold: true; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
                
                // 表格内容 - 美化样式
                ListView {
                    id: transactionListViewList
                            Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ListModel { id: transactionModel }
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 54
                        color: index % 2 === 0 ? theme.backgroundColor : theme.cardColor // 使用主题颜色
                        
                        Rectangle { // hoverEffect
                            id: hoverEffect
                            anchors.fill: parent
                            color: Qt.rgba(theme.primaryColor.r, theme.primaryColor.g, theme.primaryColor.b, 0.08) // 悬停颜色调整
                            visible: false
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: hoverEffect.visible = true; onExited: hoverEffect.visible = false }
                        Rectangle { height: 1; width: parent.width; color: theme.borderColor; anchors.bottom: parent.bottom } // 使用主题颜色

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 0 // 控制列之间的间距
                            
                            Item { // 日期
                                width: parent.width * 0.12
                                height: parent.height
                                Text { text: date; font.pixelSize: 14; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Item { // 类型
                                width: parent.width * 0.10
                                height: parent.height
                                Text { text: asset_type; font.pixelSize: 14; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Item { // 名称
                                width: parent.width * 0.26 // 增加名称列宽度
                                height: parent.height
                                Text { text: project_name; font.pixelSize: 14; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: parent.width - 10 }
                            }
                            Item { // 盈亏
                                width: parent.width * 0.12
                                height: parent.height
                                Rectangle {
                                    width: profitText.width + 16 // 标签宽度微调
                                    height: 28 // 标签高度微调
                                    radius: 4
                                    color: profit_loss >= 0 ? Qt.rgba(theme.profitColor.r, theme.profitColor.g, theme.profitColor.b, 0.15) : Qt.rgba(theme.lossColor.r, theme.lossColor.g, theme.lossColor.b, 0.15) // 使用主题颜色
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: 5 // 增加右边距
                                    Text { id: profitText; text: profit_loss.toFixed(2); font.pixelSize: 14; font.bold: true; color: profit_loss >= 0 ? theme.profitColor : theme.lossColor; anchors.centerIn: parent } // 使用主题颜色
                                }
                            }
                            Item { // 备注
                                width: parent.width * 0.28 // 增加备注列宽度
                                height: parent.height
                                Text { text: notes; font.pixelSize: 14; color: theme.textColor; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; width: parent.width - 10; anchors.left: parent.left; anchors.leftMargin: 5 } // 增加左边距
                            }
                            Item { // 操作
                                width: parent.width * 0.12
                                height: parent.height
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Rectangle { // 编辑按钮
                                        width: 28; height: 28; radius: 14
                                        color: theme.buttonBackgroundColor // 使用主题颜色
                                        Text { text: "✎"; font.pixelSize: 16; anchors.centerIn: parent; color: theme.buttonTextColor } // 使用主题颜色
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { editTransactionDialog.transactionId = id; editTransactionDialog.dateField.text = date; editTransactionDialog.assetTypeField.text = asset_type; editTransactionDialog.projectNameField.text = project_name; editTransactionDialog.profitLossField.text = profit_loss; editTransactionDialog.notesField.text = notes; editTransactionDialog.open(); } }
                                    }
                                    Rectangle { // 删除按钮
                                        width: 28; height: 28; radius: 14
                                        color: theme.buttonBackgroundColor // 使用主题颜色
                                        Text { text: "✕"; font.pixelSize: 16; anchors.centerIn: parent; color: theme.buttonTextColor } // 使用主题颜色
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { deleteConfirmDialog.transactionId = id; deleteConfirmDialog.open(); } }
                                    }
                                }
                            }
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                }
            }
        }
    }
    
    // 添加交易对话框
    Dialog {
        id: addTransactionDialog
        title: "添加交易记录"
        width: 400
        height: 400 // 减少了高度，因为删除了三个字段
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        contentItem: ColumnLayout {
            spacing: 10
            
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                
                Text { text: "日期:" }
                TextField { 
                    id: addDateField
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: new Date().toISOString().split('T')[0]
                }
                
                Text { text: "资产类型:" }
                TextField { 
                    id: addAssetTypeField 
                    Layout.fillWidth: true
                    text: "股票"
                }
                
                Text { text: "名称:" } // 改为"名称"
                TextField { 
                    id: addProjectNameField
                    Layout.fillWidth: true
                }
                
                // 删除了"数量"、"单价"和"币种"字段
                
                Text { text: "盈亏:" }
                TextField { 
                    id: addProfitLossField
                    Layout.fillWidth: true
                    text: "0"
                    validator: DoubleValidator {}
                }
                
                Text { text: "备注:" }
                TextField { 
                    id: addNotesField
                    Layout.fillWidth: true 
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "取消"
                    onClicked: addTransactionDialog.close()
                }
                
                Button {
                    text: "保存"
                    highlighted: true
                    onClicked: {
                        var success = backend.addTransaction(
                            addDateField.text,
                            addAssetTypeField.text,
                            addProjectNameField.text,
                            0, // 数量设为0
                            0, // 单价设为0
                            "CNY", // 币种默认为CNY
                            parseFloat(addProfitLossField.text) || 0,
                            addNotesField.text
                        );
                        
                        if (success) {
                            addTransactionDialog.close();
                            loadTransactions();
                        } else {
                            errorDialog.showError("添加交易记录失败");
                        }
                    }
                }
            }
        }
    }
    
    // 编辑交易对话框 - 美化样式
    Dialog {
        id: editTransactionDialog
        title: "编辑交易记录"
        width: 420
        height: 420
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        // 自定义标题栏样式
        header: Rectangle {
            width: parent.width
            height: 50
            color: theme.primaryColor
            radius: 4
            
            Text {
                text: "编辑交易记录"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            
            // 关闭按钮
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                
                Text {
                    text: "✕"
                    font.pixelSize: 16
                    color: "white"
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editTransactionDialog.close()
                }
            }
        }
        
        property int transactionId: -1
        property alias dateField: editDateField
        property alias assetTypeField: editAssetTypeField
        property alias projectNameField: editProjectNameField
        property alias profitLossField: editProfitLossField
        property alias notesField: editNotesField
        
        // 美化内容区域
        contentItem: Rectangle {
            color: "white"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                // 日期输入
                ColumnLayout {
                Layout.fillWidth: true
                    spacing: 6
                    
                    Text { 
                        text: "日期:"
                        font.pixelSize: 13
                        color: theme.textColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 4
                        border.color: editDateField.focus ? theme.primaryColor : "#E0E0E0"
                        border.width: editDateField.focus ? 2 : 1
                        
                        TextInput {
                    id: editDateField
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            selectByMouse: true
                            
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "YYYY-MM-DD"
                                font.pixelSize: 14
                                color: "#AAAAAA"
                                visible: !editDateField.text && !editDateField.focus
                            }
                        }
                    }
                }
                
                // 资产类型输入
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text { 
                        text: "资产类型:"
                        font.pixelSize: 13
                        color: theme.textColor
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 4
                        border.color: editAssetTypeField.focus ? theme.primaryColor : "#E0E0E0"
                        border.width: editAssetTypeField.focus ? 2 : 1
                        
                        TextInput {
                    id: editAssetTypeField 
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            selectByMouse: true
                        }
                    }
                }
                
                // 名称输入
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text { 
                        text: "名称:"
                        font.pixelSize: 13 
                        color: theme.textColor
                    }
                    
                    Rectangle {
                    Layout.fillWidth: true
                        height: 40
                        radius: 4
                        border.color: editProjectNameField.focus ? theme.primaryColor : "#E0E0E0"
                        border.width: editProjectNameField.focus ? 2 : 1
                        
                        TextInput {
                            id: editProjectNameField
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            selectByMouse: true
                        }
                    }
                }
                
                // 盈亏输入
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text { 
                        text: "盈亏:"
                        font.pixelSize: 13
                        color: theme.textColor
                    }
                    
                    Rectangle {
                    Layout.fillWidth: true
                        height: 40
                        radius: 4
                        border.color: editProfitLossField.focus ? theme.primaryColor : "#E0E0E0"
                        border.width: editProfitLossField.focus ? 2 : 1
                        
                        TextInput {
                            id: editProfitLossField
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            selectByMouse: true
                    validator: DoubleValidator {}
                        }
                    }
                }
                
                // 备注输入
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text { 
                        text: "备注:" 
                        font.pixelSize: 13
                        color: theme.textColor
                    }
                    
                    Rectangle {
                    Layout.fillWidth: true
                        height: 40
                        radius: 4
                        border.color: editNotesField.focus ? theme.primaryColor : "#E0E0E0"
                        border.width: editNotesField.focus ? 2 : 1
                        
                        TextInput {
                    id: editNotesField
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: theme.textColor
                            selectByMouse: true
                        }
                    }
                }
                
                Item { Layout.fillHeight: true } // 空白填充
                
                // 操作按钮区域
            RowLayout {
                Layout.alignment: Qt.AlignRight
                    spacing: 12
                    
                    // 取消按钮
                    Rectangle {
                        width: 100
                        height: 40
                        radius: 4
                        color: "#F0F0F0"
                        
                        Text {
                    text: "取消"
                            font.pixelSize: 14
                            color: "#555555"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                    onClicked: editTransactionDialog.close()
                        }
                    }
                    
                    // 保存按钮
                    Rectangle {
                        width: 100
                        height: 40
                        radius: 4
                        color: theme.primaryColor
                        
                        Text {
                    text: "保存"
                            font.pixelSize: 14
                            color: "white"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var success = backend.updateTransaction(
                            editTransactionDialog.transactionId,
                            editDateField.text,
                            editAssetTypeField.text,
                            editProjectNameField.text,
                                    0, // 数量设为0
                                    0, // 单价设为0
                                    "CNY", // 币种默认为CNY
                            parseFloat(editProfitLossField.text) || 0,
                            editNotesField.text
                        );
                        
                        if (success) {
                            editTransactionDialog.close();
                            loadTransactions();
                        } else {
                            errorDialog.showError("更新交易记录失败");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 删除确认对话框 - 美化样式
    Dialog {
        id: deleteConfirmDialog
        width: 340
        height: 180
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        // 自定义标题栏样式
        header: Rectangle {
            width: parent.width
            height: 50
            color: "#E53935" // 删除操作使用警告色
            radius: 4
            
            Text {
                text: "确认删除"
                color: "white"
                font.pixelSize: 16
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 20
            }
            
            // 关闭按钮
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                
                Text {
                    text: "✕"
                    font.pixelSize: 16
                    color: "white"
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deleteConfirmDialog.close()
                }
            }
        }
        
        property int transactionId: -1
        
        // 美化内容区域
        contentItem: Rectangle {
            color: "white"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
            spacing: 20
                
                // 警告图标和文字
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    
                    Text {
                        text: "⚠️"
                        font.pixelSize: 24
                        color: "#E53935"
                    }
            
            Text {
                text: "确定要删除这条交易记录吗？此操作不可撤销。"
                wrapMode: Text.WordWrap
                        font.pixelSize: 14
                        color: theme.textColor
                Layout.fillWidth: true
                    }
            }
            
                Item { Layout.fillHeight: true } // 空白填充
                
                // 操作按钮区域
            RowLayout {
                Layout.alignment: Qt.AlignRight
                    spacing: 12
                    
                    // 取消按钮
                    Rectangle {
                        width: 100
                        height: 36
                        radius: 4
                        color: "#F0F0F0"
                        
                        Text {
                    text: "取消"
                            font.pixelSize: 14
                            color: "#555555"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                    onClicked: deleteConfirmDialog.close()
                        }
                    }
                    
                    // 删除按钮
                    Rectangle {
                        width: 100
                        height: 36
                        radius: 4
                        color: "#E53935"
                        
                        Text {
                    text: "删除"
                            font.pixelSize: 14
                            color: "white"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var success = backend.deleteTransaction(deleteConfirmDialog.transactionId);
                        if (success) {
                            deleteConfirmDialog.close();
                            loadTransactions();
                        } else {
                            errorDialog.showError("删除交易记录失败");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 监听交易数据变化，自动刷新列表
    Connections {
        target: backend
        function onTransactionsChanged() {
            console.log("Transaction data changed, reloading transaction list...");
            loadTransactions();
        }
    }
    
    // 声明模型
    property int totalCount: 0
    ListModel { id: assetTypeModel }

    // 添加加载动画覆盖层
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, 0.7)
        visible: isLoading
        z: 10 // 确保在顶层
        
        BusyIndicator {
            anchors.centerIn: parent
            running: parent.visible
            width: 64
            height: 64
        }
        
        Text {
            anchors.top: parent.verticalCenter
            anchors.topMargin: 50
            anchors.horizontalCenter: parent.horizontalCenter
            text: "正在加载数据..."
            font.pixelSize: 16
            color: theme.textColor
        }
    }

    // 日期选择器弹出框
    Popup {
        id: startDateCalendar //确保日历控件定义存在
        width: 300
        height: 350
        x: 0
        y: 65 //确保在输入框下方
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: theme.cardColor // 使用主题颜色
            radius: 4
            border.color: theme.borderColor // 使用主题颜色
            border.width: 1
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.15) // 阴影颜色可以保留或调整
            }
        }
        
        contentItem: Item {
            anchors.fill: parent
            property var selectedDate: startDateField.text ? new Date(startDateField.text) : new Date()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                
                RowLayout {
                    Layout.fillWidth: true
                    height: 40
                    spacing: 8
                    
                    Button {
                        text: "<"
                        implicitWidth: 40
                        onClicked: {
                            var currentDate = new Date(startYearCombo.currentValue, startMonthCombo.currentIndex, 1);
                            currentDate.setMonth(currentDate.getMonth() - 1);
                            startMonthCombo.currentIndex = currentDate.getMonth();
                            startYearCombo.currentIndex = startYearCombo.model.findIndex(function(item) { return item.value === currentDate.getFullYear(); });
                            updateCalendarGrid("start");
                        }
                    }
                    
                    ComboBox {
                        id: startMonthCombo
                        Layout.fillWidth: true
                        model: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
                        currentIndex: selectedDate.getMonth()
                        onCurrentIndexChanged: updateCalendarGrid("start")
                    }
                    
                    ComboBox {
                        id: startYearCombo
                        Layout.fillWidth: true
                        model: (function() {
                            var years = [];
                            var currentYear = new Date().getFullYear();
                            for (var i = currentYear - 20; i <= currentYear + 10; i++) {
                                years.push({text: i + "年", value: i});
                            }
                            return years;
                        })()
                        currentIndex: model.findIndex(function(item) { return item.value === selectedDate.getFullYear(); })
                        textRole: "text"
                        valueRole: "value"
                        onCurrentIndexChanged: updateCalendarGrid("start")
                    }
                    
                    Button {
                        text: ">"
                        implicitWidth: 40
                        onClicked: {
                            var currentDate = new Date(startYearCombo.currentValue, startMonthCombo.currentIndex, 1);
                            currentDate.setMonth(currentDate.getMonth() + 1);
                            startMonthCombo.currentIndex = currentDate.getMonth();
                            startYearCombo.currentIndex = startYearCombo.model.findIndex(function(item) { return item.value === currentDate.getFullYear(); });
                            updateCalendarGrid("start");
                        }
                    }
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    Repeater {
                        model: ["日", "一", "二", "三", "四", "五", "六"]
                        delegate: Label {
                            text: modelData
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                        }
                    }
                }
                
                GridLayout {
                    id: calendarGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    
                    Repeater {
                        id: startDayRepeater
                        model: 42 // 6 weeks * 7 days
                        
                        Rectangle {
                            property date cellDate
                            property bool isCurrentDisplayMonth
                            property bool isSelectable
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: calendarGrid.height / 6
                            radius: width / 2
                            color: {
                                if (!isSelectable) return "transparent";
                                if (cellDate.toDateString() === startDateCalendar.contentItem.selectedDate.toDateString()) return theme.primaryColor;
                                return "transparent";
                            }
                            opacity: isSelectable && isCurrentDisplayMonth ? 1.0 : 0.3
                            
                            Text {
                                anchors.centerIn: parent
                                text: isSelectable ? cellDate.getDate() : ""
                                color: parent.color === theme.primaryColor ? "white" : theme.textColor
                                font.pixelSize: 14
                                visible: parent.isSelectable
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.isSelectable && parent.isCurrentDisplayMonth
                                onClicked: {
                                    startDateCalendar.contentItem.selectedDate = parent.cellDate;
                                    startDateField.text = Qt.formatDate(parent.cellDate, "yyyy-MM-dd");
                                    startDateCalendar.close();
                                }
                            }
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    height: 50
                    Item { Layout.fillWidth: true }
                    Rectangle { // 清除按钮
                        width: 80; height: 34; radius: 4
                        color: theme.buttonBackgroundColor // 使用主题颜色
                        Text { anchors.centerIn: parent; text: "清除"; font.pixelSize: 14; color: theme.buttonTextColor } // 使用主题颜色
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { startDateField.text = ""; startDateCalendar.close(); } }
                    }
                    Rectangle { // 今天按钮
                        width: 80; height: 34; radius: 4
                        color: theme.primaryColor // 使用主题颜色
                        Text { anchors.centerIn: parent; text: "今天"; font.pixelSize: 14; color: "white" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var today = new Date(); startDateField.text = Qt.formatDate(today, "yyyy-MM-dd"); startDateCalendar.contentItem.selectedDate = today; updateCalendarGrid("start"); startDateCalendar.close(); } }
                    }
                }
            }
            
            function updateCalendarGrid(calendarPrefix) {
                var year = calendarPrefix === "start" ? startYearCombo.currentValue : endYearCombo.currentValue;
                var month = calendarPrefix === "start" ? startMonthCombo.currentIndex : endMonthCombo.currentIndex;
                var repeater = calendarPrefix === "start" ? startDayRepeater : endDayRepeater;
                
                var firstOfMonth = new Date(year, month, 1);
                var startingDay = firstOfMonth.getDay(); // 0 (Sun) to 6 (Sat)
                
                var currentDate = new Date(firstOfMonth);
                currentDate.setDate(1 - startingDay); // Rewind to the first day to display in the grid (could be previous month)

                for (var i = 0; i < repeater.model; i++) {
                    var cell = repeater.itemAt(i);
                    cell.cellDate = new Date(currentDate);
                    cell.isCurrentDisplayMonth = currentDate.getMonth() === month;
                    cell.isSelectable = true; // All cells are selectable initially, opacity handles visual cue
                    currentDate.setDate(currentDate.getDate() + 1);
                }
            }
            
            Component.onCompleted: {
                var d = startDateField.text ? new Date(startDateField.text) : new Date();
                startMonthCombo.currentIndex = d.getMonth();
                var yearIndex = startYearCombo.model.findIndex(function(item){ return item.value === d.getFullYear(); });
                if(yearIndex !== -1) startYearCombo.currentIndex = yearIndex;
                else startYearCombo.currentIndex = 20; // Default if year not in range

                startDateCalendar.contentItem.selectedDate = d;
                updateCalendarGrid("start");
            }
        }
    }

    // 日期选择器弹出框
    Popup {
        id: endDateCalendar //确保日历控件定义存在
        width: 300
        height: 350
        x: 0
        y: 65 //确保在输入框下方
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: theme.cardColor // 使用主题颜色
            radius: 4
            border.color: theme.borderColor // 使用主题颜色
            border.width: 1
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: Qt.rgba(0, 0, 0, 0.15)
            }
        }
        
        contentItem: Item {
            anchors.fill: parent
            property var selectedDate: endDateField.text ? new Date(endDateField.text) : new Date()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                
                RowLayout {
                    Layout.fillWidth: true
                    height: 40
                    spacing: 8
                    
                    Button {
                        text: "<"
                        implicitWidth: 40
                        onClicked: {
                            var currentDate = new Date(endYearCombo.currentValue, endMonthCombo.currentIndex, 1);
                            currentDate.setMonth(currentDate.getMonth() - 1);
                            endMonthCombo.currentIndex = currentDate.getMonth();
                            endYearCombo.currentIndex = endYearCombo.model.findIndex(function(item) { return item.value === currentDate.getFullYear(); });
                            endDateCalendar.contentItem.updateCalendarGrid("end");
                        }
                    }
                    
                    ComboBox {
                        id: endMonthCombo
                        Layout.fillWidth: true
                        model: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
                        currentIndex: selectedDate.getMonth()
                        onCurrentIndexChanged: endDateCalendar.contentItem.updateCalendarGrid("end")
                    }
                    
                    ComboBox {
                        id: endYearCombo
                        Layout.fillWidth: true
                        model: (function() {
                            var years = [];
                            var currentYear = new Date().getFullYear();
                            for (var i = currentYear - 20; i <= currentYear + 10; i++) {
                                years.push({text: i + "年", value: i});
                            }
                            return years;
                        })()
                        currentIndex: model.findIndex(function(item) { return item.value === selectedDate.getFullYear(); })
                        textRole: "text"
                        valueRole: "value"
                        onCurrentIndexChanged: endDateCalendar.contentItem.updateCalendarGrid("end")
                    }
                    
                    Button {
                        text: ">"
                        implicitWidth: 40
                        onClicked: {
                            var currentDate = new Date(endYearCombo.currentValue, endMonthCombo.currentIndex, 1);
                            currentDate.setMonth(currentDate.getMonth() + 1);
                            endMonthCombo.currentIndex = currentDate.getMonth();
                            endYearCombo.currentIndex = endYearCombo.model.findIndex(function(item) { return item.value === currentDate.getFullYear(); });
                            endDateCalendar.contentItem.updateCalendarGrid("end");
                        }
                    }
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    Repeater {
                        model: ["日", "一", "二", "三", "四", "五", "六"]
                        delegate: Label {
                            text: modelData
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                        }
                    }
                }
                
                GridLayout {
                    id: endCalendarGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    
                    Repeater {
                        id: endDayRepeater
                        model: 42 // 6 weeks * 7 days
                        
                        Rectangle {
                            property date cellDate
                            property bool isCurrentDisplayMonth
                            property bool isSelectable
                            
                            Layout.fillWidth: true
                            Layout.preferredHeight: endCalendarGrid.height / 6
                            radius: width / 2
                            color: {
                                if (!isSelectable) return "transparent";
                                if (cellDate.toDateString() === endDateCalendar.contentItem.selectedDate.toDateString()) return theme.primaryColor;
                                return "transparent";
                            }
                            opacity: isSelectable && isCurrentDisplayMonth ? 1.0 : 0.3
                            
                            Text {
                                anchors.centerIn: parent
                                text: isSelectable ? cellDate.getDate() : ""
                                color: parent.color === theme.primaryColor ? "white" : theme.textColor
                                font.pixelSize: 14
                                visible: parent.isSelectable
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.isSelectable && parent.isCurrentDisplayMonth
                                onClicked: {
                                    endDateCalendar.contentItem.selectedDate = parent.cellDate;
                                    endDateField.text = Qt.formatDate(parent.cellDate, "yyyy-MM-dd");
                                    endDateCalendar.close();
                                }
                            }
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    height: 50
                    Item { Layout.fillWidth: true }
                    Rectangle { // 清除按钮
                        width: 80; height: 34; radius: 4
                        color: theme.buttonBackgroundColor // 使用主题颜色
                        Text { anchors.centerIn: parent; text: "清除"; font.pixelSize: 14; color: theme.buttonTextColor } // 使用主题颜色
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { endDateField.text = ""; endDateCalendar.close(); } }
                    }
                    Rectangle { // 今天按钮
                        width: 80; height: 34; radius: 4
                        color: theme.primaryColor // 使用主题颜色
                        Text { anchors.centerIn: parent; text: "今天"; font.pixelSize: 14; color: "white" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { var today = new Date(); endDateField.text = Qt.formatDate(today, "yyyy-MM-dd"); endDateCalendar.contentItem.selectedDate = today; endDateCalendar.contentItem.updateCalendarGrid("end"); endDateCalendar.close(); } }
                    }
                }
            }
            
            function updateCalendarGrid(calendarPrefix) {
                var year = calendarPrefix === "start" ? startYearCombo.currentValue : endYearCombo.currentValue;
                var month = calendarPrefix === "start" ? startMonthCombo.currentIndex : endMonthCombo.currentIndex;
                var repeater = calendarPrefix === "start" ? startDayRepeater : endDayRepeater;
                
                var firstOfMonth = new Date(year, month, 1);
                var startingDay = firstOfMonth.getDay(); 
                
                var currentDate = new Date(firstOfMonth);
                currentDate.setDate(1 - startingDay);

                for (var i = 0; i < repeater.model; i++) {
                    var cell = repeater.itemAt(i);
                    cell.cellDate = new Date(currentDate);
                    cell.isCurrentDisplayMonth = currentDate.getMonth() === month;
                    cell.isSelectable = true; 
                    currentDate.setDate(currentDate.getDate() + 1);
                }
            }
            Component.onCompleted: {
                var d = endDateField.text ? new Date(endDateField.text) : new Date();
                endMonthCombo.currentIndex = d.getMonth();
                var yearIndex = endYearCombo.model.findIndex(function(item){ return item.value === d.getFullYear(); });
                if(yearIndex !== -1) endYearCombo.currentIndex = yearIndex;
                else endYearCombo.currentIndex = 20; // Default

                endDateCalendar.contentItem.selectedDate = d;
                updateCalendarGrid("end");
            }
        }
    }
}