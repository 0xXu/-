import sys
import subprocess
import pkg_resources
import os
from pathlib import Path

def check_dependencies():
    """检查并安装依赖"""
    required = {
        'pandas': 'pandas>=1.5.0',
        'ttkbootstrap': 'ttkbootstrap>=1.10.1',
        'matplotlib': 'matplotlib>=3.7.1',
        'pillow': 'pillow>=9.5.0',
        'openpyxl': 'openpyxl>=3.1.2'
    }
    
    missing = []
    
    for package, requirement in required.items():
        try:
            pkg_resources.require(requirement)
        except:
            missing.append(requirement)
    
    if missing:
        print("正在安装缺失的依赖包...")
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing)
            print("依赖安装完成！")
        except Exception as e:
            print(f"依赖安装失败：{str(e)}")
            return False
    
    return True

def main():
    """主函数"""
    try:
        # 检查src目录是否存在
        if not Path('src').exists():
            print("错误：找不到src目录！")
            return
            
        # 检查必要文件
        required_files = ['main.py', 'utils.py', 'database.py', 'charts.py']
        missing_files = [f for f in required_files if not (Path('src') / f).exists()]
        
        if missing_files:
            print(f"错误：以下文件缺失：{', '.join(missing_files)}")
            return
            
        # 检查并安装依赖
        if not check_dependencies():
            print("程序启动失败：依赖安装出错")
            return
            
        # 添加src目录到Python路径
        sys.path.insert(0, str(Path('src').absolute()))
        
        # 导入并运行主程序
        from main import StockTracker
        app = StockTracker()
        app.mainloop()
        
    except Exception as e:
        print(f"程序启动失败：{str(e)}")
        input("按回车键退出...")

if __name__ == "__main__":
    main() 