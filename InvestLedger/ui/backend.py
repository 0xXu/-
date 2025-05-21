#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from PySide6.QtCore import QObject, Signal, Slot, Property, QDate, QUrl
from PySide6.QtGui import QGuiApplication

import datetime
import json
from pathlib import Path
import os

from analyzer import DataAnalyzer
from importer import DataImporter
from exporter import DataExporter, ExportFormat, ExportResult
from storage import Transaction
from tags import TagManager

class UIBackend(QObject):
    """UI后端桥接类，连接QML前端与Python后端"""
    
    # 信号定义
    usersChanged = Signal()  # 用户列表改变
    transactionsChanged = Signal()  # 交易列表改变
    transactionAdded = Signal()  # 添加了新交易
    importProgressChanged = Signal(int, int)  # 导入进度更新(成功数, 错误数)
    updateAvailable = Signal(str, str)  # 有更新可用(版本号, 更新说明)
    updateProgress = Signal(int)  # 更新下载进度
    errorOccurred = Signal(str)  # 发生错误
    messageReceived = Signal(str)  # 显示消息
    importPreviewReady = Signal(str)  # 导入预览数据JSON字符串
    
    def __init__(self, main_app):
        super().__init__()
        self.main_app = main_app
        self.current_user = None
        
        # 数据管理对象将在用户选择后初始化
        self.db_manager = None
        self.data_analyzer = None
        self.data_importer = None
        self.tag_manager = None
        self.data_exporter = None
    
    # 用户管理相关方法
    
    @Slot(result='QVariantList')
    def getUsers(self):
        """获取用户列表"""
        users = self.main_app.user_manager.get_users()
        return [{"name": name} for name in users]
    
    @Slot(str, result=bool)
    def createUser(self, username):
        """创建新用户"""
        success = self.main_app.create_new_user(username)
        if success:
            self.usersChanged.emit()
        return success
    
    @Slot(str, result=bool)
    def selectUser(self, username):
        """选择用户"""
        print(f"[UI] 选择用户: {username}")
        success = self.main_app.select_user(username)
        if success:
            self.current_user = username
            self.db_manager = self.main_app.db_manager
            
            # 创建数据库连接状态检查
            try:
                if not self.db_manager or not self.db_manager.conn:
                    print("[ERROR] 数据库管理器或连接为空")
                    self.errorOccurred.emit("数据库连接失败")
                    return False
                
                # 测试数据库连接是否可用
                cursor = self.db_manager.conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM transactions")
                count = cursor.fetchone()[0]
                print(f"[UI] 数据库连接测试成功，有 {count} 条交易记录")
            except Exception as e:
                print(f"[ERROR] 数据库连接测试失败: {e}")
                self.errorOccurred.emit(f"数据库连接测试失败: {e}")
                # 不要在这里返回False，我们仍然需要初始化其他组件
            
            # 初始化数据分析和导入器
            self.data_analyzer = DataAnalyzer(self.db_manager)
            self.data_importer = DataImporter(self.db_manager)
            
            # 初始化标签管理器
            if self.db_manager:
                self.tag_manager = TagManager(self.db_manager.db_path)
            
            # 初始化数据导出器
            self.data_exporter = DataExporter(self.db_manager)
            
            # 多次通知UI刷新数据，确保UI捕获到信号
            print("[UI] 发送数据变化信号...")
            self.transactionsChanged.emit()
            
            # 使用延迟触发额外的信号
            import threading
            def delayed_notify():
                import time
                for i in range(3):  # 尝试多次通知
                    time.sleep(0.5)  # 每次等待0.5秒
                    print(f"[UI] 发送延迟数据变化信号 #{i+1}")
                    self.transactionsChanged.emit()
            
            # 启动延迟通知线程
            threading.Thread(target=delayed_notify).start()
            
            print(f"[UI] 用户 {username} 选择成功")
            return True
        else:
            print(f"[ERROR] 选择用户 {username} 失败")
            return False
    
    @Slot(str, result=bool)
    def deleteUser(self, username):
        """删除用户"""
        success = self.main_app.user_manager.delete_user(username)
        if success:
            self.usersChanged.emit()
        return success
    
    @Slot(result=bool)
    def getCurrentUserSelected(self):
        """返回当前是否已选择用户"""
        return self.current_user is not None and self.db_manager is not None
    
    # 交易记录相关方法
    
    @Slot(str, str, str, float, float, str, float, str, result=bool)
    def addTransaction(self, date, asset_type, project_name, amount, unit_price, currency, profit_loss, notes):
        """添加交易记录"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        # 创建交易记录对象
        transaction = Transaction(
            date=date,
            asset_type=asset_type,
            project_name=project_name,
            amount=amount,
            unit_price=unit_price,
            currency=currency,
            profit_loss=profit_loss,
            notes=notes
        )
        
        # 保存到数据库
        success = self.db_manager.add_transaction(transaction) is not None
        if success:
            self.transactionAdded.emit()
            self.transactionsChanged.emit()
            # 检查预算告警
            self._check_budget_alerts()
        
        return success
    
    # 撤销/重做相关方法
    
    @Property(bool, notify=transactionsChanged)
    def canUndo(self):
        """检查是否可以撤销操作"""
        if not self.db_manager:
            return False
        return self.db_manager.can_undo()
    
    @Property(bool, notify=transactionsChanged)
    def canRedo(self):
        """检查是否可以重做操作"""
        if not self.db_manager:
            return False
        return self.db_manager.can_redo()
    
    @Slot(result=bool)
    def undo(self):
        """撤销上一次操作"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        success = self.db_manager.undo()
        if success:
            self.transactionsChanged.emit()
            # 检查预算告警
            self._check_budget_alerts()
        
        return success
    
    @Slot(result=bool)
    def redo(self):
        """重做上一次撤销的操作"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        success = self.db_manager.redo()
        if success:
            self.transactionsChanged.emit()
            # 检查预算告警
            self._check_budget_alerts()
        
        return success
    
    @Slot()
    def refreshCurrentView(self):
        """刷新当前视图"""
        self.transactionsChanged.emit()
    
    @Slot(int, result=bool)
    def deleteTransaction(self, transaction_id):
        """删除交易记录"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        success = self.db_manager.delete_transaction(transaction_id)
        if success:
            self.transactionsChanged.emit()
        
        return success
    
    @Slot(int, str, str, str, float, float, str, float, str, result=bool)
    def updateTransaction(self, id, date, asset_type, project_name, amount, unit_price, currency, profit_loss, notes):
        """更新交易记录"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        # 创建交易记录对象
        transaction = Transaction(
            id=id,
            date=date,
            asset_type=asset_type,
            project_name=project_name,
            amount=amount,
            unit_price=unit_price,
            currency=currency,
            profit_loss=profit_loss,
            notes=notes
        )
        
        # 更新数据库
        success = self.db_manager.update_transaction(transaction)
        if success:
            self.transactionsChanged.emit()
        
        return success
    
    @Slot(str, str, str, int, int, result='QVariantList')
    def getTransactions(self, start_date, end_date, asset_type, limit, offset):
        """获取交易记录列表"""
        print(f"UI调用getTransactions: start_date={start_date}, end_date={end_date}, asset_type={asset_type}, limit={limit}, offset={offset}")
        
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            print("错误: 未选择用户")
            return []
        
        filters = []
        
        # 添加日期过滤条件
        if start_date:
            filters.append(('date', '>=', start_date))
        if end_date:
            filters.append(('date', '<=', end_date))
        
        # 添加资产类型过滤条件
        if asset_type and asset_type != "全部":
            filters.append(('asset_type', '=', asset_type))
        
        # 查询交易记录
        transactions = self.db_manager.get_transactions(
            filters=filters,
            order_by="date DESC",
            limit=limit if limit > 0 else None,
            offset=offset if offset > 0 else None
        )
        
        # 转换为QML可用的格式
        result = []
        for trans in transactions:
            # 获取交易对应的标签
            tags = self.tag_manager.get_transaction_tags(trans.id) if self.tag_manager else []
            
            result.append({
                "id": trans.id,
                "date": trans.date,
                "asset_type": trans.asset_type,
                "project_name": trans.project_name,
                "amount": trans.amount,
                "unit_price": trans.unit_price,
                "currency": trans.currency,
                "profit_loss": trans.profit_loss,
                "tags": tags,
                "notes": trans.notes
            })
        
        print(f"UI getTransactions 返回 {len(result)} 条记录")
        return result
    
    @Slot(str, str, str, result=int)
    def getTransactionsCount(self, start_date, end_date, asset_type):
        """获取交易记录总数，支持过滤条件"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return 0
        
        filters = []
        
        # 添加日期过滤条件
        if start_date:
            filters.append(('date', '>=', start_date))
        if end_date:
            filters.append(('date', '<=', end_date))
        
        # 添加资产类型过滤条件
        if asset_type and asset_type != "全部":
            filters.append(('asset_type', '=', asset_type))
        
        # 查询交易记录总数
        try:
            cursor = self.db_manager.conn.cursor()
            
            # 构建SQL查询
            query = "SELECT COUNT(*) as count FROM transactions"
            parameters = []
            
            # 处理过滤条件
            if filters:
                where_clauses = []
                for field, operator, value in filters:
                    where_clauses.append(f"{field} {operator} ?")
                    parameters.append(value)
                
                if where_clauses:
                    query += " WHERE " + " AND ".join(where_clauses)
            
            # 执行查询
            cursor.execute(query, parameters)
            result = cursor.fetchone()
            return result['count'] if result else 0
        except Exception as e:
            print(f"获取交易记录总数失败: {e}")
            return 0
    
    # 预算告警相关方法
    
    def _check_budget_alerts(self):
        """检查预算告警情况"""
        if not self.data_analyzer:
            return
        
        # 获取预算告警
        alerts = self.data_analyzer.check_budget_alerts()
        if alerts:
            # 更新UI中的告警信息
            QGuiApplication.instance().findChild(QObject, "mainWindow").setProperty("budgetAlerts", alerts)
    
    @Slot(float, result=bool)
    def setBudgetAlertThreshold(self, threshold):
        """设置预算告警阈值"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return False
        
        return self.data_analyzer.set_budget_alert_threshold(threshold)
    
    @Slot(result=float)
    def getBudgetAlertThreshold(self):
        """获取当前预算告警阈值"""
        if not self.data_analyzer:
            return 0.8  # 默认值
        
        return self.data_analyzer.budget_alert_threshold
    
    @Slot(result='QVariantList')
    def getAssetTypes(self):
        """获取资产类别列表"""
        if not self.db_manager:
            return []
        
        asset_types = self.db_manager.get_asset_types()
        return asset_types
    
    # 标签相关方法
    
    @Slot(result='QVariantList')
    def getAllTags(self):
        """获取所有标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return []
            
        return self.tag_manager.get_all_tags()
    
    @Slot(int, result='QVariantMap')
    def getTagById(self, tag_id):
        """根据ID获取标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return {}
            
        tag = self.tag_manager.get_tag_by_id(tag_id)
        return tag or {}
    
    @Slot(str, str, str, result=int)
    def createTag(self, name, color, description):
        """创建新标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return -1
            
        tag_id = self.tag_manager.create_tag(name, color, description)
        return tag_id if tag_id is not None else -1
    
    @Slot(int, str, str, str, result=bool)
    def updateTag(self, tag_id, name, color, description):
        """更新标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.tag_manager.update_tag(tag_id, name, color, description)
        return success
    
    @Slot(int, result=bool)
    def deleteTag(self, tag_id):
        """删除标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.tag_manager.delete_tag(tag_id)
        return success
    
    @Slot(str, result='QVariantList')
    def searchTags(self, query):
        """搜索标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return []
            
        return self.tag_manager.search_tags(query)
    
    @Slot(int, result='QVariantList')
    def getTransactionTags(self, transaction_id):
        """获取交易的所有标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return []
            
        return self.tag_manager.get_transaction_tags(transaction_id)
    
    @Slot(int, 'QVariantList', result=bool)
    def replaceTransactionTags(self, transaction_id, tag_ids):
        """替换交易的所有标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.tag_manager.replace_transaction_tags(transaction_id, tag_ids)
        if success:
            self.transactionsChanged.emit()
        return success
    
    @Slot(int, int, result=bool)
    def addTagToTransaction(self, transaction_id, tag_id):
        """为交易添加标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.tag_manager.add_tag_to_transaction(transaction_id, tag_id)
        if success:
            self.transactionsChanged.emit()
        return success
    
    @Slot(int, int, result=bool)
    def removeTagFromTransaction(self, transaction_id, tag_id):
        """从交易移除标签"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.tag_manager.remove_tag_from_transaction(transaction_id, tag_id)
        if success:
            self.transactionsChanged.emit()
        return success
    
    @Slot(int, result='QVariantList')
    def getTaggedTransactions(self, tag_id):
        """获取带有指定标签的所有交易"""
        if not self.tag_manager:
            self.errorOccurred.emit("未选择用户")
            return []
            
        transaction_ids = self.tag_manager.get_tagged_transactions(tag_id)
        
        # 查询这些交易的详细信息
        transactions = []
        for tid in transaction_ids:
            trans = self.db_manager.get_transaction_by_id(tid)
            if trans:
                transactions.append({
                    "id": trans.id,
                    "date": trans.date,
                    "asset_type": trans.asset_type,
                    "project_name": trans.project_name,
                    "amount": trans.amount,
                    "unit_price": trans.unit_price,
                    "currency": trans.currency,
                    "profit_loss": trans.profit_loss,
                    "notes": trans.notes
                })
        
        return transactions
    
    @Slot(str, result=None)
    def showMessage(self, message):
        """显示消息"""
        self.messageReceived.emit(message)
    
    # 数据导入相关方法
    
    @Slot(str, str, str, result='QVariantList')
    def importCSVData(self, file_content, delimiter, mapping_json):
        """导入CSV数据"""
        if not self.data_importer:
            self.errorOccurred.emit("未选择用户")
            return {"success": False, "message": "未选择用户"}
        
        # 解析字段映射
        mapping = json.loads(mapping_json) if mapping_json else None
        
        # 导入数据
        result = self.data_importer.import_csv(file_content, delimiter, mapping)
        
        # 保存到数据库
        if len(result.parsed_data) > 0:
            saved_count = self.data_importer.save_imported_data(result)
            # 通知UI更新
            self.transactionsChanged.emit()
            
            # 返回结果
            return {
                "success": True,
                "success_count": saved_count,
                "error_count": len(result.error_data),
                "skipped_count": len(result.skipped_data),
                "errors": [
                    {
                        "row": error["row_index"],
                        "data": str(error["row_data"]),
                        "message": error["error_message"]
                    }
                    for error in result.error_data
                ]
            }
        else:
            return {
                "success": False,
                "message": "没有成功导入的数据",
                "error_count": len(result.error_data),
                "skipped_count": len(result.skipped_data),
                "errors": [
                    {
                        "row": error["row_index"],
                        "data": str(error["row_data"]),
                        "message": error["error_message"]
                    }
                    for error in result.error_data
                ]
            }
    
    @Slot(str, result='QVariantMap')
    def importClipboardText(self, text):
        """导入剪贴板文本"""
        if not self.data_importer:
            self.errorOccurred.emit("未选择用户")
            return {"success": False, "message": "未选择用户"}
        
        # 导入数据
        result = self.data_importer.batch_process_clipboard_data(text)
        
        # 保存到数据库
        if len(result.parsed_data) > 0:
            saved_count = self.data_importer.save_imported_data(result)
            # 通知UI更新
            self.transactionsChanged.emit()
            
            # 返回结果
            return {
                "success": True,
                "success_count": saved_count,
                "error_count": len(result.error_data),
                "skipped_count": len(result.skipped_data),
                "errors": [
                    {
                        "row": error["row_index"],
                        "data": str(error["row_data"]),
                        "message": error["error_message"]
                    }
                    for error in result.error_data
                ]
            }
        else:
            return {
                "success": False,
                "message": "没有成功导入的数据",
                "error_count": len(result.error_data),
                "skipped_count": len(result.skipped_data),
                "errors": [
                    {
                        "row": error["row_index"],
                        "data": str(error["row_data"]),
                        "message": error["error_message"]
                    }
                    for error in result.error_data
                ]
            }
    
    @Slot(str, int, str, result='QVariantMap')
    def importFromFile(self, file_url, header_row, file_type):
        """从文件导入数据
        
        Args:
            file_url: 文件URL
            header_row: 表头行索引
            file_type: 文件类型(csv, tsv, excel, txt)
            
        Returns:
            dict: 导入结果
        """
        if not self.data_importer:
            self.errorOccurred.emit("未选择用户")
            return {"success": False, "message": "未选择用户"}
        
        try:
            # 转换文件URL为本地路径
            file_path = QUrl(file_url).toLocalFile()
            
            # 根据文件类型选择导入方法
            result = self.data_importer.import_file(
                file_path=file_path, 
                file_type=file_type,
                header_row=header_row
            )
            
            # 保存到数据库
            if len(result.parsed_data) > 0:
                saved_count = self.data_importer.save_imported_data(result)
                # 通知UI更新
                self.transactionsChanged.emit()
                
                # 返回结果
                return {
                    "success": True,
                    "success_count": saved_count,
                    "error_count": len(result.error_data),
                    "skipped_count": len(result.skipped_data),
                    "errors": [
                        {
                            "row": error["row_index"],
                            "data": str(error["row_data"]),
                            "message": error["error_message"]
                        }
                        for error in result.error_data
                    ]
                }
            else:
                return {
                    "success": False,
                    "message": "没有成功导入的数据",
                    "error_count": len(result.error_data),
                    "skipped_count": len(result.skipped_data),
                    "errors": [
                        {
                            "row": error["row_index"],
                            "data": str(error["row_data"]),
                            "message": error["error_message"]
                        }
                        for error in result.error_data
                    ]
                }
        except Exception as e:
            self.errorOccurred.emit(f"导入文件失败: {str(e)}")
            return {
                "success": False,
                "message": f"导入文件失败: {str(e)}"
            }
    
    @Slot(str, str, str, int, result=str)
    def generateFilePreview(self, file_url, file_type, delimiter=',', lines=10):
        """生成文件预览
        
        Args:
            file_url: 文件URL
            file_type: 文件类型，可选值：'csv', 'tsv', 'excel', 'txt'
            delimiter: 分隔符，用于CSV/TSV文件
            lines: 预览行数
            
        Returns:
            str: 预览数据JSON字符串
        """
        if not self.data_importer:
            self.errorOccurred.emit("未选择用户")
            return json.dumps({
                "success": False,
                "error": "未选择用户"
            })
        
        try:
            # 转换文件URL为本地路径
            file_path = QUrl(file_url).toLocalFile()
            
            # 生成预览
            preview_data = self.data_importer.generate_preview(
                file_path, 
                file_type=file_type,
                delimiter=delimiter, 
                lines=lines
            )
            
            # 转换为JSON字符串
            preview_json = json.dumps(preview_data)
            
            # 发送预览就绪信号
            self.importPreviewReady.emit(preview_json)
            
            return preview_json
        except Exception as e:
            error_data = {
                "success": False,
                "error": str(e)
            }
            return json.dumps(error_data)
    
    @Slot(str, int, result='QVariantMap')
    def importFromText(self, text_content, format_type_index):
        """从文本导入数据
        
        Args:
            text_content: 文本内容
            format_type_index: 格式类型索引(0=自动识别, 1=CSV/TSV, 2=自定义格式)
            
        Returns:
            dict: 导入结果
        """
        if not self.data_importer:
            self.errorOccurred.emit("未选择用户")
            return {"success": False, "message": "未选择用户"}
        
        try:
            # 根据格式类型索引确定导入格式
            format_type = "auto"
            if format_type_index == 1:
                # 检测是否包含制表符
                if '\t' in text_content:
                    format_type = "tsv"
                else:
                    format_type = "csv"
            elif format_type_index == 2:
                format_type = "custom"
            
            # 导入数据
            result = self.data_importer.import_text(text_content, format_type=format_type)
            
            # 保存到数据库
            if len(result.parsed_data) > 0:
                saved_count = self.data_importer.save_imported_data(result)
                # 通知UI更新
                self.transactionsChanged.emit()
                
                # 返回结果
                return {
                    "success": True,
                    "success_count": saved_count,
                    "error_count": len(result.error_data),
                    "skipped_count": len(result.skipped_data),
                    "errors": [
                        {
                            "row": error["row_index"],
                            "data": str(error["row_data"]),
                            "message": error["error_message"]
                        }
                        for error in result.error_data
                    ]
                }
            else:
                return {
                    "success": False,
                    "message": "没有成功导入的数据",
                    "error_count": len(result.error_data),
                    "skipped_count": len(result.skipped_data),
                    "errors": [
                        {
                            "row": error["row_index"],
                            "data": str(error["row_data"]),
                            "message": error["error_message"]
                        }
                        for error in result.error_data
                    ]
                }
        except Exception as e:
            self.errorOccurred.emit(f"导入文本失败: {str(e)}")
            return {
                "success": False,
                "message": f"导入文本失败: {str(e)}"
            }
    
    # 统计分析相关方法
    
    @Slot(str, str, str, result='QVariantList')
    def getProfitLossSummary(self, period, start_date, end_date):
        """获取盈亏汇总"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return []
        
        summary = self.data_analyzer.get_profit_loss_summary(period, start_date, end_date)
        return summary
    
    @Slot(str, str, result='QVariantList')
    def getAssetTypeDistribution(self, start_date, end_date):
        """获取资产类别分布"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return []
        
        distribution = self.data_analyzer.get_asset_type_distribution(start_date, end_date)
        return distribution
    
    @Slot(int, int, result='QVariantMap')
    def getMonthlyGoalComparison(self, year, month):
        """获取月度目标比较"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return {}
        
        comparison = self.data_analyzer.get_monthly_goal_comparison(year, month)
        return comparison
    
    @Slot(int, result='QVariantMap')
    def getYearlyGoalComparison(self, year):
        """获取年度目标比较"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return {}
        
        comparison = self.data_analyzer.get_yearly_goal_comparison(year)
        return comparison
    
    @Slot(int, bool, str, str, result='QVariantList')
    def getTopProjects(self, limit, is_profit, start_date, end_date):
        """获取盈利/亏损最多的项目"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return []
        
        projects = self.data_analyzer.get_top_projects(limit, is_profit, start_date, end_date)
        return projects
    
    @Slot(result='QVariantList')
    def getMonthlyProfitLossLastYear(self):
        """获取近一年每个月的盈亏数据"""
        if not self.data_analyzer:
            self.errorOccurred.emit("未选择用户")
            return []
        
        monthly_data = self.data_analyzer.get_monthly_profit_loss_last_year()
        return monthly_data
    
    # 预算目标相关方法
    
    @Slot(int, int, float, result=bool)
    def setBudgetGoal(self, year, month, goal_amount):
        """设置月度预算目标"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        success = self.db_manager.set_budget_goal(year, month, goal_amount)
        return success
    
    @Slot(int, float, result=bool)
    def setYearlyBudgetGoal(self, year, goal_amount):
        """设置年度预算目标"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
        
        success = self.db_manager.set_yearly_budget_goal(year, goal_amount)
        return success
    
    @Slot(int, int, result=float)
    def getBudgetGoal(self, year, month):
        """获取月度预算目标"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return 0.0
        
        goal = self.db_manager.get_budget_goal(year, month)
        return goal if goal is not None else 0.0
    
    @Slot(int, result=float)
    def getYearlyBudgetGoal(self, year):
        """获取年度预算目标"""
        if not self.db_manager:
            self.errorOccurred.emit("未选择用户")
            return 0.0
        
        goal = self.db_manager.get_yearly_budget_goal(year)
        return goal if goal is not None else 0.0
    
    # 系统功能相关方法
    
    @Slot(result=bool)
    def backupDatabase(self):
        """立即创建数据库备份"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        backup_path = self.main_app.backup_manager.create_backup()
        return backup_path is not None
    
    @Slot(result='QVariantList')
    def getBackups(self):
        """获取备份列表"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return []
            
        backups = self.main_app.backup_manager.get_backups()
        result = []
        
        for backup in backups:
            # 格式化时间戳为可读形式
            try:
                timestamp = backup['timestamp']
                year = int(timestamp[0:4])
                month = int(timestamp[4:6])
                day = int(timestamp[6:8])
                hour = int(timestamp[9:11])
                minute = int(timestamp[11:13])
                second = int(timestamp[13:15])
                
                formatted_time = f"{year}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:{second:02d}"
            except:
                # 如果解析失败，使用文件的修改时间
                import time
                formatted_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(backup['modified_time']))
                
            # 格式化文件大小
            size_kb = backup['size'] / 1024
            if size_kb < 1024:
                size_str = f"{size_kb:.2f} KB"
            else:
                size_mb = size_kb / 1024
                size_str = f"{size_mb:.2f} MB"
                
            result.append({
                'filename': backup['filename'],
                'path': backup['path'],
                'size': backup['size'],
                'size_str': size_str,
                'timestamp': backup['timestamp'],
                'formatted_time': formatted_time
            })
            
        return result
    
    @Slot(str, result=bool)
    def restoreBackup(self, backup_path):
        """从备份恢复数据库"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        success = self.main_app.backup_manager.restore_backup(backup_path)
        if success:
            # 重新加载数据
            self.transactionsChanged.emit()
        return success
    
    @Slot(int, result=int)
    def cleanupOldBackups(self, keep_days):
        """清理旧备份文件"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return 0
            
        return self.main_app.backup_manager.cleanup_old_backups(keep_days)
    
    @Slot(bool, result=bool)
    def setAutoBackup(self, enabled):
        """设置是否启用自动备份"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        return self.main_app.backup_manager.set_auto_backup(enabled)
    
    @Slot(int, result=bool)
    def setKeepDays(self, days):
        """设置备份保留天数"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        return self.main_app.backup_manager.set_keep_days(days)
    
    @Slot(result='QVariantMap')
    def getBackupSettings(self):
        """获取备份设置"""
        if not self.main_app.backup_manager:
            self.errorOccurred.emit("未选择用户")
            return {'auto_backup': False, 'keep_days': 7, 'has_backup': False}
            
        config = self.main_app.backup_manager.config
        backup_info = self.main_app.backup_manager.get_last_backup_info()
        
        return {
            'auto_backup': config['auto_backup'],
            'keep_days': config['keep_days'],
            'has_backup': backup_info['has_backup'],
            'last_backup': backup_info['last_backup'],
            'backup_count': backup_info['backup_count']
        }
    
    @Slot(result=bool)
    def checkForUpdates(self):
        """检查更新"""
        return self.main_app.update_checker.check_for_updates(silent=False)
    
    @Slot(bool, result=bool)
    def downloadUpdate(self, auto_restart):
        """下载并安装更新"""
        return self.main_app.update_checker.download_and_install_update(auto_restart)
    
    # 主题与外观相关方法
    
    @Slot(str, result=bool)
    def setTheme(self, theme_name):
        """设置主题"""
        if not self.main_app.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        # 保存主题设置到用户配置
        try:
            user_config_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', self.current_user)
            config_file = os.path.join(user_config_dir, 'ui_config.json')
            
            # 读取现有配置
            config = {}
            if os.path.exists(config_file):
                try:
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config = json.load(f)
                except:
                    pass
            
            # 更新主题设置
            config['theme'] = theme_name
            
            # 保存配置
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, ensure_ascii=False, indent=2)
                
            return True
        except Exception as e:
            self.errorOccurred.emit(f"保存主题设置失败: {e}")
            return False
    
    @Slot(result=str)
    def getTheme(self):
        """获取当前主题"""
        if not self.current_user:
            return "light"  # 默认主题
            
        # 读取用户配置
        try:
            user_config_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', self.current_user)
            config_file = os.path.join(user_config_dir, 'ui_config.json')
            
            if os.path.exists(config_file):
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    return config.get('theme', 'light')
            
            return "light"  # 默认主题
        except:
            return "light"  # 默认主题
    
    @Slot(str, str, result=bool)
    def setColorSetting(self, key, color_value):
        """设置颜色配置"""
        if not self.main_app.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        # 允许的颜色配置键
        allowed_keys = ['primaryColor', 'accentColor', 'profitColor', 'lossColor']
        if key not in allowed_keys:
            self.errorOccurred.emit(f"无效的颜色配置键: {key}")
            return False
            
        # 保存颜色设置到用户配置
        try:
            user_config_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', self.current_user)
            config_file = os.path.join(user_config_dir, 'ui_config.json')
            
            # 读取现有配置
            config = {}
            if os.path.exists(config_file):
                try:
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config = json.load(f)
                except:
                    pass
            
            # 确保colors配置项存在
            if 'colors' not in config:
                config['colors'] = {}
                
            # 更新颜色设置
            config['colors'][key] = color_value
            
            # 保存配置
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, ensure_ascii=False, indent=2)
                
            return True
        except Exception as e:
            self.errorOccurred.emit(f"保存颜色设置失败: {e}")
            return False
    
    @Slot(result='QVariantMap')
    def getColorSettings(self):
        """获取颜色配置"""
        # 默认颜色配置
        default_colors = {
            'primaryColor': "#2c3e50",
            'accentColor': "#3498db",
            'profitColor': "#e74c3c",
            'lossColor': "#2ecc71"
        }
        
        if not self.current_user:
            return default_colors
            
        # 读取用户配置
        try:
            user_config_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', self.current_user)
            config_file = os.path.join(user_config_dir, 'ui_config.json')
            
            if os.path.exists(config_file):
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    colors = config.get('colors', {})
                    
                    # 合并默认颜色和用户配置的颜色
                    result = default_colors.copy()
                    result.update(colors)
                    return result
            
            return default_colors
        except:
            return default_colors
    
    @Slot(result=bool)
    def resetColorSettings(self):
        """重置颜色配置为默认值"""
        if not self.main_app.db_manager:
            self.errorOccurred.emit("未选择用户")
            return False
            
        # 保存颜色设置到用户配置
        try:
            user_config_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', self.current_user)
            config_file = os.path.join(user_config_dir, 'ui_config.json')
            
            # 读取现有配置
            config = {}
            if os.path.exists(config_file):
                try:
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config = json.load(f)
                except:
                    pass
            
            # 删除颜色配置，使用默认值
            if 'colors' in config:
                del config['colors']
            
            # 保存配置
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, ensure_ascii=False, indent=2)
                
            return True
        except Exception as e:
            self.errorOccurred.emit(f"重置颜色设置失败: {e}")
            return False
    
    # 数据导出相关方法
    
    @Slot(str, str, str, str, bool, bool, result='QVariantMap')
    def exportTransactions(self, format_name, file_path, start_date, end_date, include_header, include_summary):
        """
        导出交易数据
        
        Parameters:
        - format_name: 导出格式名称 ("csv", "excel", "pdf")
        - file_path: 导出文件路径
        - start_date: 开始日期过滤
        - end_date: 结束日期过滤
        - include_header: 是否包含表头
        - include_summary: 是否包含汇总信息
        
        Returns:
        - 导出结果 {success: bool, message: string, file_path: string}
        """
        if not self.data_exporter:
            self.errorOccurred.emit("未选择用户")
            return {"success": False, "message": "未选择用户", "file_path": ""}
        
        # 构建过滤条件
        filters = []
        if start_date:
            filters.append(('date', '>=', start_date))
        if end_date:
            filters.append(('date', '<=', end_date))
        
        # 确定导出格式
        export_format = None
        if format_name.lower() == "csv":
            export_format = ExportFormat.CSV
        elif format_name.lower() == "excel":
            export_format = ExportFormat.EXCEL
        elif format_name.lower() == "pdf":
            export_format = ExportFormat.PDF
        else:
            self.errorOccurred.emit(f"不支持的导出格式: {format_name}")
            return {"success": False, "message": f"不支持的导出格式: {format_name}", "file_path": ""}
        
        # 执行导出
        result = self.data_exporter.export_transactions(
            export_format=export_format,
            file_path=file_path,
            filters=filters,
            include_header=include_header,
            summary=include_summary
        )
        
        # 返回结果
        return {
            "success": result.success,
            "message": result.message if result.message else "",
            "file_path": result.file_path if result.file_path else ""
        }
    
    @Slot(result='QVariantMap')
    def getExportCapabilities(self):
        """
        获取导出功能支持情况
        
        Returns:
        - 支持的导出格式 {csv: true, excel: true|false, pdf: true|false}
        """
        from exporter import has_excel, has_pdf
        
        return {
            "csv": True,
            "excel": has_excel,
            "pdf": has_pdf
        }