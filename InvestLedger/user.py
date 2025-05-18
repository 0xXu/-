#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
from pathlib import Path

class UserManager:
    """用户管理类，负责用户列表的创建、删除与切换"""
    
    def __init__(self):
        """初始化用户管理器"""
        self.app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
        self.users_file = os.path.join(self.app_data_dir, 'users.json')
        self.users = self._load_users()
        
    def _load_users(self):
        """加载用户列表"""
        if not os.path.exists(self.users_file):
            # 如果用户列表文件不存在，创建默认用户
            default_users = {"users": ["default"]}
            self._save_users(default_users)
            # 创建默认用户数据目录
            self._create_user_data_dir("default")
            return default_users
        
        try:
            with open(self.users_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"加载用户列表失败: {e}")
            # 返回默认用户列表
            return {"users": ["default"]}
    
    def _save_users(self, users_data):
        """保存用户列表"""
        try:
            with open(self.users_file, 'w', encoding='utf-8') as f:
                json.dump(users_data, f, ensure_ascii=False, indent=2)
            return True
        except Exception as e:
            print(f"保存用户列表失败: {e}")
            return False
    
    def _create_user_data_dir(self, username):
        """创建用户数据目录"""
        user_dir = os.path.join(self.app_data_dir, username)
        Path(user_dir).mkdir(exist_ok=True)
        return user_dir
    
    def get_users(self):
        """获取所有用户列表"""
        return self.users.get("users", [])
    
    def create_user(self, username):
        """创建新用户"""
        if not username or username.strip() == "":
            return False
        
        # 规范化用户名
        username = username.strip()
        
        # 检查用户是否已存在
        if username in self.users.get("users", []):
            return False
        
        # 创建用户数据目录
        user_dir = self._create_user_data_dir(username)
        
        # 更新用户列表
        users_list = self.users.get("users", [])
        users_list.append(username)
        self.users["users"] = users_list
        
        # 保存用户列表
        return self._save_users(self.users)
    
    def delete_user(self, username):
        """删除用户"""
        if username == "default":
            # 不允许删除默认用户
            return False
        
        if username not in self.users.get("users", []):
            # 用户不存在
            return False
        
        # 从列表中移除用户
        users_list = self.users.get("users", [])
        users_list.remove(username)
        self.users["users"] = users_list
        
        # 保存用户列表
        return self._save_users(self.users)
        
    def user_exists(self, username):
        """检查用户是否存在"""
        return username in self.users.get("users", []) 