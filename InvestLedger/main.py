#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import datetime
import logging
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, QUrl, Signal, Slot, Property, QtMsgType, qInstallMessageHandler, Property

# 尝试导入Qt Charts模块
try:
    from PySide6 import QtCharts
    has_charts = True
    logging.info("Qt Charts 模块加载成功")
except ImportError:
    has_charts = False
    logging.warning("无法加载 Qt Charts 模块，图表功能将被禁用")

# 尝试导入QtGraphicalEffects模块（用于DropShadow等效果）
try:
    from PySide6 import QtQuickEffects
    has_effects = True
    
except ImportError:
    has_effects = False
    

# 版本信息
__version__ = "0.1.0"

# 导入自定义模块
from updater import UpdateChecker
from user import UserManager
from storage import DatabaseManager
from backup import BackupManager
import ui.backend as UIBackend

# 设置日志记录
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(os.getenv('APPDATA'), 'InvestLedger', 'app.log')),
        logging.StreamHandler()
    ]
)

# Qt消息处理器
def qt_message_handler(msg_type, context, message):
    """处理Qt框架产生的消息"""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
    
    # 定义消息类型
    msg_type_str = {
        QtMsgType.QtDebugMsg: "调试",
        QtMsgType.QtInfoMsg: "信息",
        QtMsgType.QtWarningMsg: "警告",
        QtMsgType.QtCriticalMsg: "严重",
        QtMsgType.QtFatalMsg: "致命"
    }.get(msg_type, "未知")
    
    # 格式化消息
    log_message = f"[{now}] [{msg_type_str}] {message}"
    
    # 添加上下文信息（如果有）
    if context.file:
        log_message += f" (文件: {context.file}, 行: {context.line})"
    
    # 控制台输出
    print(log_message)
    
    # 可选：写入日志文件
    log_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', 'logs')
    Path(log_dir).mkdir(parents=True, exist_ok=True)
    log_file = os.path.join(log_dir, f"qt_log_{datetime.datetime.now().strftime('%Y%m%d')}.txt")
    
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(f"{log_message}\n")
    
    # 如果是致命错误，终止程序
    if msg_type == QtMsgType.QtFatalMsg:
        sys.exit(-1)

# QML引擎状态变化处理
def log_qml_load_status(status, qml_url):
    """记录QML加载状态"""
    status_str = "Ready" if status else "Error"
    
    msg = f"QML加载状态: {status_str}, URL: {qml_url}"
    print(msg)
    
    # 如果是错误状态，记录到日志
    if not status:  # Error status
        print("===== QML 加载出错 =====")
        log_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', 'logs')
        Path(log_dir).mkdir(parents=True, exist_ok=True)
        log_file = os.path.join(log_dir, f"qml_errors_{datetime.datetime.now().strftime('%Y%m%d')}.txt")
        
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')}] {msg}\n")
        print("===================")

class MainApplication(QObject):
    """主应用程序类，负责初始化和协调各个模块"""
    
    def __init__(self):
        super().__init__()
        # 安装Qt消息处理器
        qInstallMessageHandler(qt_message_handler)
        
        self.app = QGuiApplication(sys.argv)
        self.engine = QQmlApplicationEngine()
        
        # 初始化各模块
        self.update_checker = UpdateChecker(__version__)
        self.user_manager = UserManager()
        self.db_manager = None  # 将在用户选择后初始化
        self.backup_manager = None  # 将在用户选择后初始化
        self.theme_manager = ThemeManager() # 创建ThemeManager实例
        
        # 注册Python后端到QML
        self.ui_backend = UIBackend.UIBackend(self)
        
    def start(self):
        """启动应用程序"""
        print("程序启动中...")
        
        # 检查更新
        try:
            self.update_checker.check_for_updates()
            print("更新检查完成")
        except Exception as e:
            print(f"更新检查出错: {e}")
        
        # 设置QML上下文属性
        context = self.engine.rootContext()
        context.setContextProperty("backend", self.ui_backend)
        context.setContextProperty("appVersion", __version__)
        context.setContextProperty("hasCharts", has_charts)  # 向QML传递Charts模块可用状态
        context.setContextProperty("hasEffects", has_effects)  # 向QML传递QtQuickEffects模块可用状态
        context.setContextProperty("themeManager", self.theme_manager) # 设置themeManager上下文属性
        
        # 注册QtCharts模块到QML引擎
        if has_charts:
            print("Qt Charts 模块已注册到QML引擎")
        
        # 注册QtQuickEffects模块到QML引擎
        if has_effects:
            print("QtQuickEffects 模块已注册到QML引擎")
        print("QML上下文设置完成")
        
        # 设置导入路径，确保QML可以找到组件
        ui_dir = os.path.join(os.path.dirname(__file__), "ui")
        self.engine.addImportPath(ui_dir)
        print(f"添加导入路径: {ui_dir}")
        
        # 设置QML加载状态监视
        self.engine.objectCreated.connect(lambda obj, url: log_qml_load_status(
            bool(obj), url.toString())
        )
        
        # 加载主QML文件 - 使用相对路径
        try:
            # 使用相对于 main.py 的路径
            base_dir = os.path.dirname(__file__)
            qml_file_path = os.path.join(base_dir, "ui", "app.qml") # 使用app.qml作为入口点
            qml_url = QUrl.fromLocalFile(qml_file_path) # 转换为 QUrl
            print(f"准备加载QML文件: {qml_url.toString()}")
            
            # 加载QML文件
            self.engine.load(qml_url)
            print("QML文件加载指令已发送")
            
            # 检查加载结果
            root_objects = self.engine.rootObjects()
            print(f"根对象数量: {len(root_objects)}")
            if root_objects:
                for i, obj in enumerate(root_objects):
                    print(f"  根对象 {i+1}: {obj}")
                print(f"QML成功加载，根对象数量: {len(root_objects)}")
            else:
                print("没有根对象加载成功，QML加载可能失败")
        except Exception as e:
            print(f"加载QML文件出错: {e}")
            log_qml_load_status(False, qml_file_path)
            sys.exit(-1)
        
        # 运行应用程序
        print("开始执行应用程序事件循环")
        return self.app.exec()
    
    def select_user(self, username):
        """选择用户并初始化数据库"""
        self.db_manager = DatabaseManager(username)
        
        # 初始化备份管理器
        app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
        self.backup_manager = BackupManager(app_data_dir, username)
        
        # 执行自动备份
        self._perform_auto_backup()
        
        return True
        
    def create_new_user(self, username):
        """创建新用户"""
        success = self.user_manager.create_user(username)
        if success:
            self.select_user(username)
        return success
    
    def _perform_auto_backup(self):
        """执行自动备份操作（如果启用）"""
        if self.backup_manager:
            try:
                self.backup_manager.auto_backup()
            except Exception as e:
                logging.error(f"自动备份失败: {e}")

class ThemeManager(QObject):
    def __init__(self):
        super().__init__()
        self._currentTheme = "light"
        self._primaryColor = "#2c3e50"
        self._accentColor = "#3498db"

    @Property(str, constant=True) # In a real app, use notify for changes
    def currentTheme(self):
        return self._currentTheme

    @Property(str, constant=True)
    def primaryColor(self):
        return self._primaryColor

    @Property(str, constant=True)
    def accentColor(self):
        return self._accentColor

    @Slot(str)
    def saveTheme(self, themeName):
        # This is a placeholder. In a real app, you would save the theme
        # to a persistent storage and potentially emit signals if properties change.
        print(f"ThemeManager: saveTheme called with {themeName}")
        self._currentTheme = themeName # Placeholder update

    @Slot(str, str)
    def setColor(self, colorName, colorValue):
        # This is a placeholder. In a real app, you would save the color
        # to a persistent storage and potentially emit signals if properties change.
        print(f"ThemeManager: setColor called for {colorName} with {colorValue}")
        if colorName == "primaryColor":
            self._primaryColor = colorValue # Placeholder update
        elif colorName == "accentColor":
            self._accentColor = colorValue # Placeholder update


def main():
    """程序入口函数"""
    # 确保应用程序数据目录存在
    app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
    Path(app_data_dir).mkdir(parents=True, exist_ok=True)
    
    # 创建并启动应用程序
    app = MainApplication()
    sys.exit(app.start())

if __name__ == "__main__":
    main()