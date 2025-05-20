import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: transactionListView
    
    // 分页属性
    property int currentPage: 0
    property int pageSize: 50
    property int totalCount: 0
    
    // 过滤属性
    property string startDateFilter: ""
    property string endDateFilter: ""
    property string assetTypeFilter: "全部"
    
    property bool hasData: false // 用于跟踪是否有数据

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
        // 如果未选择用户，不加载数据
        if (!userSelected) return;
        
        var assetTypes = backend.getAssetTypes();
        assetTypeModel.clear();
        
        // 添加"全部"选项
        assetTypeModel.append({name: "全部", id: -1});
        
        // 添加资产类型
        for (var i = 0; i < assetTypes.length; i++) {
            assetTypeModel.append({
                name: assetTypes[i].name,
                id: assetTypes[i].id
            });
        }
        // 获取总交易数用于分页
        totalCount = backend.getTransactionsCount(startDateFilter, endDateFilter, assetTypeFilter);
        hasData = transactionModel.count > 0;
        
        emptyStateOverlay.visible = !hasData;
        transactionContent.visible = hasData;
        updatePaginationControls();
    }
    
    function loadTransactions() {
        // 如果未选择用户，不加载数据，并确保显示空状态
        if (!userSelected) {
            hasData = false;
            transactionModel.clear();
            totalCount = 0;
            emptyStateOverlay.visible = true;
            transactionContent.visible = false;
            updatePaginationControls(); // 更新分页（此时应隐藏）
            return;
        }
        
        var transactions = backend.getTransactions(
            startDateFilter, 
            endDateFilter, 
            assetTypeFilter,
            pageSize,
            currentPage * pageSize
        );
        
        transactionModel.clear();
        for (var i = 0; i < transactions.length; i++) {
            transactionModel.append({
                id: transactions[i].id,
                date: transactions[i].date,
                asset_type: transactions[i].asset_type,
                project_name: transactions[i].project_name,
                amount: transactions[i].amount,
                unit_price: transactions[i].unit_price,
                currency: transactions[i].currency,
                profit_loss: transactions[i].profit_loss,
                notes: transactions[i].notes
            });
        }
        // 获取总交易数用于分页
        totalCount = backend.getTransactionsCount(startDateFilter, endDateFilter, assetTypeFilter);
        hasData = transactionModel.count > 0;
        
        emptyStateOverlay.visible = !hasData;
        transactionContent.visible = hasData;
        updatePaginationControls();
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
                text: qsTr("尝试添加一些交易，或调整上方的筛选条件。")
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
        
        // 过滤和操作栏
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: cardColor
            radius: 5
            y: 40
            SequentialAnimation on y {
                NumberAnimation { to: 0; duration: 400; easing.type: Easing.OutQuad }
            }
            Component.onCompleted: y = 0;
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
                            currentPage = 0;
                            loadTransactions();
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
                            currentPage = 0;
                            loadTransactions();
                        }
                    }
                }
                
                // 资产类型过滤
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 2
                    
                    Text {
                        text: "资产类型"
                        font.pixelSize: 12
                    }
                    
                    ComboBox {
                        id: assetTypeCombo
                        Layout.fillWidth: true
                        model: ListModel { id: assetTypeModel }
                        textRole: "name"
                        
                        onCurrentTextChanged: {
                            assetTypeFilter = currentText;
                            currentPage = 0;
                            loadTransactions();
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // 添加交易按钮
                Button {
                    text: qsTr("添加交易")
                    icon.name: "list-add" // 使用Qt标准图标
                    highlighted: true
                    onClicked: addTransactionDialog.open()
                    ToolTip.text: qsTr("添加一条新的交易记录")
                    ToolTip.visible: hovered
                }
            }
        }
        
        // 交易记录表格
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: cardColor
            radius: 5
            opacity: 0.0
            SequentialAnimation on opacity {
                NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.OutQuad }
            }
            Component.onCompleted: opacity = 1.0;
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0
                
                // 表头
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: Qt.lighter(primaryColor, 1.7)
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 5
                        
                        Text { 
                            text: "日期" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 100
                        }
                        Text { 
                            text: "类型" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 80
                        }
                        Text { 
                            text: "项目名称" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 150
                        }
                        Text { 
                            text: "数量" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight
                        }
                        Text { 
                            text: "单价" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignRight
                        }
                        Text { 
                            text: "币种" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 60
                        }
                        Text { 
                            text: "盈亏" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        Text { 
                            text: "备注" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text { 
                            text: "操作" 
                            font.pixelSize: 14
                            font.bold: true
                            Layout.preferredWidth: 100
                        }
                    }
                }
                
                // 表格内容
                ListView {
                    id: transactionListViewList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    model: ListModel { id: transactionModel }
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 50
                        color: index % 2 === 0 ? "white" : Qt.lighter(bgColor, 1.02)
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 5
                            
                            Text { 
                                text: date 
                                font.pixelSize: 14
                                Layout.preferredWidth: 100
                            }
                            Text { 
                                text: asset_type 
                                font.pixelSize: 14
                                Layout.preferredWidth: 80
                            }
                            Text { 
                                text: project_name 
                                font.pixelSize: 14
                                Layout.preferredWidth: 150
                                elide: Text.ElideRight
                            }
                            Text { 
                                text: amount.toFixed(2) 
                                font.pixelSize: 14
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                            }
                            Text { 
                                text: unit_price.toFixed(2) 
                                font.pixelSize: 14
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                            }
                            Text { 
                                text: currency 
                                font.pixelSize: 14
                                Layout.preferredWidth: 60
                            }
                            Text { 
                                text: profit_loss.toFixed(2) 
                                font.pixelSize: 14
                                font.bold: true
                                color: profit_loss >= 0 ? profitColor : lossColor
                                Layout.preferredWidth: 100
                                horizontalAlignment: Text.AlignRight
                            }
                            Text { 
                                text: notes 
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            // 操作按钮
                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 5
                                
                                Button {
                                    text: "编辑"
                                    implicitWidth: 45
                                    implicitHeight: 30
                                    onClicked: {
                                        editTransactionDialog.transactionId = id;
                                        editTransactionDialog.dateField.text = date;
                                        editTransactionDialog.assetTypeField.text = asset_type;
                                        editTransactionDialog.projectNameField.text = project_name;
                                        editTransactionDialog.amountField.text = amount;
                                        editTransactionDialog.unitPriceField.text = unit_price;
                                        editTransactionDialog.currencyField.text = currency;
                                        editTransactionDialog.profitLossField.text = profit_loss;
                                        editTransactionDialog.notesField.text = notes;
                                        editTransactionDialog.open();
                                    }
                                }
                                
                                Button {
                                    text: "删除"
                                    implicitWidth: 45
                                    implicitHeight: 30
                                    onClicked: {
                                        deleteConfirmDialog.transactionId = id;
                                        deleteConfirmDialog.open();
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 分页控制
                Rectangle {
                    id: paginationControlsContainer
                    Layout.fillWidth: true
                    height: 50
                    color: Qt.lighter(theme.cardColor, 1.05) // 使用主题颜色
                    visible: false // 初始不可见，由updatePaginationControls控制
                    border.color: Qt.darker(theme.cardColor, 1.1)
                    border.width: 1
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        
                        Button {
                            id: prevPageButton
                            text: qsTr("上一页")
                            icon.name: "go-previous"
                            enabled: currentPage > 0
                            onClicked: {
                                if (currentPage > 0) {
                                    currentPage--;
                                    loadTransactions();
                                }
                            }
                        }
                        
                        Text {
                            id: pageInfoText
                            text: qsTr("第 %1 / %2 页").arg(currentPage + 1).arg(Math.max(1, Math.ceil(totalCount / pageSize)))
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                            color: theme.textColor
                        }
                        
                        Button {
                            id: nextPageButton
                            text: qsTr("下一页")
                            icon.name: "go-next"
                            enabled: (currentPage + 1) * pageSize < totalCount
                            onClicked: {
                                if ((currentPage + 1) * pageSize < totalCount) {
                                    currentPage++;
                                    loadTransactions();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function updatePaginationControls() {
        paginationControlsContainer.visible = totalCount > pageSize;
        prevPageButton.enabled = currentPage > 0;
        nextPageButton.enabled = (currentPage + 1) * pageSize < totalCount;
        pageInfoText.text = qsTr("第 %1 / %2 页").arg(currentPage + 1).arg(Math.max(1, Math.ceil(totalCount / pageSize)));
    }
    
    // 添加交易对话框
    Dialog {
        id: addTransactionDialog
        title: "添加交易记录"
        width: 400
        height: 500
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
                
                Text { text: "项目名称:" }
                TextField { 
                    id: addProjectNameField
                    Layout.fillWidth: true
                }
                
                Text { text: "数量:" }
                TextField { 
                    id: addAmountField
                    Layout.fillWidth: true
                    text: "1"
                    validator: DoubleValidator { bottom: 0 }
                }
                
                Text { text: "单价:" }
                TextField { 
                    id: addUnitPriceField
                    Layout.fillWidth: true
                    text: "0"
                    validator: DoubleValidator {}
                }
                
                Text { text: "币种:" }
                TextField { 
                    id: addCurrencyField
                    Layout.fillWidth: true
                    text: "CNY"
                }
                
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
                            parseFloat(addAmountField.text) || 0,
                            parseFloat(addUnitPriceField.text) || 0,
                            addCurrencyField.text,
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
    
    // 编辑交易对话框
    Dialog {
        id: editTransactionDialog
        title: "编辑交易记录"
        width: 400
        height: 500
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property int transactionId: -1
        property alias dateField: editDateField
        property alias assetTypeField: editAssetTypeField
        property alias projectNameField: editProjectNameField
        property alias amountField: editAmountField
        property alias unitPriceField: editUnitPriceField
        property alias currencyField: editCurrencyField
        property alias profitLossField: editProfitLossField
        property alias notesField: editNotesField
        
        contentItem: ColumnLayout {
            spacing: 10
            
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                
                Text { text: "日期:" }
                TextField { 
                    id: editDateField
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                }
                
                Text { text: "资产类型:" }
                TextField { 
                    id: editAssetTypeField 
                    Layout.fillWidth: true
                }
                
                Text { text: "项目名称:" }
                TextField { 
                    id: editProjectNameField
                    Layout.fillWidth: true
                }
                
                Text { text: "数量:" }
                TextField { 
                    id: editAmountField
                    Layout.fillWidth: true
                    validator: DoubleValidator { bottom: 0 }
                }
                
                Text { text: "单价:" }
                TextField { 
                    id: editUnitPriceField
                    Layout.fillWidth: true
                    validator: DoubleValidator {}
                }
                
                Text { text: "币种:" }
                TextField { 
                    id: editCurrencyField
                    Layout.fillWidth: true
                }
                
                Text { text: "盈亏:" }
                TextField { 
                    id: editProfitLossField
                    Layout.fillWidth: true
                    validator: DoubleValidator {}
                }
                
                Text { text: "备注:" }
                TextField { 
                    id: editNotesField
                    Layout.fillWidth: true 
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "取消"
                    onClicked: editTransactionDialog.close()
                }
                
                Button {
                    text: "保存"
                    highlighted: true
                    onClicked: {
                        var success = backend.updateTransaction(
                            editTransactionDialog.transactionId,
                            editDateField.text,
                            editAssetTypeField.text,
                            editProjectNameField.text,
                            parseFloat(editAmountField.text) || 0,
                            parseFloat(editUnitPriceField.text) || 0,
                            editCurrencyField.text,
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
    
    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property int transactionId: -1
        
        contentItem: ColumnLayout {
            spacing: 20
            
            Text {
                text: "确定要删除这条交易记录吗？此操作不可撤销。"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                
                Button {
                    text: "取消"
                    onClicked: deleteConfirmDialog.close()
                }
                
                Button {
                    text: "删除"
                    highlighted: true
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
    
    // 全局信号处理
    Connections {
        target: backend
        
        function onTransactionsChanged() {
            loadTransactions();
        }
    }
}