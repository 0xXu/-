#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import shutil
import subprocess
import platform

def build_executable():
    """使用PyInstaller构建可执行文件"""
    print("开始构建InvestLedger可执行文件...")
    
    # 清理之前的构建
    if os.path.exists("build"):
        shutil.rmtree("build")
    if os.path.exists("dist"):
        shutil.rmtree("dist")
    
    # PyInstaller命令
    cmd = [
        "pyinstaller",
        "--name=InvestLedger",
        "--windowed",  # 无控制台窗口
        "--onedir",    # 单目录模式
        "--icon=InvestLedger/ui/resources/icon.ico",  # 图标 (如果存在)
        "--add-data=InvestLedger/ui;InvestLedger/ui",  # 添加UI资源
        "run.py"
    ]
    
    # 处理Windows路径分隔符
    if platform.system() == "Windows":
        cmd[5] = "--add-data=InvestLedger/ui;InvestLedger/ui"
    else:
        cmd[5] = "--add-data=InvestLedger/ui:InvestLedger/ui"
    
    # 运行PyInstaller
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("构建失败!")
        print(result.stderr)
        return False
    
    print("构建成功! 可执行文件位于 dist/InvestLedger 目录")
    return True

if __name__ == "__main__":
    if build_executable():
        # 构建成功后的操作
        print("\n后续步骤:")
        print("1. 将dist/InvestLedger目录中的文件打包为安装程序")
        print("2. 分发给用户")
    else:
        sys.exit(1) 