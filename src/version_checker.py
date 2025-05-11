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
import platform
from urllib.parse import quote

# 禁用SSL警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class VersionChecker:
    def __init__(self, current_version="1.0.0", github_token=None):
        self.current_version = current_version
        self.github_token = github_token
        # 使用URL编码处理API URL
        base_url = "https://api.github.com/repos"
        owner = "0xXu"
        repo = "Personal-Investment-Accounting-Procedure"
        self.github_api_url = f"{base_url}/{quote(owner)}/{quote(repo)}/releases/latest"
        
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
                "update_history": [],
                "github_token": ""  # 添加GitHub Token配置
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
            print("正在检查更新...")
            
            # 准备请求头
            headers = {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Personal-Investment-Accounting-Procedure-Updater'
            }
            
            # 优先使用命令行传入的token，其次使用配置文件中的token
            token = self.github_token
            if not token:
                config = self.load_config()
                token = config.get("github_token")
            
            if token:
                headers['Authorization'] = f'token {token}'
                print("使用GitHub Token进行认证")
            else:
                print("警告: 未配置GitHub Token，可能会受到API访问限制")
            
            # 发送请求
            response = requests.get(
                self.github_api_url,
                headers=headers,
                timeout=10,
                verify=False
            )
            
            print(f"API响应状态码: {response.status_code}")
            
            if response.status_code == 200:
                latest_release = response.json()
                latest_version = latest_release["tag_name"].lstrip("v")
                
                print(f"最新版本: {latest_version}")
                print(f"当前版本: {self.current_version}")
                
                try:
                    latest_ver = version.parse(latest_version)
                    current_ver = version.parse(self.current_version)
                    print(f"版本比较: {latest_ver} > {current_ver}")
                    
                    if latest_ver > current_ver:
                        print("发现新版本")
                        
                        # 获取第一个可用的资源
                        download_url = None
                        checksum = ""
                        
                        if latest_release["assets"]:
                            asset = latest_release["assets"][0]
                            download_url = asset["browser_download_url"]
                            print(f"找到更新文件: {asset['name']}")
                            print(f"下载地址: {download_url}")
                        else:
                            print("警告: 发布中没有任何资源文件")
                        
                        # 如果没有找到任何可用版本，返回错误
                        if not download_url:
                            print("未找到可用的更新文件")
                            return {
                                "has_update": False,
                                "error": "未找到可用的更新文件，请联系开发者"
                            }
                        
                        # 提取 SHA256 校验值
                        body = latest_release.get("body", "")
                        print("\n发布说明:")
                        print(body)
                        print("\n正在查找校验值...")
                        
                        for line in body.split("\n"):
                            line = line.strip()
                            if line.startswith("SHA256"):
                                checksum = line.split(":", 1)[1].strip()
                                print(f"找到校验值: {checksum}")
                                break
                        
                        if not checksum:
                            print("警告: 未找到校验值")
                        
                        update_info = {
                            "has_update": True,
                            "version": latest_version,
                            "download_url": download_url,
                            "release_notes": latest_release["body"],
                            "checksum": checksum,
                            "publish_date": latest_release["published_at"]
                        }
                    else:
                        print(f"版本比较结果: 当前版本 {self.current_version} 已是最新")
                        update_info = {"has_update": False}
                        
                except version.InvalidVersion as e:
                    print(f"版本号解析错误: {str(e)}")
                    return {"has_update": False, "error": f"版本号格式错误: {str(e)}"}
                    
                # 更新最后检查时间
                config = self.load_config()
                config["last_check"] = datetime.now().isoformat()
                self.save_config(config)
                
                return update_info
            else:
                error_msg = f"API请求失败: {response.status_code}"
                if response.status_code == 403:
                    error_msg += "\n请考虑配置GitHub Token以提高API访问限制"
                print(f"API请求失败，状态码: {response.status_code}")
                print(f"响应内容: {response.text}")
                return {"has_update": False, "error": error_msg}
                
        except Exception as e:
            print(f"检查更新时出错: {str(e)}")
            import traceback
            print("错误详情:")
            print(traceback.format_exc())
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
            print(f"开始下载更新: {download_url}")
            # 禁用SSL验证
            response = requests.get(download_url, stream=True, timeout=30, verify=False)
            total_size = int(response.headers.get('content-length', 0))
            
            # 下载到临时文件
            temp_file = self.temp_dir / "update.exe"
            if temp_file.exists():
                temp_file.unlink()
            
            print(f"下载到临时文件: {temp_file}")
            block_size = 1024
            downloaded = 0
            
            with open(temp_file, 'wb') as f:
                for data in response.iter_content(block_size):
                    downloaded += len(data)
                    f.write(data)
                    if callback:
                        callback(downloaded / total_size * 100)
            
            print("下载完成，开始验证文件...")
            # 验证文件完整性
            if checksum and not self.verify_file(temp_file, checksum):
                raise Exception("文件校验失败")
            
            print(f"文件验证成功，路径: {temp_file}")
            return str(temp_file)
            
        except Exception as e:
            print(f"下载更新时出错: {str(e)}")
            return None
    
    def backup_current_version(self):
        """备份当前版本"""
        try:
            # 获取当前程序路径
            if getattr(sys, 'frozen', False):
                # 如果是打包后的exe
                current_exe = sys.executable
            else:
                # 如果是python脚本
                current_exe = sys.argv[0]
            
            print(f"备份当前版本: {current_exe}")
            backup_file = self.backup_dir / f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.exe"
            shutil.copy2(current_exe, backup_file)
            print(f"备份成功: {backup_file}")
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