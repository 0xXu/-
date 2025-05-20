import QtQuick
import QtQuick.Window

// App入口点
Item {
    id: appRoot
    
    // 全局错误对话框引用
    property var errorDialogRef: null
    property var userSelectWindowRef: null
    property var mainWindowRef: null
    
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
                mainWindowRef = mainWindowComponent.createObject(null);
                if (mainWindowRef) {
                    // 监听主窗口的visible属性变化
                    mainWindowRef.visibleChanged.connect(function() {
                        console.log("主窗口可见性变化:", mainWindowRef.visible);
                    });
                    
                    // 创建用户选择窗口并传递主窗口引用
                    userSelectWindowRef = component.createObject(null, {
                        "mainWindow": mainWindowRef,
                        "theme": mainWindowRef.theme
                    });
                    
                    if (userSelectWindowRef) {
                        // 连接用户选择窗口的userSelected信号
                        userSelectWindowRef.userSelected.connect(function(username) {
                            console.log("用户选择了:", username);
                            
                            // 先选择用户，这将触发数据加载
                            mainWindowRef.selectUser(username);
                            
                            // 创建一个循环检查定时器，确保主窗口显示
                            var checkVisibleTimer = Qt.createQmlObject(
                                'import QtQuick; Timer {interval: 300; repeat: true;}', 
                                appRoot
                            );
                            
                            var checkCount = 0;
                            checkVisibleTimer.triggered.connect(function() {
                                checkCount++;
                                console.log("检查主窗口可见性:", mainWindowRef.visible, "尝试次数:", checkCount);
                                
                                if (mainWindowRef.visible) {
                                    // 主窗口已显示，停止计时器并关闭选择窗口
                                    checkVisibleTimer.stop();
                                    userSelectWindowRef.close();
                                    console.log("主窗口已显示，关闭用户选择窗口");
                                } else if (checkCount >= 10) {
                                    // 超过尝试次数，强制显示主窗口
                                    console.log("强制显示主窗口");
                                    mainWindowRef.visible = true;
                                    checkVisibleTimer.stop();
                                    userSelectWindowRef.close();
                                }
                            });
                            
                            checkVisibleTimer.start();
                        });
                        
                        // 用户选择窗口关闭时，如果主窗口还不可见，则退出应用
                        userSelectWindowRef.closing.connect(function(close) {
                            if (!mainWindowRef.visible) {
                                Qt.quit();
                            }
                        });
                    } else {
                        console.error("创建用户选择窗口失败");
                    }
                } else {
                    console.error("创建主窗口失败");
                }
            } else {
                console.error("加载main.qml失败:", mainWindowComponent.errorString());
            }
        } else {
            console.error("加载UserSelectWindow.qml失败:", component.errorString());
        }
    }
} 