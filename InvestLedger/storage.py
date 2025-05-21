#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sqlite3
import json
import datetime
import shutil
from pathlib import Path

class Transaction:
    """交易记录模型类"""
    
    def __init__(self, id=None, date=None, asset_type=None, project_name=None, 
                 amount=None, unit_price=None, currency=None, profit_loss=None, 
                 tags=None, notes=None):
        self.id = id
        self.date = date or datetime.date.today().isoformat()
        self.asset_type = asset_type or "股票"
        self.project_name = project_name or ""
        self.amount = amount or 0
        self.unit_price = unit_price or 0
        self.currency = currency or "CNY"
        self.profit_loss = profit_loss or 0
        self.tags = tags or []
        self.notes = notes or ""
    
    def to_dict(self):
        """将对象转换为字典"""
        return {
            "id": self.id,
            "date": self.date,
            "asset_type": self.asset_type,
            "project_name": self.project_name,
            "amount": self.amount,
            "unit_price": self.unit_price,
            "currency": self.currency,
            "profit_loss": self.profit_loss,
            "tags": json.dumps(self.tags, ensure_ascii=False),
            "notes": self.notes
        }
    
    @staticmethod
    def from_dict(data):
        """从字典创建对象"""
        transaction = Transaction()
        for key, value in data.items():
            if key == 'tags' and isinstance(value, str):
                setattr(transaction, key, json.loads(value))
            else:
                setattr(transaction, key, value)
        return transaction

class DatabaseManager:
    """数据库管理类，负责SQLite连接和CRUD操作"""
    
    def __init__(self, username):
        """初始化数据库管理器"""
        print(f"[DB] 初始化用户 {username} 的数据库管理器")
        self.app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
        self.user_dir = os.path.join(self.app_data_dir, username)
        self.db_file = os.path.join(self.user_dir, 'data.db')
        self.db_path = self.db_file  # 添加db_path属性，与db_file相同
        
        # 确保用户目录存在
        Path(self.user_dir).mkdir(parents=True, exist_ok=True)
        
        print(f"[DB] 数据库文件路径: {self.db_file}")
        
        # 尝试连接数据库，如果失败则最多重试3次
        self.conn = None
        retries = 3
        while retries > 0 and self.conn is None:
            try:
                self.conn = self._connect_db()
                # 如果成功连接，初始化表结构
                self._init_schema()
                print(f"[DB] 数据库连接成功")
            except Exception as e:
                print(f"[DB] 连接数据库失败 (剩余尝试: {retries-1}): {e}")
                import traceback
                traceback.print_exc()
                retries -= 1
                if retries > 0:
                    import time
                    time.sleep(0.5)  # 等待一段时间再重试
        
        if self.conn is None:
            print("[DB] 错误: 无法连接到数据库，所有重试均失败")
            raise Exception("数据库连接失败")
        
        # 验证数据库连接是否正常工作
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM transactions")
            count = cursor.fetchone()[0]
            print(f"[DB] 数据库验证：找到 {count} 条交易记录")
        except Exception as e:
            print(f"[DB] 数据库验证失败: {e}")
            import traceback
            traceback.print_exc()
        
        # 初始化操作历史栈
        self.undo_stack = []
        self.redo_stack = []
    
    def _connect_db(self):
        """连接到SQLite数据库"""
        conn = sqlite3.connect(self.db_file)
        # 启用外键约束
        conn.execute("PRAGMA foreign_keys = ON")
        # 行工厂设置为字典
        conn.row_factory = sqlite3.Row
        return conn
    
    def _init_schema(self):
        """初始化数据库架构"""
        cursor = self.conn.cursor()
        
        # 交易记录表
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            asset_type TEXT NOT NULL,
            project_name TEXT NOT NULL,
            amount REAL NOT NULL,
            unit_price REAL NOT NULL,
            currency TEXT NOT NULL,
            profit_loss REAL NOT NULL,
            tags TEXT NOT NULL,
            notes TEXT
        )
        ''')
        
        # 资产类别表
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS asset_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )
        ''')
        
        # 预设标签表
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            color TEXT
        )
        ''')
        
        # 预算目标表
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS budget_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            goal_amount REAL NOT NULL,
            UNIQUE(year, month)
        )
        ''')
        
        # 插入默认资产类别数据
        default_asset_types = ["股票", "基金", "债券", "外汇", "其他"]
        for asset_type in default_asset_types:
            try:
                cursor.execute("INSERT OR IGNORE INTO asset_types (name) VALUES (?)", (asset_type,))
            except sqlite3.Error:
                pass
        
        self.conn.commit()
    
    def backup_database(self):
        """备份数据库"""
        today = datetime.date.today().strftime('%Y%m%d')
        backup_file = os.path.join(self.user_dir, f'data_{today}.bak')
        
        # 关闭当前连接
        self.conn.close()
        
        # 复制数据库文件
        try:
            shutil.copy2(self.db_file, backup_file)
            success = True
        except Exception as e:
            print(f"备份数据库失败: {e}")
            success = False
        
        # 重新连接数据库
        self.conn = self._connect_db()
        return success
    
    def cleanup_backups(self, keep_days=7):
        """清理旧备份文件，只保留最近指定天数的备份"""
        backup_files = [f for f in os.listdir(self.user_dir) if f.startswith('data_') and f.endswith('.bak')]
        
        # 按修改时间排序
        backup_files.sort(key=lambda x: os.path.getmtime(os.path.join(self.user_dir, x)), reverse=True)
        
        # 保留最近的备份
        for backup_file in backup_files[keep_days:]:
            try:
                os.remove(os.path.join(self.user_dir, backup_file))
            except Exception as e:
                print(f"删除旧备份文件失败: {e}")
    
    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
    
    # 交易记录CRUD操作
    
    # 操作历史记录相关方法
    
    def record_operation(self, operation_type, data, reverse_operation=None):
        """记录操作到撤销栈中
        
        Args:
            operation_type: 操作类型（如'add', 'update', 'delete'）
            data: 操作相关数据
            reverse_operation: 撤销该操作的方法名
        """
        operation = {
            'type': operation_type,
            'data': data,
            'reverse_operation': reverse_operation
        }
        self.undo_stack.append(operation)
        # 记录新操作后清空重做栈
        self.redo_stack.clear()
    
    def can_undo(self):
        """检查是否可以撤销操作"""
        return len(self.undo_stack) > 0
    
    def can_redo(self):
        """检查是否可以重做操作"""
        return len(self.redo_stack) > 0
    
    def undo(self):
        """撤销上一次操作"""
        if not self.can_undo():
            return False
        
        operation = self.undo_stack.pop()
        # 将操作添加到重做栈
        self.redo_stack.append(operation)
        
        # 执行撤销操作
        if operation['reverse_operation'] == 'delete_transaction':
            # 恢复被删除的交易
            transaction = Transaction.from_dict(operation['data'])
            self._restore_transaction(transaction)
        elif operation['reverse_operation'] == 'restore_transaction':
            # 删除被恢复的交易
            self._delete_transaction_by_id(operation['data']['id'], record=False)
        elif operation['reverse_operation'] == 'update_transaction':
            # 恢复到更新前的状态
            old_transaction = Transaction.from_dict(operation['data']['old'])
            self._update_transaction(old_transaction, record=False)
        
        return True
    
    def redo(self):
        """重做上一次撤销的操作"""
        if not self.can_redo():
            return False
        
        operation = self.redo_stack.pop()
        # 将操作添加回撤销栈
        self.undo_stack.append(operation)
        
        # 执行重做操作
        if operation['type'] == 'add':
            # 重新添加交易
            transaction = Transaction.from_dict(operation['data'])
            self._restore_transaction(transaction)
        elif operation['type'] == 'delete':
            # 重新删除交易
            self._delete_transaction_by_id(operation['data']['id'], record=False)
        elif operation['type'] == 'update':
            # 重新应用更新
            new_transaction = Transaction.from_dict(operation['data']['new'])
            self._update_transaction(new_transaction, record=False)
        
        return True
    
    def _restore_transaction(self, transaction):
        """恢复交易记录（内部方法）"""
        cursor = self.conn.cursor()
        try:
            data = transaction.to_dict()
            fields = ', '.join(data.keys())
            placeholders = ', '.join(['?' for _ in data])
            
            query = f"INSERT INTO transactions ({fields}) VALUES ({placeholders})"
            cursor.execute(query, list(data.values()))
            self.conn.commit()
            return True
        except Exception as e:
            self.conn.rollback()
            print(f"恢复交易记录失败: {e}")
            return False
    
    def add_transaction(self, transaction, record=True):
        """添加交易记录"""
        cursor = self.conn.cursor()
        try:
            data = transaction.to_dict()
            # 删除ID字段，让SQLite自动生成
            if 'id' in data:
                del data['id']
            
            fields = ', '.join(data.keys())
            placeholders = ', '.join(['?' for _ in data])
            
            query = f"INSERT INTO transactions ({fields}) VALUES ({placeholders})"
            cursor.execute(query, list(data.values()))
            self.conn.commit()
            
            # 获取新记录的ID
            transaction.id = cursor.lastrowid
            
            # 记录操作到历史栈
            if record:
                self.record_operation('add', transaction.to_dict(), 'delete_transaction')
            
            return transaction.id
        except Exception as e:
            self.conn.rollback()
            print(f"添加交易记录失败: {e}")
            return None
    
    def _update_transaction(self, transaction, record=True):
        """更新交易记录（内部方法）"""
        cursor = self.conn.cursor()
        try:
            data = transaction.to_dict()
            transaction_id = data.pop('id')
            
            set_clause = ', '.join([f"{field} = ?" for field in data.keys()])
            
            query = f"UPDATE transactions SET {set_clause} WHERE id = ?"
            parameters = list(data.values()) + [transaction_id]
            
            cursor.execute(query, parameters)
            self.conn.commit()
            return cursor.rowcount > 0
        except Exception as e:
            self.conn.rollback()
            print(f"更新交易记录失败: {e}")
            return False
    
    def update_transaction(self, transaction):
        """更新交易记录"""
        # 先获取原始记录，用于撤销操作
        old_transaction = self.get_transaction_by_id(transaction.id)
        if not old_transaction:
            return False
        
        # 执行更新
        result = self._update_transaction(transaction, record=False)
        if result:
            # 记录操作到历史栈
            self.record_operation('update', {
                'old': old_transaction.to_dict(),
                'new': transaction.to_dict()
            }, 'update_transaction')
        
        return result
    
    def _delete_transaction_by_id(self, transaction_id, record=True):
        """删除交易记录（内部方法）"""
        cursor = self.conn.cursor()
        try:
            cursor.execute("DELETE FROM transactions WHERE id = ?", (transaction_id,))
            self.conn.commit()
            return cursor.rowcount > 0
        except Exception as e:
            self.conn.rollback()
            print(f"删除交易记录失败: {e}")
            return False
    
    def delete_transaction(self, transaction_id):
        """删除交易记录"""
        # 先获取原始记录，用于撤销操作
        transaction = self.get_transaction_by_id(transaction_id)
        if not transaction:
            return False
        
        # 执行删除
        result = self._delete_transaction_by_id(transaction_id, record=False)
        if result:
            # 记录操作到历史栈
            self.record_operation('delete', {
                'id': transaction_id,
                'transaction': transaction.to_dict()
            }, 'restore_transaction')
        
        return result
    
    def get_transaction(self, transaction_id):
        """获取单条交易记录"""
        cursor = self.conn.cursor()
        try:
            cursor.execute("SELECT * FROM transactions WHERE id = ?", (transaction_id,))
            row = cursor.fetchone()
            if row:
                return Transaction.from_dict(dict(row))
            return None
        except Exception as e:
            print(f"获取交易记录失败: {e}")
            return None
    
    # 添加一个别名方法，用于解决命名不一致问题
    def get_transaction_by_id(self, transaction_id):
        """获取单条交易记录（get_transaction的别名）"""
        return self.get_transaction(transaction_id)
    
    def get_transactions(self, filters=None, order_by="date DESC", limit=None, offset=None):
        """获取交易记录列表，支持过滤、排序和分页"""
        cursor = self.conn.cursor()
        query = "SELECT * FROM transactions"
        parameters = []
        
        # 处理过滤条件
        if filters:
            where_clauses = []
            for field, operator, value in filters:
                where_clauses.append(f"{field} {operator} ?")
                parameters.append(value)
            
            if where_clauses:
                query += " WHERE " + " AND ".join(where_clauses)
        
        # 处理排序
        if order_by:
            query += f" ORDER BY {order_by}"
        
        # 处理分页
        if limit is not None:
            query += f" LIMIT {limit}"
            if offset is not None:
                query += f" OFFSET {offset}"
        
        try:
            print(f"执行查询: {query} 参数: {parameters}")
            cursor.execute(query, parameters)
            rows = cursor.fetchall()
            result = [Transaction.from_dict(dict(row)) for row in rows]
            print(f"查询成功，获取到 {len(result)} 条记录")
            return result
        except Exception as e:
            print(f"获取交易记录列表失败: {e}")
            return []
    
    def get_transactions_by_date_range(self, start_date, end_date):
        """按日期范围获取交易记录"""
        filters = [
            ('date', '>=', start_date),
            ('date', '<=', end_date)
        ]
        return self.get_transactions(filters)
    
    def get_total_profit_loss(self, start_date=None, end_date=None, asset_type=None):
        """获取总盈亏金额，支持按日期范围和资产类型过滤"""
        cursor = self.conn.cursor()
        query = "SELECT SUM(profit_loss) as total FROM transactions"
        parameters = []
        
        # 构建WHERE子句
        where_clauses = []
        
        if start_date:
            where_clauses.append("date >= ?")
            parameters.append(start_date)
        
        if end_date:
            where_clauses.append("date <= ?")
            parameters.append(end_date)
        
        if asset_type:
            where_clauses.append("asset_type = ?")
            parameters.append(asset_type)
        
        if where_clauses:
            query += " WHERE " + " AND ".join(where_clauses)
        
        try:
            cursor.execute(query, parameters)
            result = cursor.fetchone()
            return result['total'] if result and result['total'] is not None else 0
        except Exception as e:
            print(f"获取总盈亏失败: {e}")
            return 0
    
    # 资产类别操作
    
    def get_asset_types(self):
        """获取所有资产类别"""
        cursor = self.conn.cursor()
        try:
            cursor.execute("SELECT * FROM asset_types ORDER BY name")
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
        except Exception as e:
            print(f"获取资产类别失败: {e}")
            return []
    
    def add_asset_type(self, name):
        """添加资产类别"""
        cursor = self.conn.cursor()
        try:
            cursor.execute("INSERT INTO asset_types (name) VALUES (?)", (name,))
            self.conn.commit()
            return cursor.lastrowid
        except Exception as e:
            self.conn.rollback()
            print(f"添加资产类别失败: {e}")
            return None
    
    # 预算目标操作
    
    def set_budget_goal(self, year, month, goal_amount):
        """设置月度预算目标"""
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                "INSERT OR REPLACE INTO budget_goals (year, month, goal_amount) VALUES (?, ?, ?)",
                (year, month, goal_amount)
            )
            self.conn.commit()
            return True
        except Exception as e:
            self.conn.rollback()
            print(f"设置预算目标失败: {e}")
            return False
    
    def get_budget_goal(self, year, month):
        """获取指定月份的预算目标"""
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                "SELECT goal_amount FROM budget_goals WHERE year = ? AND month = ?",
                (year, month)
            )
            result = cursor.fetchone()
            return result['goal_amount'] if result else 0
        except Exception as e:
            print(f"获取预算目标失败: {e}")
            return 0
            
    def set_yearly_budget_goal(self, year, goal_amount):
        """设置年度预算目标 - 实际上是将目标金额平均分配到每个月"""
        cursor = self.conn.cursor()
        try:
            # 计算每月分配金额 - 简单平均分配
            monthly_amount = goal_amount / 12
            
            # 开始事务
            self.conn.execute("BEGIN TRANSACTION")
            
            # 更新该年所有月份的目标
            for month in range(1, 13):
                cursor.execute(
                    "INSERT OR REPLACE INTO budget_goals (year, month, goal_amount) VALUES (?, ?, ?)",
                    (year, month, monthly_amount)
                )
            
            # 提交事务
            self.conn.commit()
            print(f"设置年度预算目标成功: {year}年 {goal_amount}")
            return True
        except Exception as e:
            self.conn.rollback()
            print(f"设置年度预算目标失败: {e}")
            return False
            
    def get_yearly_budget_goal(self, year):
        """获取指定年份的预算目标，计算为所有月份目标之和"""
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                "SELECT SUM(goal_amount) as yearly_goal FROM budget_goals WHERE year = ?",
                (year,)
            )
            result = cursor.fetchone()
            yearly_goal = result['yearly_goal'] if result and result['yearly_goal'] is not None else 0
            print(f"获取年度预算目标: {year}年 {yearly_goal}")
            return yearly_goal
        except Exception as e:
            print(f"获取年度预算目标失败: {e}")
            return 0
