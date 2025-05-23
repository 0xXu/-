#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sqlite3
import logging
from pathlib import Path


class TagManager:
    """标签管理类，负责标签的增删改查以及与交易记录的关联"""
    
    def __init__(self, db_path):
        """
        初始化标签管理器
        
        Parameters:
        - db_path: 数据库文件路径
        """
        self.db_path = db_path
        self._ensure_tables()
        
    def _ensure_tables(self):
        """确保标签相关表存在"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 创建标签表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS tags (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE,
                    color TEXT DEFAULT "#cccccc",
                    description TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # 创建交易-标签关联表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS transaction_tags (
                    transaction_id INTEGER,
                    tag_id INTEGER,
                    PRIMARY KEY (transaction_id, tag_id),
                    FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
                    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
                )
            ''')
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logging.error(f"确保标签表存在时发生错误: {e}")
            raise e
    
    def get_all_tags(self):
        """获取所有标签"""
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute("SELECT id, name, color, description FROM tags ORDER BY name")
            tags = [dict(row) for row in cursor.fetchall()]
            
            conn.close()
            return tags
            
        except Exception as e:
            logging.error(f"获取所有标签时发生错误: {e}")
            return []
    
    def get_tag_by_id(self, tag_id):
        """
        根据ID获取标签
        
        Parameters:
        - tag_id: 标签ID
        
        Returns:
        - 标签信息字典，未找到返回None
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute("SELECT id, name, color, description FROM tags WHERE id = ?", (tag_id,))
            tag = cursor.fetchone()
            
            conn.close()
            
            if tag:
                return dict(tag)
            return None
            
        except Exception as e:
            logging.error(f"通过ID获取标签时发生错误: {e}")
            return None
    
    def create_tag(self, name, color="#cccccc", description=""):
        """
        创建新标签
        
        Parameters:
        - name: 标签名称
        - color: 标签颜色（十六进制色值）
        - description: 标签描述
        
        Returns:
        - 新标签ID，失败返回None
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                "INSERT INTO tags (name, color, description) VALUES (?, ?, ?)",
                (name, color, description)
            )
            
            tag_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            return tag_id
            
        except sqlite3.IntegrityError:
            logging.warning(f"标签名称 '{name}' 已存在")
            conn.rollback()
            conn.close()
            return None
            
        except Exception as e:
            logging.error(f"创建标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return None
    
    def update_tag(self, tag_id, name=None, color=None, description=None):
        """
        更新标签
        
        Parameters:
        - tag_id: 标签ID
        - name: 新标签名称，None表示不更新
        - color: 新标签颜色，None表示不更新
        - description: 新标签描述，None表示不更新
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 首先获取现有标签
            cursor.execute("SELECT name, color, description FROM tags WHERE id = ?", (tag_id,))
            tag = cursor.fetchone()
            
            if not tag:
                conn.close()
                return False
                
            current_name, current_color, current_description = tag
            
            # 更新不为None的字段
            new_name = name if name is not None else current_name
            new_color = color if color is not None else current_color
            new_description = description if description is not None else current_description
            
            cursor.execute(
                "UPDATE tags SET name = ?, color = ?, description = ? WHERE id = ?",
                (new_name, new_color, new_description, tag_id)
            )
            
            conn.commit()
            conn.close()
            
            return True
            
        except sqlite3.IntegrityError:
            logging.warning(f"更新标签失败：标签名称 '{name}' 已存在")
            if conn:
                conn.rollback()
                conn.close()
            return False
            
        except Exception as e:
            logging.error(f"更新标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return False
    
    def delete_tag(self, tag_id):
        """
        删除标签
        
        Parameters:
        - tag_id: 标签ID
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 检查标签是否存在
            cursor.execute("SELECT id FROM tags WHERE id = ?", (tag_id,))
            if not cursor.fetchone():
                conn.close()
                return False
                
            # 删除标签（关联表中的记录会因为外键约束自动删除）
            cursor.execute("DELETE FROM tags WHERE id = ?", (tag_id,))
            
            conn.commit()
            conn.close()
            
            return True
            
        except Exception as e:
            logging.error(f"删除标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return False
    
    def add_tag_to_transaction(self, transaction_id, tag_id):
        """
        为交易添加标签
        
        Parameters:
        - transaction_id: 交易ID
        - tag_id: 标签ID
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 检查交易和标签是否存在
            cursor.execute("SELECT id FROM transactions WHERE id = ?", (transaction_id,))
            if not cursor.fetchone():
                conn.close()
                return False
                
            cursor.execute("SELECT id FROM tags WHERE id = ?", (tag_id,))
            if not cursor.fetchone():
                conn.close()
                return False
            
            # 添加关联
            try:
                cursor.execute(
                    "INSERT INTO transaction_tags (transaction_id, tag_id) VALUES (?, ?)",
                    (transaction_id, tag_id)
                )
                conn.commit()
                conn.close()
                return True
            except sqlite3.IntegrityError:
                # 关联已存在
                conn.rollback()
                conn.close()
                return True  # 已经关联过，视为成功
                
        except Exception as e:
            logging.error(f"为交易添加标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return False
    
    def remove_tag_from_transaction(self, transaction_id, tag_id):
        """
        从交易移除标签
        
        Parameters:
        - transaction_id: 交易ID
        - tag_id: 标签ID
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                "DELETE FROM transaction_tags WHERE transaction_id = ? AND tag_id = ?",
                (transaction_id, tag_id)
            )
            
            conn.commit()
            conn.close()
            
            return True
            
        except Exception as e:
            logging.error(f"从交易移除标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return False
    
    def get_transaction_tags(self, transaction_id):
        """
        获取交易的所有标签
        
        Parameters:
        - transaction_id: 交易ID
        
        Returns:
        - 标签信息列表
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT t.id, t.name, t.color 
                FROM tags t
                INNER JOIN transaction_tags tt ON t.id = tt.tag_id
                WHERE tt.transaction_id = ?
                ORDER BY t.name
            """, (transaction_id,))
            
            tags = [dict(row) for row in cursor.fetchall()]
            
            conn.close()
            return tags
            
        except Exception as e:
            logging.error(f"获取交易标签时发生错误: {e}")
            return []
    
    def get_tagged_transactions(self, tag_id):
        """
        获取带有指定标签的所有交易
        
        Parameters:
        - tag_id: 标签ID
        
        Returns:
        - 交易ID列表
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT transaction_id 
                FROM transaction_tags
                WHERE tag_id = ?
            """, (tag_id,))
            
            transaction_ids = [row[0] for row in cursor.fetchall()]
            
            conn.close()
            return transaction_ids
            
        except Exception as e:
            logging.error(f"获取带有标签的交易时发生错误: {e}")
            return []
    
    def batch_add_tags_to_transaction(self, transaction_id, tag_ids):
        """
        批量为交易添加标签
        
        Parameters:
        - transaction_id: 交易ID
        - tag_ids: 标签ID列表
        
        Returns:
        - 成功添加的标签数量
        """
        success_count = 0
        
        for tag_id in tag_ids:
            if self.add_tag_to_transaction(transaction_id, tag_id):
                success_count += 1
                
        return success_count
    
    def batch_remove_tags_from_transaction(self, transaction_id, tag_ids):
        """
        批量从交易移除标签
        
        Parameters:
        - transaction_id: 交易ID
        - tag_ids: 标签ID列表
        
        Returns:
        - 成功移除的标签数量
        """
        success_count = 0
        
        for tag_id in tag_ids:
            if self.remove_tag_from_transaction(transaction_id, tag_id):
                success_count += 1
                
        return success_count
    
    def replace_transaction_tags(self, transaction_id, tag_ids):
        """
        替换交易的所有标签
        
        Parameters:
        - transaction_id: 交易ID
        - tag_ids: 新的标签ID列表
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # 开始事务
            conn.execute("BEGIN TRANSACTION")
            
            # 删除所有现有标签关联
            cursor.execute("DELETE FROM transaction_tags WHERE transaction_id = ?", (transaction_id,))
            
            # 添加新标签关联
            for tag_id in tag_ids:
                cursor.execute(
                    "INSERT INTO transaction_tags (transaction_id, tag_id) VALUES (?, ?)",
                    (transaction_id, tag_id)
                )
            
            conn.commit()
            conn.close()
            
            return True
            
        except Exception as e:
            logging.error(f"替换交易标签时发生错误: {e}")
            if conn:
                conn.rollback()
                conn.close()
            return False
    
    def search_tags(self, query):
        """
        搜索标签
        
        Parameters:
        - query: 搜索关键词
        
        Returns:
        - 匹配的标签列表
        """
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT id, name, color, description 
                FROM tags 
                WHERE name LIKE ? OR description LIKE ?
                ORDER BY name
            """, (f"%{query}%", f"%{query}%"))
            
            tags = [dict(row) for row in cursor.fetchall()]
            
            conn.close()
            return tags
            
        except Exception as e:
            logging.error(f"搜索标签时发生错误: {e}")
            return [] 