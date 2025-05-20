import QtQuick
import QtQuick.Window

// WindowChanger组件用于优化窗口拖动和调整大小的性能
Item {
    id: root
    
    // 目标窗口
    property var target: null
    
    // 跟踪窗口状态
    property bool isMoving: false
    property int lastX: 0
    property int lastY: 0
    property int startX: 0
    property int startY: 0
    
    // 屏幕刷新率适配
    property int updateInterval: 16 // 约60fps
    
    // 窗口移动优化
    Timer {
        id: moveTimer
        interval: root.updateInterval
        repeat: true
        running: root.isMoving
        
        onTriggered: {
            if (root.target && root.isMoving) {
                // 减少屏幕更新频率，提高拖动性能
                if (typeof root.target.update === "function") {
                    root.target.update();
                }
            }
        }
    }
    
    // 连接到窗口事件
    Component.onCompleted: {
        if (root.target) {
            // 窗口位置变化时的优化
            root.target.xChanged.connect(function() {
                handleWindowChange();
            });
            
            root.target.yChanged.connect(function() {
                handleWindowChange();
            });
            
            // 窗口大小变化时的优化
            root.target.widthChanged.connect(function() {
                optimizeRendering();
            });
            
            root.target.heightChanged.connect(function() {
                optimizeRendering();
            });
        }
    }
    
    // 处理窗口位置变化
    function handleWindowChange() {
        if (!root.isMoving) {
            root.isMoving = true;
            root.lastX = root.target.x;
            root.lastY = root.target.y;
            
            // 使用定时器跟踪窗口停止移动
            moveEndTimer.restart();
        } else {
            moveEndTimer.restart();
        }
    }
    
    // 检测窗口停止移动
    Timer {
        id: moveEndTimer
        interval: 100
        repeat: false
        
        onTriggered: {
            root.isMoving = false;
            optimizeRendering();
        }
    }
    
    // 优化渲染，减少不必要的更新
    function optimizeRendering() {
        if (root.target) {
            // 强制完整更新一次，确保显示正确
            if (typeof root.target.update === "function") {
                root.target.update();
            }
            
            // 优化窗口内容的渲染
            if (root.target.contentItem) {
                if (root.target.contentItem.layer) {
                    // 重置layer提高清晰度
                    root.target.contentItem.layer.enabled = false;
                    root.target.contentItem.layer.enabled = true;
                }
            }
        }
    }
} 