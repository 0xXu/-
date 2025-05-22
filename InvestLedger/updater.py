#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import time
import shutil
import zipfile
import tempfile
import threading
import requests
from pathlib import Path
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class UpdateChecker:
    """更新检查器，负责检查、下载与安装更新"""
    
    def __init__(self, current_version):
        self.current_version = current_version
        self.github_api_url = "https://api.github.com/repos/0xXu/Personal-Investment-Accounting-Procedure/releases/latest"
        self.update_available = False
        self.latest_version = None
        self.download_url = None
        self.release_notes = None
        self.update_thread = None
        self.progress_callback = None
        self.finished_callback = None
        self.download_complete = False
        self.update_file_path = None
        
        # 检查是否有待安装的更新
        self._check_pending_update()
    
    def _check_pending_update(self):
        """检查是否有待安装的更新"""
        app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
        update_status_file = os.path.join(app_data_dir, 'update_status.json')
        
        if os.path.exists(update_status_file):
            try:
                with open(update_status_file, 'r') as f:
                    status = json.load(f)
                    
                if status.get('download_complete') and status.get('update_file'):
                    if os.path.exists(status['update_file']):
                        # 执行更新安装
                        print("发现待安装的更新，正在安装...")
                        # 创建临时目录
                        temp_dir = tempfile.mkdtemp()
                        
                        # 解压更新
                        with zipfile.ZipFile(status['update_file'], 'r') as zip_ref:
                            zip_ref.extractall(temp_dir)
                        
                        # 找到解压后的应用程序根目录
                        app_dir = self._find_app_dir(temp_dir)
                        if app_dir:
                            # 备份当前配置
                            self._backup_user_data()
                            
                            # 获取当前程序路径
                            current_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
                            
                            # 安装更新：复制新文件到程序目录
                            self._copy_update_files(app_dir, current_dir)
                            
                        # 清理
                        shutil.rmtree(temp_dir, ignore_errors=True)
                        os.remove(status['update_file'])
                        os.remove(update_status_file)
                        print("更新安装完成")
            except Exception as e:
                print(f"处理待安装更新失败: {e}")
                # 清理失败的更新状态
                if os.path.exists(update_status_file):
                    os.remove(update_status_file)
    
    def set_progress_callback(self, callback):
        """设置进度回调函数"""
        self.progress_callback = callback
    
    def set_finished_callback(self, callback):
        """设置完成回调函数"""
        self.finished_callback = callback
    
    def check_for_updates(self, silent=False):
        """
        检查更新，如果存在新版本则返回True
        silent: 静默模式，不弹出提示
        """
        try:
            response = requests.get(self.github_api_url, timeout=5, verify=False)
            if response.status_code == 200:
                data = response.json()
                self.latest_version = data['tag_name'].lstrip('v')
                self.download_url = self._get_download_url(data['assets'])
                self.release_notes = data['body']
                
                # 比较版本
                if self._compare_versions(self.latest_version, self.current_version) > 0:
                    self.update_available = True
                    if not silent:
                        # 在实际实现中，这里应该弹出QML对话框
                        print(f"有新版本可用: v{self.latest_version}")
                        print(f"当前版本: v{self.current_version}")
                    return True
            
            return False
        except Exception as e:
            print(f"检查更新失败: {e}")
            return False
    
    def download_and_install_update(self, auto_restart=False):
        """
        下载并安装更新
        auto_restart: 安装后是否自动重启
        """
        if not self.update_available or not self.download_url:
            if self.finished_callback:
                self.finished_callback(False)
            return False
        
        # 在后台线程中下载更新
        self.update_thread = threading.Thread(target=self._do_update, args=(auto_restart,))
        self.update_thread.daemon = True
        self.update_thread.start()
        
        return True
    
    def _do_update(self, auto_restart):
        """执行更新过程"""
        success = False
        try:
            # 创建临时目录
            temp_dir = tempfile.mkdtemp()
            zip_path = os.path.join(temp_dir, "update.zip")
            
            # 下载更新
            if not self._download_file(self.download_url, zip_path):
                raise Exception("下载更新文件失败")
            
            # 将更新文件复制到应用数据目录
            app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
            os.makedirs(app_data_dir, exist_ok=True)
            update_file = os.path.join(app_data_dir, f"update_{self.latest_version}.zip")
            shutil.copy2(zip_path, update_file)
            
            # 创建更新状态文件
            update_status = {
                'download_complete': True,
                'version': self.latest_version,
                'update_file': update_file,
                'timestamp': time.time()
            }
            
            with open(os.path.join(app_data_dir, 'update_status.json'), 'w') as f:
                json.dump(update_status, f)
            
            # 清理临时文件
            shutil.rmtree(temp_dir, ignore_errors=True)
            
            # 标记下载完成
            self.download_complete = True
            self.update_file_path = update_file
            
            # 如果需要，重启应用程序
            if auto_restart:
                self._restart_application()
            
            success = True
            
        except Exception as e:
            print(f"更新下载失败: {e}")
            success = False
        
        # 调用完成回调
        if self.finished_callback:
            self.finished_callback(success)
    
    def _download_file(self, url, dest_path):
        """下载文件到指定路径"""
        try:
            response = requests.get(url, stream=True,verify=False)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded_size = 0
            
            with open(dest_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded_size += len(chunk)
                        
                        # 更新下载进度
                        if total_size > 0:
                            progress = int(100 * downloaded_size / total_size)
                            # 使用回调函数通知UI
                            if self.progress_callback:
                                self.progress_callback(progress)
                            # 控制台显示
                            print(f"\r下载进度: {progress}%", end='')
            
            print("\n下载完成")
            return True
            
        except Exception as e:
            print(f"下载文件失败: {e}")
            return False
    
    def _find_app_dir(self, extract_dir):
        """查找解压后的应用程序主目录"""
        for root, dirs, files in os.walk(extract_dir):
            # 检查是否包含main.py文件
            if 'main.py' in files:
                return root
        return None
    
    def _backup_user_data(self):
        """备份用户数据目录"""
        try:
            app_data_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger')
            if os.path.exists(app_data_dir):
                # 备份到备份目录
                backup_dir = os.path.join(app_data_dir, 'backup_before_update')
                if os.path.exists(backup_dir):
                    shutil.rmtree(backup_dir, ignore_errors=True)
                
                # 创建备份目录
                os.makedirs(backup_dir, exist_ok=True)
                
                # 复制用户数据文件
                for item in os.listdir(app_data_dir):
                    if item != 'backup_before_update':
                        src = os.path.join(app_data_dir, item)
                        dst = os.path.join(backup_dir, item)
                        if os.path.isdir(src):
                            shutil.copytree(src, dst)
                        else:
                            shutil.copy2(src, dst)
                
                return True
        except Exception as e:
            print(f"备份用户数据失败: {e}")
        
        return False
    
    def _copy_update_files(self, src_dir, dst_dir):
        """复制更新文件到目标目录"""
        try:
            # 创建排除文件列表，不覆盖这些文件
            exclude = []
            
            # 复制文件
            for item in os.listdir(src_dir):
                src = os.path.join(src_dir, item)
                dst = os.path.join(dst_dir, item)
                
                if item in exclude:
                    continue
                
                if os.path.isdir(src):
                    if os.path.exists(dst):
                        shutil.rmtree(dst)
                    shutil.copytree(src, dst)
                else:
                    if os.path.exists(dst):
                        os.remove(dst)
                    shutil.copy2(src, dst)
            
            return True
            
        except Exception as e:
            print(f"复制更新文件失败: {e}")
            return False
    
    def _restart_application(self):
        """重启应用程序"""
        python = sys.executable
        script = os.path.abspath(sys.argv[0])
        args = sys.argv[1:]
        
        # 构建重启命令
        cmd = [python, script] + args
        
        # 延迟一秒，确保当前进程已经关闭
        def delayed_restart():
            time.sleep(1)
            os.execv(python, cmd)
        
        restart_thread = threading.Thread(target=delayed_restart)
        restart_thread.daemon = True
        restart_thread.start()
        
        # 退出当前进程
        sys.exit(0)
    
    def _compare_versions(self, version1, version2):
        """
        比较两个版本号
        返回值: -1 (version1 < version2), 0 (version1 == version2), 1 (version1 > version2)
        """
        v1 = [int(x) for x in version1.split('.')]
        v2 = [int(x) for x in version2.split('.')]
        
        # 填充短版本号
        while len(v1) < len(v2):
            v1.append(0)
        while len(v2) < len(v1):
            v2.append(0)
        
        # 比较版本号
        for i in range(len(v1)):
            if v1[i] > v2[i]:
                return 1
            elif v1[i] < v2[i]:
                return -1
        
        return 0
    
    def _get_download_url(self, assets):
        """从资源列表中获取下载URL"""
        if not assets:
            return None
        
        # 寻找Windows可执行文件（.zip）
        for asset in assets:
            if asset['name'].endswith('.zip') and 'windows' in asset['name'].lower():
                return asset['browser_download_url']
        
        # 如果没有找到特定平台的资源，返回第一个.zip文件
        for asset in assets:
            if asset['name'].endswith('.zip'):
                return asset['browser_download_url']
        
        # 如果没有.zip文件，返回第一个资源
        return assets[0]['browser_download_url'] if assets else None 