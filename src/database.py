import sqlite3
from datetime import datetime
from typing import List, Dict, Any, Tuple, Optional
import pandas as pd
from pathlib import Path
import shutil
import json
import threading

class DatabaseManager:
    def __init__(self, db_path: Path, backup_dir: Path):
        self.db_path = db_path
        self.backup_dir = backup_dir
        self._local = threading.local()
        self.init_database()
        
    @property
    def conn(self):
        if not hasattr(self._local, 'conn'):
            self._local.conn = sqlite3.connect(str(self.db_path))
        return self._local.conn
    
    @property
    def cursor(self):
        if not hasattr(self._local, 'cursor'):
            self._local.cursor = self.conn.cursor()
        return self._local.cursor
    
    def init_database(self):
        """初始化数据库表"""
        with sqlite3.connect(str(self.db_path)) as conn:
            cursor = conn.cursor()
            cursor.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                stock_name TEXT NOT NULL,
                amount REAL NOT NULL,
                is_profit BOOLEAN NOT NULL,
                trade_date DATE NOT NULL,
                note TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            ''')
            conn.commit()
        
    def add_transaction(self, transaction: Dict[str, Any]) -> Tuple[bool, str]:
        """添加交易记录"""
        try:
            # 首先检查是否存在重复记录
            self.cursor.execute('''
            SELECT id FROM transactions 
            WHERE stock_name = ? 
            AND amount = ? 
            AND is_profit = ? 
            AND trade_date = ?
            ''', (
                transaction['stock_name'],
                transaction['amount'],
                transaction['is_profit'],
                transaction['trade_date'].strftime('%Y-%m-%d')
            ))
            
            if self.cursor.fetchone():
                return False, "该记录已存在，避免重复添加"
            
            # 如果不存在重复，则添加新记录
            self.cursor.execute('''
            INSERT INTO transactions (stock_name, amount, is_profit, trade_date, note)
            VALUES (?, ?, ?, ?, ?)
            ''', (
                transaction['stock_name'],
                transaction['amount'],
                transaction['is_profit'],
                transaction['trade_date'].strftime('%Y-%m-%d'),
                transaction['note']
            ))
            self.conn.commit()
            return True, ""
        except Exception as e:
            return False, str(e)
            
    def get_all_transactions(self) -> List[Dict[str, Any]]:
        """获取所有交易记录"""
        self.cursor.execute('''
        SELECT id, stock_name, amount, is_profit, trade_date, note, timestamp
        FROM transactions
        ORDER BY trade_date DESC, timestamp DESC
        ''')
        
        records = []
        for row in self.cursor.fetchall():
            records.append({
                'id': row[0],
                'stock_name': row[1],
                'amount': row[2],
                'is_profit': bool(row[3]),
                'trade_date': datetime.strptime(row[4], '%Y-%m-%d'),
                'note': row[5],
                'timestamp': row[6]
            })
        return records
        
    def search_transactions(self, keyword: str) -> List[Dict[str, Any]]:
        """搜索交易记录"""
        self.cursor.execute('''
        SELECT id, stock_name, amount, is_profit, trade_date, note, timestamp
        FROM transactions
        WHERE stock_name LIKE ? OR note LIKE ?
        ORDER BY trade_date DESC, timestamp DESC
        ''', (f'%{keyword}%', f'%{keyword}%'))
        
        records = []
        for row in self.cursor.fetchall():
            records.append({
                'id': row[0],
                'stock_name': row[1],
                'amount': row[2],
                'is_profit': bool(row[3]),
                'trade_date': datetime.strptime(row[4], '%Y-%m-%d'),
                'note': row[5],
                'timestamp': row[6]
            })
        return records
        
    def get_statistics(self, start_date=None, end_date=None):
        """获取统计数据，支持日期筛选"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 构建日期条件
            date_condition = ""
            params = []
            if start_date:
                date_condition += " AND trade_date >= ?"
                params.append(start_date.strftime('%Y-%m-%d'))
            if end_date:
                date_condition += " AND trade_date <= ?"
                params.append(end_date.strftime('%Y-%m-%d'))
            
            # 获取月度统计
            monthly_query = f"""
                SELECT 
                    strftime('%Y-%m', trade_date) as month,
                    COUNT(*) as trade_count,
                    SUM(CASE WHEN is_profit = 1 THEN amount ELSE -amount END) as net_profit
                FROM transactions
                WHERE 1=1 {date_condition}
                GROUP BY strftime('%Y-%m', trade_date)
                ORDER BY month
            """
            cursor.execute(monthly_query, params)
            monthly_stats = [
                {
                    'month': row[0],
                    'trade_count': row[1],
                    'net_profit': row[2]
                }
                for row in cursor.fetchall()
            ]
            
            # 获取股票统计
            stock_query = f"""
                SELECT 
                    stock_name,
                    COUNT(*) as trade_count,
                    SUM(CASE WHEN is_profit = 1 THEN amount ELSE -amount END) as net_profit
                FROM transactions
                WHERE 1=1 {date_condition}
                GROUP BY stock_name
                ORDER BY net_profit DESC
            """
            cursor.execute(stock_query, params)
            stock_stats = [
                {
                    'stock_name': row[0],
                    'trade_count': row[1],
                    'net_profit': row[2]
                }
                for row in cursor.fetchall()
            ]
            
            # 获取总体统计
            total_query = f"""
                SELECT 
                    COUNT(*) as transaction_count,
                    COUNT(DISTINCT stock_name) as stock_count,
                    SUM(CASE WHEN is_profit = 1 THEN amount ELSE 0 END) as total_profit,
                    SUM(CASE WHEN is_profit = 0 THEN amount ELSE 0 END) as total_loss,
                    SUM(CASE WHEN is_profit = 1 THEN amount ELSE -amount END) as net_profit
                FROM transactions
                WHERE 1=1 {date_condition}
            """
            cursor.execute(total_query, params)
            total_stats = dict(zip(
                ['transaction_count', 'stock_count', 'total_profit', 'total_loss', 'net_profit'],
                cursor.fetchone()
            ))
            
            conn.close()
            
            return {
                'monthly': monthly_stats,
                'stocks': stock_stats,
                'total': total_stats
            }
            
        except Exception as e:
            print(f"获取统计数据时出错：{str(e)}")
            return {
                'monthly': [],
                'stocks': [],
                'total': {
                    'transaction_count': 0,
                    'stock_count': 0,
                    'total_profit': 0,
                    'total_loss': 0,
                    'net_profit': 0
                }
            }
        
    def backup_database(self) -> Tuple[bool, str]:
        """备份数据库"""
        try:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_path = self.backup_dir / f"transactions_backup_{timestamp}.db"
            
            # 关闭当前连接
            self.conn.close()
            
            # 复制数据库文件
            shutil.copy2(self.db_path, backup_path)
            
            # 重新连接数据库
            self.conn = sqlite3.connect(str(self.db_path))
            self.cursor = self.conn.cursor()
            
            return True, str(backup_path)
        except Exception as e:
            return False, str(e)
        
    def export_to_excel(self, output_path: Path) -> Tuple[bool, str]:
        """导出数据到Excel"""
        try:
            records = self.get_all_transactions()
            df = pd.DataFrame(records)
            
            # 格式化日期和时间
            df['trade_date'] = df['trade_date'].dt.strftime('%Y年%m月%d日')
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            
            # 重命名列
            df = df.rename(columns={
                'stock_name': '股票名称',
                'amount': '金额',
                'is_profit': '盈亏',
                'trade_date': '交易日期',
                'note': '备注',
                'timestamp': '记录时间'
            })
            
            # 格式化盈亏列
            df['盈亏'] = df['盈亏'].map({True: '盈', False: '亏'})
            
            # 保存到Excel
            df.to_excel(output_path, index=False, engine='openpyxl')
            return True, ""
        except Exception as e:
            return False, str(e)
        
    def get_monthly_statistics(self) -> List[Dict[str, Any]]:
        """获取月度统计信息"""
        try:
            self.cursor.execute('''
            SELECT 
                strftime('%Y-%m', trade_date) as month,
                SUM(CASE WHEN is_profit THEN amount ELSE -amount END) as net_profit,
                COUNT(*) as trade_count
            FROM transactions
            GROUP BY month
            ORDER BY month DESC
            ''')
            monthly_stats = self.cursor.fetchall()
            
            return [{
                'month': f"{month[:4]}年{month[5:]}月",
                'net_profit': net_profit or 0,
                'trade_count': count or 0
            } for month, net_profit, count in monthly_stats]
        except Exception:
            return []
            
    def get_stock_statistics(self) -> List[Dict[str, Any]]:
        """获取股票统计信息"""
        try:
            self.cursor.execute('''
            SELECT 
                stock_name,
                SUM(CASE WHEN is_profit THEN amount ELSE -amount END) as net_profit,
                COUNT(*) as trade_count
            FROM transactions
            GROUP BY stock_name
            ORDER BY net_profit DESC
            ''')
            stock_stats = self.cursor.fetchall()
            
            return [{
                'stock_name': name or 'Unknown',
                'net_profit': net_profit or 0,
                'trade_count': count or 0
            } for name, net_profit, count in stock_stats]
        except Exception:
            return []
        
    def delete_transactions(self, ids: List[int]) -> Tuple[bool, str]:
        """删除指定ID的交易记录"""
        try:
            # 将ID列表转换为字符串，用于SQL的IN子句
            id_str = ','.join('?' * len(ids))
            self.cursor.execute(f'DELETE FROM transactions WHERE id IN ({id_str})', ids)
            self.conn.commit()
            return True, ""
        except Exception as e:
            return False, str(e)
            
    def clear_all_transactions(self) -> Tuple[bool, str]:
        """清空所有交易记录"""
        try:
            self.cursor.execute('DELETE FROM transactions')
            self.conn.commit()
            return True, ""
        except Exception as e:
            return False, str(e)
        
    def get_filtered_transactions(self, conditions: List[str], params: List[Any]) -> List[Dict[str, Any]]:
        """获取筛选后的交易记录"""
        try:
            # 构建SQL查询
            query = '''
            SELECT id, stock_name, amount, is_profit, trade_date, note, timestamp
            FROM transactions
            '''
            
            # 添加筛选条件
            if conditions:
                query += ' WHERE ' + ' AND '.join(conditions)
            
            # 添加排序
            query += ' ORDER BY trade_date DESC, timestamp DESC'
            
            # 执行查询
            self.cursor.execute(query, tuple(params))  # 将参数列表转换为元组
            
            # 处理结果
            records = []
            for row in self.cursor.fetchall():
                records.append({
                    'id': row[0],
                    'stock_name': row[1],
                    'amount': row[2],
                    'is_profit': bool(row[3]),
                    'trade_date': datetime.strptime(row[4], '%Y-%m-%d'),
                    'note': row[5],
                    'timestamp': row[6]
                })
            return records
            
        except Exception as e:
            raise Exception(f"筛选数据失败：{str(e)}")
        
    def __del__(self):
        """析构函数，确保关闭数据库连接"""
        if hasattr(self._local, 'conn'):
            try:
                self._local.conn.close()
            except:
                pass 