import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: tagManager
    
    // 当前选择的标签ID
    property int selectedTagId: -1
    
    // 绑定的交易ID（用于编辑交易的标签）
    property int transactionId: -1
    
    // 选择模式（true表示选择模式，用于选择标签后返回）
    property bool selectionMode: false
    
    // 多选模式（true表示可以选择多个标签）
    property bool multiSelect: false
    
    // 已选标签IDs
    property var selectedTagIds: []
    
    // 标签选择变更信号
    signal tagsSelected(var selectedIds)
    
    // 标签数据模型
    ListModel { id: tagsModel }
    
    // 当组件加载时获取数据
    Component.onCompleted: {
        loadTags();
        
        if (transactionId > 0) {
            loadTransactionTags();
        }
    }
    
    // 加载所有标签
    function loadTags() {
        var tags = backend.getAllTags();
        tagsModel.clear();
        
        for (var i = 0; i < tags.length; i++) {
            tagsModel.append({
                id: tags[i].id,
                name: tags[i].name,
                color: tags[i].color,
                description: tags[i].description,
                selected: false
            });
        }
    }
    
    // 加载交易的标签
    function loadTransactionTags() {
        if (transactionId <= 0) return;
        
        var transactionTags = backend.getTransactionTags(transactionId);
        selectedTagIds = [];
        
        // 标记已关联的标签
        for (var i = 0; i < tagsModel.count; i++) {
            var tagItem = tagsModel.get(i);
            tagItem.selected = false;
            
            for (var j = 0; j < transactionTags.length; j++) {
                if (tagItem.id === transactionTags[j].id) {
                    tagItem.selected = true;
                    selectedTagIds.push(tagItem.id);
                    break;
                }
            }
        }
    }
    
    // 切换标签选择
    function toggleTagSelection(index) {
        var tag = tagsModel.get(index);
        
        if (multiSelect) {
            // 多选模式
            tag.selected = !tag.selected;
            
            if (tag.selected) {
                // 添加到选择列表
                if (!selectedTagIds.includes(tag.id)) {
                    selectedTagIds.push(tag.id);
                }
            } else {
                // 从选择列表移除
                var idx = selectedTagIds.indexOf(tag.id);
                if (idx !== -1) {
                    selectedTagIds.splice(idx, 1);
                }
            }
        } else {
            // 单选模式
            for (var i = 0; i < tagsModel.count; i++) {
                tagsModel.get(i).selected = (i === index);
            }
            
            selectedTagId = tag.id;
            selectedTagIds = [tag.id];
            
            if (selectionMode) {
                tagsSelected(selectedTagIds);
            }
        }
    }
    
    // 保存标签到交易
    function saveTagsToTransaction() {
        if (transactionId <= 0) return false;
        
        var success = backend.replaceTransactionTags(transactionId, selectedTagIds);
        return success;
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        // 标题和操作栏
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: cardColor
            radius: 5
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                
                Text {
                    text: selectionMode ? "选择标签" : "标签管理"
                    font.pixelSize: 18
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                TextField {
                    id: searchField
                    Layout.preferredWidth: 150
                    placeholderText: "搜索标签..."
                    onTextChanged: {
                        if (text.length >= 2 || text.length === 0) {
                            searchTimer.restart();
                        }
                    }
                }
                
                Button {
                    text: "新建标签"
                    onClicked: {
                        newTagDialog.open();
                    }
                }
                
                Timer {
                    id: searchTimer
                    interval: 300
                    onTriggered: {
                        if (searchField.text) {
                            var searchResults = backend.searchTags(searchField.text);
                            tagsModel.clear();
                            
                            for (var i = 0; i < searchResults.length; i++) {
                                var isSelected = selectedTagIds.includes(searchResults[i].id);
                                tagsModel.append({
                                    id: searchResults[i].id,
                                    name: searchResults[i].name,
                                    color: searchResults[i].color,
                                    description: searchResults[i].description,
                                    selected: isSelected
                                });
                            }
                        } else {
                            loadTags();
                            
                            // 恢复已选状态
                            for (var i = 0; i < tagsModel.count; i++) {
                                var tagItem = tagsModel.get(i);
                                tagItem.selected = selectedTagIds.includes(tagItem.id);
                            }
                        }
                    }
                }
            }
        }
        
        // 标签列表
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: cardColor
            radius: 5
            
            ScrollView {
                anchors.fill: parent
                anchors.margins: 5
                clip: true
                
                GridView {
                    id: tagsGridView
                    anchors.fill: parent
                    cellWidth: 150
                    cellHeight: 40
                    model: tagsModel
                    delegate: Rectangle {
                        width: 140
                        height: 30
                        radius: 15
                        color: model.selected ? model.color : Qt.lighter(model.color, 1.5)
                        border.color: model.color
                        border.width: 1
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                toggleTagSelection(index);
                            }
                            onPressAndHold: {
                                if (!selectionMode) {
                                    editTagDialog.tagId = model.id;
                                    editTagDialog.tagNameField.text = model.name;
                                    editTagDialog.tagDescField.text = model.description || "";
                                    editTagDialog.tagColor = model.color;
                                    editTagDialog.open();
                                }
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5
                            
                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: model.color
                                visible: !model.selected
                            }
                            
                            Text {
                                text: model.name
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                color: model.selected ? "white" : textColor
                                font.bold: model.selected
                            }
                            
                            Image {
                                source: "qrc:/icons/check.png"
                                width: 16
                                height: 16
                                visible: model.selected
                                Layout.alignment: Qt.AlignRight
                            }
                        }
                    }
                }
            }
        }
        
        // 底部按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Button {
                text: "取消"
                visible: selectionMode
                onClicked: {
                    selectedTagIds = [];
                    tagsSelected([]);
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: selectionMode ? "确认选择" : "应用标签"
                visible: selectionMode || transactionId > 0
                highlighted: true
                onClicked: {
                    if (selectionMode) {
                        tagsSelected(selectedTagIds);
                    } else if (transactionId > 0) {
                        var success = saveTagsToTransaction();
                        if (success) {
                            backend.showMessage("标签保存成功");
                        } else {
                            backend.showMessage("标签保存失败");
                        }
                    }
                }
            }
        }
    }
    
    // 新建标签对话框
    Dialog {
        id: newTagDialog
        title: "新建标签"
        width: 350
        height: 250
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        GridLayout {
            columns: 2
            anchors.fill: parent
            anchors.margins: 10
            columnSpacing: 10
            rowSpacing: 10
            
            Label { text: "标签名称:" }
            TextField {
                id: newTagName
                Layout.fillWidth: true
                placeholderText: "输入标签名称"
            }
            
            Label { text: "标签颜色:" }
            Rectangle {
                id: newTagColorRect
                Layout.preferredWidth: 100
                height: 30
                color: "#cccccc"
                border.width: 1
                border.color: "black"
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        colorDialog.currentColor = newTagColorRect.color;
                        colorDialog.targetRect = newTagColorRect;
                        colorDialog.open();
                    }
                }
            }
            
            Label { text: "描述:" }
            TextArea {
                id: newTagDescription
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                placeholderText: "输入标签描述"
                wrapMode: TextArea.Wrap
            }
            
            Item { Layout.columnSpan: 2; Layout.fillHeight: true }
            
            Button {
                text: "取消"
                Layout.alignment: Qt.AlignRight
                onClicked: newTagDialog.close()
            }
            
            Button {
                text: "创建"
                highlighted: true
                onClicked: {
                    var name = newTagName.text.trim();
                    if (name) {
                        var tagId = backend.createTag(name, newTagColorRect.color, newTagDescription.text);
                        if (tagId) {
                            loadTags();
                            newTagDialog.close();
                        } else {
                            errorDialog.showError("创建标签失败");
                        }
                    }
                }
            }
        }
    }
    
    // 编辑标签对话框
    Dialog {
        id: editTagDialog
        title: "编辑标签"
        width: 350
        height: 300
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property int tagId: -1
        property alias tagNameField: editTagName
        property alias tagDescField: editTagDescription
        property color tagColor: "#cccccc"
        
        GridLayout {
            columns: 2
            anchors.fill: parent
            anchors.margins: 10
            columnSpacing: 10
            rowSpacing: 10
            
            Label { text: "标签名称:" }
            TextField {
                id: editTagName
                Layout.fillWidth: true
                placeholderText: "输入标签名称"
            }
            
            Label { text: "标签颜色:" }
            Rectangle {
                id: editTagColorRect
                Layout.preferredWidth: 100
                height: 30
                color: editTagDialog.tagColor
                border.width: 1
                border.color: "black"
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        colorDialog.currentColor = editTagColorRect.color;
                        colorDialog.targetRect = editTagColorRect;
                        colorDialog.open();
                    }
                }
            }
            
            Label { text: "描述:" }
            TextArea {
                id: editTagDescription
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                placeholderText: "输入标签描述"
                wrapMode: TextArea.Wrap
            }
            
            Item { Layout.columnSpan: 2; Layout.fillHeight: true }
            
            Button {
                text: "删除标签"
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    deleteConfirmDialog.tagId = editTagDialog.tagId;
                    deleteConfirmDialog.open();
                    editTagDialog.close();
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                
                Button {
                    text: "取消"
                    onClicked: editTagDialog.close()
                }
                
                Button {
                    text: "保存"
                    highlighted: true
                    onClicked: {
                        var name = editTagName.text.trim();
                        if (name && editTagDialog.tagId > 0) {
                            var success = backend.updateTag(
                                editTagDialog.tagId, 
                                name, 
                                editTagColorRect.color, 
                                editTagDescription.text
                            );
                            
                            if (success) {
                                loadTags();
                                editTagDialog.close();
                            } else {
                                errorDialog.showError("更新标签失败");
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 确认删除对话框
    Dialog {
        id: deleteConfirmDialog
        title: "确认删除"
        width: 300
        height: 150
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape
        
        property int tagId: -1
        
        contentItem: ColumnLayout {
            spacing: 20
            
            Text {
                text: "确定要删除这个标签吗？所有关联的交易将失去这个标签。"
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
                        var success = backend.deleteTag(deleteConfirmDialog.tagId);
                        if (success) {
                            loadTags();
                            deleteConfirmDialog.close();
                        } else {
                            errorDialog.showError("删除标签失败");
                        }
                    }
                }
            }
        }
    }
    
    // 颜色选择对话框
    ColorDialog {
        id: colorDialog
        title: "选择颜色"
        
        property var targetRect: null
        
        onAccepted: {
            if (targetRect) {
                targetRect.color = color;
            }
        }
    }
} 