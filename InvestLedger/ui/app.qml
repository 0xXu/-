import QtQuick
import QtQuick.Window

// App入口点
Item {
    id: appRoot
    
    // 全局错误对话框引用
    property var errorDialogRef: null
    
    Component.onCompleted: {
        // 初始化用户选择窗口
        createUserSelectWindow();
    }
    
    // 创建用户选择窗口
    function createUserSelectWindow() {
        var component = Qt.createComponent("UserSelectWindow.qml");
        if (component.status === Component.Ready) {
            // 先创建主窗口但保持不可见
            var mainWindowComponent = Qt.createComponent("main.qml");
            if (mainWindowComponent.status === Component.Ready) {
                var mainWindowObj = mainWindowComponent.createObject(null);
                if (mainWindowObj) {
                    // 创建用户选择窗口并传递主窗口引用
                    var userSelectWindow = component.createObject(null, {
                        "mainWindow": mainWindowObj,
                        "theme": mainWindowObj.theme,
                        "errorDialog": mainWindowObj.errorDialog
                    });
                    
                    if (!userSelectWindow) {
                        console.error("错误: 无法创建用户选择窗口!");
                        if (mainWindowObj.errorDialog) {
                            mainWindowObj.errorDialog.showError("无法创建用户选择窗口，应用程序将退出。");
                            errorDialogRef = mainWindowObj.errorDialog;
                        }
                    } else {
                        // 保存错误对话框引用
                        errorDialogRef = mainWindowObj.errorDialog;
                    }
                } else {
                    console.error("错误: 无法创建主窗口!");
                }
            } else {
                console.error("错误: 加载主窗口组件失败: " + mainWindowComponent.errorString());
            }
        } else {
            console.error("错误: 加载用户选择窗口组件失败: " + component.errorString());
        }
    }
} 