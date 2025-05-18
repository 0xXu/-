import QtQuick
import QtQuick.Controls

QtObject {
    id: themeManager
    
    // 当前主题
    property string currentTheme: "light"  // "light", "dark", "system"
    property bool isDarkTheme: currentTheme === "dark" || 
                               (currentTheme === "system" && systemThemeIsDark)
    
    // 系统主题检测（简化实现，实际应通过平台API检测）
    property bool systemThemeIsDark: false
    
    // 初始颜色
    property color primaryColor: "#2c3e50"
    property color accentColor: "#3498db"
    property color profitColor: "#e74c3c"
    property color lossColor: "#2ecc71"
    
    // 基于主题的派生颜色
    property color backgroundColor: isDarkTheme ? "#121212" : "#f5f5f5"
    property color cardColor: isDarkTheme ? "#1e1e1e" : "#ffffff"
    property color textColor: isDarkTheme ? "#e0e0e0" : "#333333"
    property color borderColor: isDarkTheme ? "#333333" : "#dddddd"
    
    // 加载主题
    function loadTheme() {
        // 从后端获取主题设置
        currentTheme = backend.getTheme()
        
        // 从后端获取颜色设置
        var colorSettings = backend.getColorSettings()
        primaryColor = colorSettings.primaryColor || "#2c3e50"
        accentColor = colorSettings.accentColor || "#3498db"
        profitColor = colorSettings.profitColor || "#e74c3c"
        lossColor = colorSettings.lossColor || "#2ecc71"
        
        updateTheme()
    }
    
    // 保存主题
    function saveTheme(themeName) {
        currentTheme = themeName
        backend.setTheme(themeName)
        updateTheme()
    }
    
    // 根据主题更新颜色
    function updateTheme() {
        // 更新派生颜色
        backgroundColor = isDarkTheme ? "#121212" : "#f5f5f5"
        cardColor = isDarkTheme ? "#1e1e1e" : "#ffffff"
        textColor = isDarkTheme ? "#e0e0e0" : "#333333"
        borderColor = isDarkTheme ? "#333333" : "#dddddd"
    }
    
    // 设置颜色
    function setColor(colorName, colorValue) {
        // 验证颜色名称
        if (colorName === "primaryColor") {
            primaryColor = colorValue
        } else if (colorName === "accentColor") {
            accentColor = colorValue
        } else if (colorName === "profitColor") {
            profitColor = colorValue
        } else if (colorName === "lossColor") {
            lossColor = colorValue
        } else {
            console.error("无效的颜色名称: " + colorName)
            return false
        }
        
        // 保存到后端
        backend.setColorSetting(colorName, colorValue)
        updateTheme()
        return true
    }
    
    // 重置为默认颜色
    function resetColors() {
        backend.resetColorSettings()
        loadTheme()
    }
} 