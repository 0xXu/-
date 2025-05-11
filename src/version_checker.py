import requests
import json
import hashlib
from datetime import datetime
from pathlib import Path
from packaging import version
import sys
import subprocess
import os
import shutil
import urllib3

# 禁用SSL警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class VersionChecker:
    def __init__(self, current_version="1.0.0"):
        self.current_version = current_version
        # 直接写死 GitHub API URL
        self.github_api_url = "https://api.github.com/repos/0xXu/Personal-Investment-Accounting-Procedure/releases/latest"
        
        # 配置文件和临时文件路径
        self.config_dir = Path.home() / "AccountTracker"
        self.update_config_file = self.config_dir / "update_config.json"
        self.temp_dir = self.config_dir / "temp"
        self.backup_dir = self.config_dir / "backup"
        
        # 创建必要的目录
        self.config_dir.mkdir(exist_ok=True)
        self.temp_dir.mkdir(exist_ok=True)
        self.backup_dir.mkdir(exist_ok=True)
        
        # 初始化配置
        self.init_config()
        
        # 打印调试信息
        print(f"版本检查器初始化完成，当前版本: {self.current_version}")
        print(f"GitHub API URL: {self.github_api_url}")
    
    def init_config(self):
        """初始化更新配置文件"""
        if not self.update_config_file.exists():
            default_config = {
                "last_check": "",
                "auto_check": True,
                "check_frequency": 7,  # 天数
                "silent_update": False,
                "update_history": []
            }
            self.save_config(default_config)
        
    def save_config(self, config):
        """保存配置到文件"""
        with open(self.update_config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=4)
    
    def load_config(self):
        """加载配置文件"""
        try:
            with open(self.update_config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            self.init_config()
            return self.load_config()
    
    def should_check_update(self):
        """检查是否需要执行更新检查"""
        config = self.load_config()
        if not config["auto_check"]:
            return False
            
        last_check = config.get("last_check", "")
        if not last_check:
            return True
            
        days_diff = (datetime.now() - datetime.fromisoformat(last_check)).days
        return days_diff >= config["check_frequency"]
    
    def check_for_updates(self):
        """检查更新"""
        try:
            # 禁用SSL验证
            response = requests.get(self.github_api_url, timeout=10, verify=False)
            if response.status_code == 200:
                latest_release = response.json()
                latest_version = latest_release["tag_name"].lstrip("v")
                
                if version.parse(latest_version) > version.parse(self.current_version):
                    update_info = {
                        "has_update": True,
                        "version": latest_version,
                        "download_url": latest_release["assets"][0]["browser_download_url"],
                        "release_notes": latest_release["body"],
                        "checksum": latest_release.get("body", "").split("SHA256: ")[-1].split("\n")[0],
                        "publish_date": latest_release["published_at"]
                    }
                else:
                    update_info = {"has_update": False}
                    
                # 更新最后检查时间
                config = self.load_config()
                config["last_check"] = datetime.now().isoformat()
                self.save_config(config)
                
                return update_info
                
        except Exception as e:
            print(f"检查更新时出错: {str(e)}")
            return {"has_update": False, "error": str(e)}
            
        return {"has_update": False}
    
    def verify_file(self, file_path, expected_checksum):
        """验证文件完整性"""
        if not expected_checksum:
            return True
            
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest() == expected_checksum
    
    def download_update(self, download_url, checksum="", callback=None):
        """下载更新"""
        try:
            # 禁用SSL验证
            response = requests.get(download_url, stream=True, timeout=30, verify=False)
            total_size = int(response.headers.get('content-length', 0))
            
            # 下载到临时文件
            temp_file = self.temp_dir / "update.exe"
            if temp_file.exists():
                temp_file.unlink()
            
            block_size = 1024
            downloaded = 0
            
            with open(temp_file, 'wb') as f:
                for data in response.iter_content(block_size):
                    downloaded += len(data)
                    f.write(data)
                    if callback:
                        callback(downloaded / total_size * 100)
            
            # 验证文件完整性
            if checksum and not self.verify_file(temp_file, checksum):
                raise Exception("文件校验失败")
                
            return str(temp_file)
            
        except Exception as e:
            print(f"下载更新时出错: {str(e)}")
            return None
    
    def backup_current_version(self):
        """备份当前版本"""
        try:
            current_exe = sys.executable
            backup_file = self.backup_dir / f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.exe"
            shutil.copy2(current_exe, backup_file)
            return True
        except Exception as e:
            print(f"备份失败: {str(e)}")
            return False
    
    def add_update_history(self, version, date):
        """添加更新历史记录"""
        config = self.load_config()
        history = config.get("update_history", [])
        history.append({
            "version": version,
            "date": date,
            "previous_version": self.current_version
        })
        config["update_history"] = history
        self.save_config(config)
    
    def get_update_history(self):
        """获取更新历史记录"""
        config = self.load_config()
        return config.get("update_history", [])
    
    def install_update(self, new_version_path):
        """安装更新"""
        try:
            # 启动新版本并传递当前进程PID
            cmd = [new_version_path, "--update", str(os.getpid())]
            subprocess.Popen(cmd)
            return True
        except Exception as e:
            print(f"启动更新失败: {str(e)}")
            return False 