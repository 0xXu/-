#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import shutil
import datetime
import json
from pathlib import Path
import logging
import time

class BackupManager:
    """数据备份管理类，负责自动备份和清理旧备份"""
    
    def __init__(self, app_data_dir, username):
        """
        初始化备份管理器
        
        Parameters:
        - app_data_dir: 应用程序数据根目录
        - username: 当前用户名
        """
        self.app_data_dir = app_data_dir
        self.username = username
        
        # 用户数据目录
        self.user_data_dir = os.path.join(app_data_dir, username)
        
        # 备份目录
        self.backup_dir = os.path.join(app_data_dir, username, 'backups')
        Path(self.backup_dir).mkdir(parents=True, exist_ok=True)
        
        # 数据库文件路径
        self.db_path = os.path.join(self.user_data_dir, 'data.db')
        
        # 备份配置
        self.config_path = os.path.join(self.user_data_dir, 'backup_config.json')
        self.config = self._load_config()
    
    def _load_config(self):
        """加载备份配置"""
        default_config = {
            'auto_backup': True,
            'keep_days': 7,
            'last_backup': None,
            'backup_count': 0
        }
        
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    # 确保所有默认配置项存在
                    for key, value in default_config.items():
                        if key not in config:
                            config[key] = value
                    return config
            except Exception as e:
                logging.error(f"加载备份配置出错: {e}")
        
        return default_config
    
    def _save_config(self):
        """保存备份配置"""
        try:
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=2)
            return True
        except Exception as e:
            logging.error(f"保存备份配置出错: {e}")
            return False
    
    def create_backup(self, custom_name=None):
        """
        创建数据库备份
        
        Parameters:
        - custom_name: 可选的自定义备份名称
        
        Returns:
        - 成功返回备份文件路径，失败返回None
        """
        try:
            if not os.path.exists(self.db_path):
                logging.error(f"数据库文件不存在: {self.db_path}")
                return None
            
            # 生成备份文件名
            timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
            if custom_name:
                filename = f"{custom_name}_{timestamp}.db.bak"
            else:
                filename = f"data_{timestamp}.db.bak"
            
            backup_path = os.path.join(self.backup_dir, filename)
            
            # 复制数据库文件
            shutil.copy2(self.db_path, backup_path)
            
            # 更新配置
            self.config['last_backup'] = timestamp
            self.config['backup_count'] += 1
            self._save_config()
            
            logging.info(f"备份创建成功: {backup_path}")
            return backup_path
        
        except Exception as e:
            logging.error(f"创建备份失败: {e}")
            return None
    
    def restore_backup(self, backup_path):
        """
        从备份恢复数据库
        
        Parameters:
        - backup_path: 备份文件路径
        
        Returns:
        - 成功返回True，失败返回False
        """
        try:
            if not os.path.exists(backup_path):
                logging.error(f"备份文件不存在: {backup_path}")
                return False
            
            # 备份当前数据库，以防恢复操作失败
            current_backup = self.create_backup(custom_name="pre_restore")
            if not current_backup:
                logging.warning("无法备份当前数据库，但将继续恢复操作")
            
            # 复制备份文件到数据库位置
            shutil.copy2(backup_path, self.db_path)
            
            logging.info(f"从备份恢复成功: {backup_path}")
            return True
        
        except Exception as e:
            logging.error(f"从备份恢复失败: {e}")
            return False
    
    def get_backups(self):
        """
        获取所有备份文件列表
        
        Returns:
        - 备份文件信息列表，按时间降序排序
        """
        try:
            backups = []
            for file in os.listdir(self.backup_dir):
                if file.endswith('.db.bak'):
                    file_path = os.path.join(self.backup_dir, file)
                    file_stat = os.stat(file_path)
                    
                    # 解析文件名中的时间戳
                    timestamp = None
                    try:
                        # 尝试从文件名中提取时间戳
                        parts = file.split('_')
                        if len(parts) >= 2:
                            date_part = parts[-2]
                            time_part = parts[-1].split('.')[0]
                            if len(date_part) == 8 and len(time_part) == 6:
                                timestamp = f"{date_part}_{time_part}"
                    except:
                        pass
                    
                    backups.append({
                        'filename': file,
                        'path': file_path,
                        'size': file_stat.st_size,
                        'modified_time': file_stat.st_mtime,
                        'timestamp': timestamp or time.strftime('%Y%m%d_%H%M%S', time.localtime(file_stat.st_mtime))
                    })
            
            # 按修改时间降序排序
            backups.sort(key=lambda x: x['modified_time'], reverse=True)
            return backups
        
        except Exception as e:
            logging.error(f"获取备份列表失败: {e}")
            return []
    
    def cleanup_old_backups(self, keep_days=None):
        """
        清理旧备份文件
        
        Parameters:
        - keep_days: 保留天数，None表示使用配置中的值
        
        Returns:
        - 删除的文件数量
        """
        if keep_days is None:
            keep_days = self.config['keep_days']
        
        try:
            now = datetime.datetime.now()
            cutoff_time = now - datetime.timedelta(days=keep_days)
            cutoff_timestamp = cutoff_time.timestamp()
            
            deleted_count = 0
            for backup in self.get_backups():
                # 保护最近的5个备份，防止意外删除所有备份
                if deleted_count >= 5:
                    break
                    
                # 检查是否为pre_restore备份（恢复前的备份）
                if 'pre_restore' in backup['filename']:
                    # 只保留24小时内的恢复备份
                    pre_restore_cutoff = now - datetime.timedelta(hours=24)
                    if backup['modified_time'] < pre_restore_cutoff.timestamp():
                        os.remove(backup['path'])
                        deleted_count += 1
                # 常规备份时间检查
                elif backup['modified_time'] < cutoff_timestamp:
                    os.remove(backup['path'])
                    deleted_count += 1
            
            logging.info(f"已清理 {deleted_count} 个旧备份文件")
            return deleted_count
        
        except Exception as e:
            logging.error(f"清理旧备份失败: {e}")
            return 0
    
    def auto_backup(self):
        """
        执行自动备份（如果启用）
        
        Returns:
        - 成功返回True，失败或未启用返回False
        """
        if not self.config['auto_backup']:
            return False
            
        # 检查上次备份时间
        last_backup = self.config['last_backup']
        if last_backup:
            try:
                # 解析上次备份时间
                year = int(last_backup[0:4])
                month = int(last_backup[4:6])
                day = int(last_backup[6:8])
                last_date = datetime.date(year, month, day)
                
                # 如果今天已经备份过，则不再备份
                if last_date == datetime.date.today():
                    return False
            except:
                # 解析失败，继续执行备份
                pass
        
        # 创建新备份
        result = self.create_backup() is not None
        
        # 清理旧备份
        self.cleanup_old_backups()
        
        return result
    
    def set_auto_backup(self, enabled):
        """设置是否启用自动备份"""
        self.config['auto_backup'] = bool(enabled)
        return self._save_config()
    
    def set_keep_days(self, days):
        """设置备份保留天数"""
        try:
            days = int(days)
            if days < 1:
                days = 1
            elif days > 365:
                days = 365
                
            self.config['keep_days'] = days
            return self._save_config()
        except:
            return False
    
    def get_last_backup_info(self):
        """获取上次备份信息"""
        last_backup = self.config['last_backup']
        if not last_backup:
            return {
                'has_backup': False,
                'last_backup': None,
                'backup_count': 0
            }
        
        return {
            'has_backup': True,
            'last_backup': last_backup,
            'backup_count': self.config['backup_count']
        } 