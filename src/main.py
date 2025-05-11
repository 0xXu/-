import sys
import tkinter as tk
from tkinter import ttk, filedialog
import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from ttkbootstrap.scrolled import ScrolledFrame, ScrolledText
from ttkbootstrap.dialogs import Messagebox
from pathlib import Path
import json
import sqlite3
from datetime import datetime
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib
matplotlib.use('TkAgg')
import seaborn as sns
import re
import argparse
import os
import subprocess

# 导入自定义模块
from database import DatabaseManager
from utils import DataValidator
from charts import ChartGenerator
from version_checker import VersionChecker

# 配置matplotlib中文显示
from matplotlib.font_manager import FontProperties
def set_matplotlib_chinese():
    try:
        # 设置中文字体
        plt.rcParams['font.family'] = ['Microsoft YaHei', 'SimHei', 'sans-serif']
        plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题
        
        # 尝试加载微软雅黑字体
        font = FontProperties(fname=r'C:/Windows/Fonts/msyh.ttc')
        return font
    except Exception as e:
        print(f"设置中文字体时出错：{str(e)}")
        return None

# 获取中文字体
chinese_font = set_matplotlib_chinese()

class StockTracker(ttk.Window):
    def __init__(self):
        self.version = "1.0.0"  # 当前版本号
        
        super().__init__(themename="litera")
        self.title("个人投资记账程序")
        self.geometry("1200x800")
        self.minsize(1000, 700)
        
        # 创建顶部工具栏
        self.create_toolbar()
        
        # 创建菜单栏
        self.create_menu()
        
        # 配置文件和数据库初始化
        self.init_config()
        self.init_database()
        
        # 创建主界面
        self.create_gui()
        
        # 绑定快捷键
        self.bind_shortcuts()
        
        # 刷新数据显示
        self.refresh_data()
        
        # 处理命令行参数
        self.handle_command_line_args()
        
        # 初始化更新检查器
        self.version_checker = VersionChecker(self.version)
        
        # 检查自动更新
        if self.version_checker.should_check_update():
            self.check_for_updates(silent=True)
        
    def init_config(self):
        """初始化配置文件"""
        self.config_dir = Path.home() / "AccountTracker"
        self.config_dir.mkdir(exist_ok=True)
        self.config_file = self.config_dir / "config.json"
        self.backup_dir = self.config_dir / "backup"
        self.backup_dir.mkdir(exist_ok=True)
        
        if not self.config_file.exists():
            default_config = {
                "theme": "litera",
                "backup_interval": 30,  # 分钟
                "last_backup": "",
                "window_size": "1200x800"
            }
            with open(self.config_file, "w", encoding="utf-8") as f:
                json.dump(default_config, f, ensure_ascii=False, indent=4)
        
    def init_database(self):
        """初始化SQLite数据库"""
        self.db = DatabaseManager(self.config_dir / "transactions.db", self.backup_dir)
        
    def create_gui(self):
        """创建图形界面"""
        # 创建主布局
        self.main_paned = ttk.PanedWindow(self, orient=HORIZONTAL)
        self.main_paned.pack(fill=BOTH, expand=YES, padx=5, pady=5)
        
        # 左侧面板 - 数据输入区
        self.left_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(self.left_frame, weight=40)
        
        # 右侧面板 - 数据展示区
        self.right_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(self.right_frame, weight=60)
        
        self.create_input_panel()
        self.create_display_panel()
        
    def create_input_panel(self):
        """创建左侧输入面板"""
        # 标题
        title_frame = ttk.Frame(self.left_frame)
        title_frame.pack(fill=X, padx=5, pady=5)
        ttk.Label(title_frame, text="数据输入", font=("微软雅黑", 12, "bold")).pack(side=LEFT)
        
        # 快速录入表单
        quick_input_frame = ttk.LabelFrame(self.left_frame, text="快速录入", padding=10)
        quick_input_frame.pack(fill=X, padx=5, pady=5)
        
        # 股票名称输入
        stock_frame = ttk.Frame(quick_input_frame)
        stock_frame.pack(fill=X, pady=5)
        ttk.Label(stock_frame, text="股票名称:").pack(side=LEFT)
        self.stock_entry = ttk.Entry(stock_frame)
        self.stock_entry.pack(side=LEFT, fill=X, expand=YES, padx=5)
        
        # 金额输入
        amount_frame = ttk.Frame(quick_input_frame)
        amount_frame.pack(fill=X, pady=5)
        ttk.Label(amount_frame, text="金额(元):").pack(side=LEFT)
        self.amount_entry = ttk.Entry(amount_frame)
        self.amount_entry.pack(side=LEFT, fill=X, expand=YES, padx=5)
        
        # 盈亏选择
        self.profit_var = tk.StringVar(value="盈")
        profit_frame = ttk.Frame(quick_input_frame)
        profit_frame.pack(fill=X, pady=5)
        ttk.Radiobutton(profit_frame, text="盈", variable=self.profit_var, value="盈").pack(side=LEFT)
        ttk.Radiobutton(profit_frame, text="亏", variable=self.profit_var, value="亏").pack(side=LEFT, padx=20)
        
        # 日期选择
        date_frame = ttk.Frame(quick_input_frame)
        date_frame.pack(fill=X, pady=5)
        ttk.Label(date_frame, text="交易日期:").pack(side=LEFT)
        self.date_entry = ttk.DateEntry(date_frame)
        self.date_entry.pack(side=LEFT, fill=X, expand=YES, padx=5)
        
        # 备注输入
        note_frame = ttk.Frame(quick_input_frame)
        note_frame.pack(fill=X, pady=5)
        ttk.Label(note_frame, text="备注:").pack(side=LEFT)
        self.note_entry = ttk.Entry(note_frame)
        self.note_entry.pack(side=LEFT, fill=X, expand=YES, padx=5)
        
        # 快速录入按钮
        ttk.Button(quick_input_frame, text="添加记录", command=self.add_record, style="primary.TButton").pack(fill=X, pady=10)
        
        # 批量输入区域
        batch_input_frame = ttk.LabelFrame(self.left_frame, text="批量输入", padding=10)
        batch_input_frame.pack(fill=BOTH, expand=YES, padx=5, pady=5)
        
        # 文本输入区
        self.batch_text = ScrolledText(batch_input_frame, height=10)
        self.batch_text.pack(fill=BOTH, expand=YES, pady=5)
        
        # 批量导入按钮
        button_frame = ttk.Frame(batch_input_frame)
        button_frame.pack(fill=X, pady=5)
        ttk.Button(button_frame, text="导入文件", command=self.import_file).pack(side=LEFT, padx=5)
        ttk.Button(button_frame, text="解析数据", command=self.parse_batch_data, style="primary.TButton").pack(side=LEFT)
        ttk.Button(button_frame, text="清空", command=lambda: self.batch_text.delete(1.0, tk.END)).pack(side=RIGHT)
        
    def create_display_panel(self):
        """创建右侧显示面板"""
        # 创建选项卡
        self.notebook = ttk.Notebook(self.right_frame)
        self.notebook.pack(fill=BOTH, expand=YES)
        
        # 交易记录表格
        self.create_transaction_tab()
        
        # 统计分析
        self.create_stats_tab()
        
        # 图表展示
        self.create_charts_tab()
        
    def create_transaction_tab(self):
        """创建交易记录表格页"""
        transaction_frame = ttk.Frame(self.notebook)
        self.notebook.add(transaction_frame, text="交易记录")
        
        # 创建工具栏
        toolbar = ttk.Frame(transaction_frame)
        toolbar.pack(fill=X, padx=5, pady=5)
        
        # 添加导出按钮
        ttk.Button(toolbar, text="导出Excel", command=self.export_excel).pack(side=RIGHT, padx=5)
        ttk.Button(toolbar, text="删除选中", command=self.delete_selected, style="danger.TButton").pack(side=RIGHT, padx=5)
        ttk.Button(toolbar, text="清空所有", command=self.clear_all_records, style="danger.Outline.TButton").pack(side=RIGHT, padx=5)
        
        # 创建筛选框架
        filter_frame = ttk.LabelFrame(transaction_frame, text="数据筛选", padding=5)
        filter_frame.pack(fill=X, padx=5, pady=5)
        
        # 股票名称筛选
        stock_filter_frame = ttk.Frame(filter_frame)
        stock_filter_frame.pack(fill=X, pady=2)
        ttk.Label(stock_filter_frame, text="股票名称:").pack(side=LEFT)
        self.stock_filter = ttk.Entry(stock_filter_frame)
        self.stock_filter.pack(side=LEFT, padx=5)
        
        # 日期范围筛选
        date_filter_frame = ttk.Frame(filter_frame)
        date_filter_frame.pack(fill=X, pady=2)
        ttk.Label(date_filter_frame, text="日期范围:").pack(side=LEFT)
        self.start_date = ttk.DateEntry(date_filter_frame)
        self.start_date.pack(side=LEFT, padx=5)
        ttk.Label(date_filter_frame, text="至").pack(side=LEFT)
        self.end_date = ttk.DateEntry(date_filter_frame)
        self.end_date.pack(side=LEFT, padx=5)
        
        # 盈亏筛选
        profit_filter_frame = ttk.Frame(filter_frame)
        profit_filter_frame.pack(fill=X, pady=2)
        ttk.Label(profit_filter_frame, text="盈亏类型:").pack(side=LEFT)
        self.profit_filter = ttk.Combobox(profit_filter_frame, values=["全部", "盈利", "亏损"])
        self.profit_filter.set("全部")
        self.profit_filter.pack(side=LEFT, padx=5)
        
        # 金额范围筛选
        amount_filter_frame = ttk.Frame(filter_frame)
        amount_filter_frame.pack(fill=X, pady=2)
        ttk.Label(amount_filter_frame, text="金额范围:").pack(side=LEFT)
        self.min_amount = ttk.Entry(amount_filter_frame, width=15)
        self.min_amount.pack(side=LEFT, padx=5)
        ttk.Label(amount_filter_frame, text="至").pack(side=LEFT)
        self.max_amount = ttk.Entry(amount_filter_frame, width=15)
        self.max_amount.pack(side=LEFT, padx=5)
        
        # 筛选按钮
        button_frame = ttk.Frame(filter_frame)
        button_frame.pack(fill=X, pady=5)
        ttk.Button(button_frame, text="应用筛选", command=self.apply_filters, style="primary.TButton").pack(side=LEFT, padx=5)
        ttk.Button(button_frame, text="重置筛选", command=self.reset_filters).pack(side=LEFT)
        
        # 创建表格
        self.create_transaction_table(transaction_frame)
        
    def create_transaction_table(self, parent):
        """创建交易记录表格"""
        # 表格区域
        table_frame = ttk.Frame(parent)
        table_frame.pack(fill=BOTH, expand=YES, padx=5, pady=5)
        
        # 创建表格（移除ID列）
        columns = ("日期", "股票名称", "盈亏", "金额", "备注")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings")
        
        # 设置列标题和宽度
        column_widths = {
            "日期": 120,
            "股票名称": 150,
            "盈亏": 80,
            "金额": 120,
            "备注": 200
        }
        
        for col in columns:
            self.tree.heading(col, text=col, command=lambda c=col: self.sort_treeview(c))
            self.tree.column(col, width=column_widths.get(col, 100))
        
        # 添加滚动条
        scrollbar = ttk.Scrollbar(table_frame, orient=VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        
        # 打包组件
        self.tree.pack(side=LEFT, fill=BOTH, expand=YES)
        scrollbar.pack(side=RIGHT, fill=Y)
        
    def apply_filters(self):
        """应用筛选条件"""
        try:
            conditions = []
            params = []
            
            # 股票名称筛选
            stock_name = self.stock_filter.get().strip()
            if stock_name:
                conditions.append("stock_name LIKE ?")
                params.append(f"%{stock_name}%")
            
            # 日期范围筛选
            start_date = self.start_date.entry.get().strip()
            end_date = self.end_date.entry.get().strip()
            
            if start_date:
                try:
                    # 尝试多种日期格式
                    for fmt in ['%Y-%m-%d', '%Y/%m/%d', '%Y年%m月%d日']:
                        try:
                            start_date = datetime.strptime(start_date, fmt).strftime('%Y-%m-%d')
                            conditions.append("trade_date >= ?")
                            params.append(start_date)
                            break
                        except ValueError:
                            continue
                    else:
                        raise ValueError("无效的开始日期格式")
                except ValueError as e:
                    self.show_centered_message(f"开始日期格式错误: {e}", "错误", "error")
                    return
            
            if end_date:
                try:
                    # 尝试多种日期格式
                    for fmt in ['%Y-%m-%d', '%Y/%m/%d', '%Y年%m月%d日']:
                        try:
                            end_date = datetime.strptime(end_date, fmt).strftime('%Y-%m-%d')
                            conditions.append("trade_date <= ?")
                            params.append(end_date)
                            break
                        except ValueError:
                            continue
                    else:
                        raise ValueError("无效的结束日期格式")
                except ValueError as e:
                    self.show_centered_message(f"结束日期格式错误: {e}", "错误", "error")
                    return
            
            # 盈亏类型筛选
            profit_type = self.profit_filter.get()
            if profit_type != "全部":
                conditions.append("is_profit = ?")
                params.append(1 if profit_type == "盈利" else 0)
            
            # 金额范围筛选
            min_amount = self.min_amount.get().strip()
            max_amount = self.max_amount.get().strip()
            
            if min_amount:
                try:
                    min_amount = float(min_amount.replace(',', ''))
                    conditions.append("amount >= ?")
                    params.append(min_amount)
                except ValueError:
                    self.show_centered_message("最小金额必须是数字", "错误", "error")
                    return
            
            if max_amount:
                try:
                    max_amount = float(max_amount.replace(',', ''))
                    conditions.append("amount <= ?")
                    params.append(max_amount)
                except ValueError:
                    self.show_centered_message("最大金额必须是数字", "错误", "error")
                    return
            
            # 获取筛选后的数据
            filtered_data = self.db.get_filtered_transactions(conditions, params)
            
            # 更新表格显示
            self.update_transaction_table(filtered_data)
            
        except Exception as e:
            self.show_centered_message(f"筛选失败：{str(e)}", "错误", "error")
            import traceback
            print(traceback.format_exc())
        
    def reset_filters(self):
        """重置所有筛选条件"""
        try:
            self.stock_filter.delete(0, tk.END)
            self.start_date.entry.delete(0, tk.END)
            self.end_date.entry.delete(0, tk.END)
            self.profit_filter.set("全部")
            self.min_amount.delete(0, tk.END)
            self.max_amount.delete(0, tk.END)
            
            # 重新加载所有数据
            records = self.db.get_all_transactions()
            self.update_transaction_table(records)
            
        except Exception as e:
            self.show_centered_message(f"重置失败：{str(e)}", "错误", "error")
            import traceback
            print(traceback.format_exc())
        
    def update_transaction_table(self, data):
        """更新表格数据"""
        # 清空现有数据
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # 添加新数据（不包含ID）
        for record in data:
            values = (
                record['trade_date'].strftime('%Y年%m月%d日'),
                record['stock_name'],
                '盈' if record['is_profit'] else '亏',
                f"{record['amount']:,.2f}",
                record['note'] or ''
            )
            self.tree.insert('', 'end', values=values, tags=(str(record['id']),))  # 将ID保存在tags中
        
    def create_stats_tab(self):
        """创建统计分析页"""
        stats_frame = ttk.Frame(self.notebook)
        self.notebook.add(stats_frame, text="统计分析")
        
        # 创建统计信息展示区
        self.stats_text = ScrolledText(stats_frame, height=10, font=("微软雅黑", 10))
        self.stats_text.pack(fill=BOTH, expand=YES, padx=5, pady=5)
        
        # 添加刷新按钮
        refresh_btn = ttk.Button(stats_frame, text="刷新统计", command=self.update_statistics)
        refresh_btn.pack(pady=5)
        
    def create_charts_tab(self):
        """创建图表展示页"""
        charts_frame = ttk.Frame(self.notebook)
        self.notebook.add(charts_frame, text="图表展示")
        
        # 创建控制面板
        control_frame = ttk.Frame(charts_frame)
        control_frame.pack(fill=X, padx=5, pady=5)
        
        # 创建图表选择下拉框
        ttk.Label(control_frame, text="选择图表:").pack(side=LEFT, padx=(0,5))
        self.chart_type = tk.StringVar(value="收益趋势")
        chart_combo = ttk.Combobox(control_frame, textvariable=self.chart_type, values=["收益趋势", "股票分布", "月度统计"])
        chart_combo.pack(side=LEFT, padx=5)
        chart_combo.bind('<<ComboboxSelected>>', self.update_chart)
        
        # 添加日期筛选
        ttk.Label(control_frame, text="起始日期:").pack(side=LEFT, padx=(20,5))
        self.chart_start_date = ttk.DateEntry(control_frame, dateformat="%Y-%m-%d")
        self.chart_start_date.pack(side=LEFT, padx=5)
        # 立即清空日期
        self.chart_start_date.entry.delete(0, tk.END)
        # 绑定事件
        self.chart_start_date.entry.bind('<FocusOut>', self.update_chart)
        self.chart_start_date.bind('<<DateEntrySelected>>', self.update_chart)
        
        ttk.Label(control_frame, text="结束日期:").pack(side=LEFT, padx=(5,5))
        self.chart_end_date = ttk.DateEntry(control_frame, dateformat="%Y-%m-%d")
        self.chart_end_date.pack(side=LEFT, padx=5)
        # 立即清空日期
        self.chart_end_date.entry.delete(0, tk.END)
        # 绑定事件
        self.chart_end_date.entry.bind('<FocusOut>', self.update_chart)
        self.chart_end_date.bind('<<DateEntrySelected>>', self.update_chart)
        
        # 清除日期按钮
        ttk.Button(control_frame, text="清除日期", command=self.clear_dates).pack(side=LEFT, padx=5)
        
        # 创建图表容器
        self.chart_container = ttk.Frame(charts_frame)
        self.chart_container.pack(fill=BOTH, expand=YES, padx=5, pady=5)
        
        # 初始化matplotlib图表
        self.fig = plt.Figure(dpi=100)
        self.canvas = FigureCanvasTkAgg(self.fig, master=self.chart_container)
        self.canvas.get_tk_widget().pack(fill=BOTH, expand=YES)
        
        # 添加工具栏
        from matplotlib.backends.backend_tkagg import NavigationToolbar2Tk
        self.toolbar = NavigationToolbar2Tk(self.canvas, self.chart_container)
        self.toolbar.update()
        
        # 绑定窗口大小改变事件
        self.bind('<Configure>', lambda e: self.after(100, self.resize_chart) if e.widget == self else None)
        
        # 绑定图表容器大小改变事件
        self.chart_container.bind('<Configure>', lambda e: self.after(100, self.resize_chart))
        
        # 延迟加载第一个图表
        self.after(100, self.update_chart)
        
    def update_chart(self, event=None):
        """更新图表显示"""
        try:
            # 清空图表
            self.fig.clear()
            
            # 获取统计数据
            stats = self.db.get_statistics()
            
            # 根据选择的图表类型创建相应的图表
            chart_type = self.chart_type.get()
            
            # 导入seaborn美化图表
            import seaborn as sns
            sns.set_style("whitegrid")
            sns.set_palette("colorblind")
            
            if chart_type == "收益趋势":
                self.create_profit_trend_chart(stats['monthly'])
            elif chart_type == "股票分布":
                self.create_stock_distribution_chart(stats['stocks'])
            else:  # 月度统计
                self.create_monthly_stats_chart(stats['monthly'])
            
            # 更新画布
            self.canvas.draw_idle()
            
        except Exception as e:
            self.show_centered_message(f"图表生成失败：{str(e)}", "错误", "error")
            import traceback
            print("图表生成错误：", traceback.format_exc())
        
    def create_profit_trend_chart(self, monthly_data):
        """创建收益趋势图"""
        if not monthly_data:
            self.fig.text(0.5, 0.5, "暂无数据", ha='center', va='center', fontsize=14, fontproperties=chinese_font)
            return
        
        # 准备数据
        months = [f"{item['month'][:7]}" for item in monthly_data]
        profits = [item['net_profit'] for item in monthly_data]
        
        # 创建子图
        ax = self.fig.add_subplot(111)
        
        # 绘制柱状图
        bars = ax.bar(months, profits, color=sns.color_palette("RdYlGn", len(profits)))
        
        # 为每个柱子添加标签
        for bar, profit in zip(bars, profits):
            color = 'green' if profit >= 0 else 'red'
            ax.text(bar.get_x() + bar.get_width()/2., 
                    profit + (max(profits) * 0.02 if profit >= 0 else min(profits) * 0.02), 
                    f'{profit:,.0f}',
                    ha='center', va='bottom', color=color, fontweight='bold', fontproperties=chinese_font)
        
        # 设置标题和标签
        ax.set_title('月度收益趋势', fontsize=14, fontweight='bold', fontproperties=chinese_font)
        ax.set_xlabel('月份', fontsize=12, fontproperties=chinese_font)
        ax.set_ylabel('净收益（元）', fontsize=12, fontproperties=chinese_font)
        
        # 设置网格线
        ax.grid(True, linestyle='--', alpha=0.7)
        
        # 旋转x轴标签
        plt.setp(ax.get_xticklabels(), rotation=45, ha='right')
        
        # 调整布局
        self.fig.tight_layout()
        
    def create_stock_distribution_chart(self, stock_data):
        """创建股票分布图"""
        if not stock_data:
            self.fig.text(0.5, 0.5, "暂无数据", ha='center', va='center', fontsize=14, fontproperties=chinese_font)
            return
        
        # 准备数据
        stocks = [item['stock_name'] for item in stock_data]
        profits = [item['net_profit'] for item in stock_data]
        
        # 按照利润排序
        sorted_indices = sorted(range(len(profits)), key=lambda i: profits[i])
        stocks = [stocks[i] for i in sorted_indices]
        profits = [profits[i] for i in sorted_indices]
        
        # 创建子图
        ax = self.fig.add_subplot(111)
        
        # 设置颜色
        colors = ['#2ecc71' if p >= 0 else '#e74c3c' for p in profits]
        
        # 计算合适的条形高度和间距
        num_stocks = len(stocks)
        total_height = 0.85  # 留出15%的空间给边距
        bar_height = total_height / (num_stocks + (num_stocks - 1) * 0.2)  # 考虑间距
        
        # 创建y轴位置
        y_positions = []
        current_pos = 0
        for i in range(num_stocks):
            y_positions.append(current_pos)
            current_pos += bar_height * 1.2  # 1.2为间距系数
        
        # 绘制水平条形图
        bars = ax.barh(y_positions, profits, color=colors, height=bar_height)
        
        # 设置y轴标签
        ax.set_yticks(y_positions)
        
        # 动态计算字体大小
        font_size = min(10, max(6, 180 / num_stocks))  # 根据数据量动态调整字体大小
        
        # 设置y轴标签，并进行长度截断处理
        max_label_length = min(10, max(4, int(50 / num_stocks)))  # 动态计算最大标签长度
        formatted_labels = []
        for stock in stocks:
            if len(stock) > max_label_length:
                formatted_label = stock[:max_label_length-1] + '…'
            else:
                formatted_label = stock
            formatted_labels.append(formatted_label)
        
        ax.set_yticklabels(formatted_labels, fontproperties=chinese_font, fontsize=font_size)
        
        # 为每个条形添加标签
        for i, (bar, profit) in enumerate(zip(bars, profits)):
            # 确定标签位置和对齐方式
            if profit >= 0:
                x_pos = profit + (max(profits) * 0.01)
                ha = 'left'
            else:
                x_pos = profit - (abs(min(profits)) * 0.01)
                ha = 'right'
            
            # 格式化数值
            if abs(profit) >= 10000:
                profit_text = f'{profit/10000:.1f}万'
            else:
                profit_text = f'{profit:,.0f}'
            
            # 添加数值标签
            ax.text(x_pos, y_positions[i], profit_text,
                   ha=ha, va='center',
                   color='black',
                   fontweight='bold',
                   fontsize=font_size,
                   fontproperties=chinese_font)
        
        # 设置标题和标签
        ax.set_title('股票盈亏分布', pad=20, fontsize=14, fontweight='bold', fontproperties=chinese_font)
        ax.set_xlabel('净收益（元）', fontsize=12, fontproperties=chinese_font)
        
        # 设置x轴格式
        def format_x_label(x, p):
            if abs(x) >= 10000:
                return f'{x/10000:.1f}万'
            return f'{x:,.0f}'
        
        ax.xaxis.set_major_formatter(plt.FuncFormatter(format_x_label))
        
        # 设置网格线
        ax.grid(True, linestyle='--', alpha=0.3, axis='x')
        
        # 移除上边框和右边框
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        
        # 设置背景色
        ax.set_facecolor('#f8f9fa')
        self.fig.patch.set_facecolor('white')
        
        # 设置y轴范围，留出一定边距
        ax.set_ylim(-bar_height, current_pos)
        
        # 调整布局
        self.fig.tight_layout()
        
        # 动态计算左边距
        longest_visible_label = max(len(label) for label in formatted_labels)
        left_margin = min(0.25, 0.1 + longest_visible_label * 0.015)  # 动态计算左边距
        plt.subplots_adjust(left=left_margin)
        
    def create_monthly_stats_chart(self, monthly_data):
        """创建月度统计图"""
        if not monthly_data:
            self.fig.text(0.5, 0.5, "暂无数据", ha='center', va='center', fontsize=14, fontproperties=chinese_font)
            return
        
        # 准备数据
        months = [f"{item['month'][:7]}" for item in monthly_data]
        profits = [item['net_profit'] for item in monthly_data]
        counts = [item['trade_count'] for item in monthly_data]
        
        # 创建子图
        ax1 = self.fig.add_subplot(111)
        ax2 = ax1.twinx()
        
        # 绘制收益柱状图
        bars = ax1.bar(months, profits, color='skyblue', alpha=0.7, label='净收益')
        
        # 绘制交易次数折线图
        line = ax2.plot(months, counts, 'ro-', linewidth=2, markersize=8, label='交易次数')
        
        # 为柱状图添加标签
        for bar, profit in zip(bars, profits):
            color = 'green' if profit >= 0 else 'red'
            ax1.text(bar.get_x() + bar.get_width()/2., 
                    profit + (max(profits) * 0.02 if profit >= 0 else min(profits) * 0.02), 
                    f'{profit:,.0f}',
                    ha='center', va='bottom', color=color, fontweight='bold', fontproperties=chinese_font)
        
        # 为折线图添加标签
        for i, count in enumerate(counts):
            ax2.text(i, count + max(counts) * 0.05, f'{count}笔', 
                    ha='center', va='bottom', color='red', fontweight='bold', fontproperties=chinese_font)
        
        # 设置标题和标签
        ax1.set_title('月度交易统计', fontsize=14, fontweight='bold', fontproperties=chinese_font)
        ax1.set_xlabel('月份', fontsize=12, fontproperties=chinese_font)
        ax1.set_ylabel('净收益（元）', fontsize=12, color='blue', fontproperties=chinese_font)
        ax2.set_ylabel('交易次数（笔）', fontsize=12, color='red', fontproperties=chinese_font)
        
        # 设置网格线
        ax1.grid(True, linestyle='--', alpha=0.7)
        
        # 旋转x轴标签
        plt.setp(ax1.get_xticklabels(), rotation=45, ha='right')
        
        # 添加图例
        lines, labels = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines + lines2, labels + labels2, loc='upper left', prop=chinese_font)
        
        # 调整布局
        self.fig.tight_layout()
        
    def bind_shortcuts(self):
        """绑定快捷键"""
        self.bind("<Control-o>", lambda e: self.import_file())
        self.bind("<Control-s>", lambda e: self.save_data())
        self.bind("<Control-e>", lambda e: self.export_excel())
        self.bind("<Control-r>", lambda e: self.refresh_data())
        self.bind("<F5>", lambda e: self.update_chart())
        self.bind("<Escape>", lambda e: self.clear_selection())
        
    def add_record(self):
        """添加单条记录"""
        try:
            # 获取输入数据
            stock_name = self.stock_entry.get().strip()
            amount = self.amount_entry.get().strip()
            is_profit = self.profit_var.get() == "盈"
            date_str = self.date_entry.entry.get()  # 获取日期字符串
            note = self.note_entry.get().strip()
            
            # 验证数据
            valid, stock_name = DataValidator.validate_stock_name(stock_name)
            if not valid:
                self.show_centered_message(stock_name, "输入错误", "error")
                self.stock_entry.focus()
                return
                
            valid, amount_value, error = DataValidator.validate_amount(amount)
            if not valid:
                self.show_centered_message(error, "输入错误", "error")
                self.amount_entry.focus()
                return
                
            valid, date_value, error = DataValidator.validate_date(date_str)
            if not valid:
                self.show_centered_message(error, "输入错误", "error")
                self.date_entry.focus()
                return
            
            # 构建交易记录
            transaction = {
                'stock_name': stock_name,
                'amount': amount_value,
                'is_profit': is_profit,
                'trade_date': date_value,
                'note': note
            }
            
            # 添加到数据库
            success, error = self.db.add_transaction(transaction)
            if not success:
                self.show_centered_message(f"保存失败：{error}", "数据库错误", "error")
                return
            
            # 清空输入框
            self.stock_entry.delete(0, tk.END)
            self.amount_entry.delete(0, tk.END)
            self.note_entry.delete(0, tk.END)
            self.stock_entry.focus()
            
            # 刷新显示
            self.refresh_data()
            
            # 显示成功消息
            self.show_centered_message("记录添加成功！", "成功", "info")
            
        except Exception as e:
            self.show_centered_message(f"发生错误：{str(e)}", "错误", "error")
        
    def import_file(self):
        """导入文件"""
        try:
            # 打开文件选择对话框
            file_path = filedialog.askopenfilename(
                title="选择交易记录文件",
                filetypes=[("文本文件", "*.txt"), ("所有文件", "*.*")]
            )
            
            if not file_path:
                return
                
            # 读取文件内容
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 将内容显示在批量输入区域
            self.batch_text.delete(1.0, tk.END)
            self.batch_text.insert(1.0, content)
            
            # 自动解析数据
            self.parse_batch_data()
            
        except Exception as e:
            self.show_centered_message(f"文件导入失败：{str(e)}", "错误", "error")
        
    def parse_batch_data(self):
        """解析批量输入的数据"""
        try:
            # 获取文本内容
            content = self.batch_text.get(1.0, tk.END).strip()
            if not content:
                self.show_centered_message("请输入要导入的数据", "提示", "warning")
                return
            
            # 按行分割
            lines = content.split('\n')
            success_count = 0
            duplicate_count = 0
            error_lines = []
            
            # 处理每一行
            for i, line in enumerate(lines, 1):
                if not line.strip():
                    continue
                    
                # 解析行数据
                valid, transaction, error = DataValidator.parse_transaction_line(line)
                if not valid:
                    error_lines.append(f"第{i}行 [原数据: {line}]\n错误原因: {error}\n")
                    continue
                
                # 添加到数据库
                success, db_error = self.db.add_transaction(transaction)
                if not success:
                    if "该记录已存在" in db_error:
                        duplicate_count += 1
                    else:
                        error_lines.append(f"第{i}行 [原数据: {line}]\n数据库错误: {db_error}\n")
                    continue
                
                success_count += 1
            
            # 刷新显示
            self.refresh_data()
            
            # 显示结果
            dialog = ttk.Toplevel()
            dialog.title("导入结果")
            dialog.geometry("600x400")
            
            # 创建滚动文本框
            result_text = ScrolledText(dialog, wrap=tk.WORD, width=70, height=20)
            result_text.pack(fill=BOTH, expand=YES, padx=10, pady=10)
            
            # 添加导入结果信息
            result_text.insert(tk.END, f"成功导入: {success_count} 条记录\n")
            if duplicate_count > 0:
                result_text.insert(tk.END, f"重复记录: {duplicate_count} 条\n")
            result_text.insert(tk.END, "\n")
            
            if error_lines:
                result_text.insert(tk.END, "以下记录导入失败:\n" + "="*50 + "\n\n")
                for error in error_lines:
                    result_text.insert(tk.END, error + "\n")
            
            # 设置只读
            result_text.configure(state='disabled')
            
            # 添加确定按钮
            ttk.Button(dialog, text="确定", command=dialog.destroy).pack(pady=10)
            
            # 设置模态
            dialog.transient(self)
            dialog.grab_set()
            self.wait_window(dialog)
            
        except Exception as e:
            self.show_centered_message(f"数据解析失败：{str(e)}", "错误", "error")
        
    def export_excel(self):
        """导出Excel文件"""
        try:
            # 选择保存位置
            file_path = filedialog.asksaveasfilename(
                title="导出Excel",
                defaultextension=".xlsx",
                filetypes=[("Excel文件", "*.xlsx"), ("所有文件", "*.*")],
                initialfile=f"交易记录_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
            )
            
            if not file_path:
                return
                
            # 导出数据
            success, error = self.db.export_to_excel(Path(file_path))
            
            if success:
                self.show_centered_message("数据导出成功！", "成功", "info")
            else:
                self.show_centered_message(f"导出失败：{error}", "错误", "error")
                
        except Exception as e:
            self.show_centered_message(f"导出失败：{str(e)}", "错误", "error")
        
    def sort_treeview(self, col):
        """表格排序"""
        try:
            # 获取所有项目
            items = [(self.tree.set(item, col), item) for item in self.tree.get_children('')]
            
            # 确定排序方向
            reverse = False
            if hasattr(self, '_sort_reverse') and self._sort_reverse:
                reverse = True
            self._sort_reverse = not reverse
            
            # 特殊处理日期和金额列
            if col == "日期":
                # 将日期转换为datetime对象进行排序
                items = [(datetime.strptime(date, "%Y年%m月%d日"), item) for date, item in items]
            elif col == "金额":
                # 提取数字部分进行排序
                items = [(float(re.sub(r'[^\d.]', '', amount)), item) for amount, item in items]
            
            # 排序
            items.sort(reverse=reverse)
            
            # 重新排列表格项目
            for index, (val, item) in enumerate(items):
                self.tree.move(item, '', index)
                
        except Exception as e:
            self.show_centered_message(f"排序失败：{str(e)}", "错误", "error")
        
    def clear_selection(self):
        """清除选择"""
        self.tree.selection_remove(self.tree.selection())
        
    def refresh_data(self):
        """刷新数据显示"""
        try:
            # 清空表格
            for item in self.tree.get_children():
                self.tree.delete(item)
            
            # 获取所有记录
            records = self.db.get_all_transactions()
            
            # 添加到表格
            for record in records:
                values = (
                    record['trade_date'].strftime('%Y年%m月%d日'),
                    record['stock_name'],
                    '盈' if record['is_profit'] else '亏',
                    f"{record['amount']:,.2f}",
                    record['note'] or ''
                )
                self.tree.insert('', 'end', values=values, tags=(str(record['id']),))
            
            # 更新统计信息
            self.update_statistics()
            
        except Exception as e:
            self.show_centered_message(f"数据刷新失败：{str(e)}", "错误", "error")
        
    def update_statistics(self):
        """更新统计信息"""
        try:
            # 获取统计数据
            stats = self.db.get_statistics()
            
            # 清空现有内容
            self.stats_text.delete(1.0, tk.END)
            
            # 添加总体统计
            total_stats = stats['total']
            monthly_stats = stats['monthly']
            stock_stats = stats['stocks']
            
            # 计算额外的统计指标
            total_profit = total_stats['total_profit'] or 0
            total_loss = total_stats['total_loss'] or 0
            net_profit = total_stats['net_profit'] or 0
            transaction_count = total_stats['transaction_count'] or 0
            stock_count = total_stats['stock_count'] or 0
            
            # 计算胜率
            profit_count = sum(1 for s in stock_stats if s['net_profit'] > 0)
            loss_count = sum(1 for s in stock_stats if s['net_profit'] < 0)
            win_rate = (profit_count / stock_count * 100) if stock_count > 0 else 0
            
            # 计算最大单笔盈亏
            max_profit = max((s['net_profit'] for s in stock_stats), default=0)
            max_loss = min((s['net_profit'] for s in stock_stats), default=0)
            
            # 计算月均交易次数和收益
            if monthly_stats:
                avg_monthly_trades = sum(m['trade_count'] for m in monthly_stats) / len(monthly_stats)
                avg_monthly_profit = sum(m['net_profit'] for m in monthly_stats) / len(monthly_stats)
            else:
                avg_monthly_trades = 0
                avg_monthly_profit = 0
            
            summary = "===== 总体统计 =====\n"
            # 基本统计
            summary += f"总收益: {net_profit:,.2f}元\n"
            summary += f"总盈利: {total_profit:,.2f}元\n"
            summary += f"总亏损: {total_loss:,.2f}元\n"
            summary += f"总交易次数: {transaction_count}笔\n"
            summary += f"交易股票数: {stock_count}支\n"
            if transaction_count > 0:
                summary += f"平均每笔收益: {(net_profit/transaction_count):,.2f}元\n"
            
            # 胜率统计
            summary += f"\n===== 胜率统计 =====\n"
            summary += f"盈利股票数: {profit_count}支\n"
            summary += f"亏损股票数: {loss_count}支\n"
            summary += f"总体胜率: {win_rate:.1f}%\n"
            
            # 极值统计
            summary += f"\n===== 极值统计 =====\n"
            summary += f"最大单支盈利: {max_profit:,.2f}元\n"
            summary += f"最大单支亏损: {max_loss:,.2f}元\n"
            if total_profit > 0:
                summary += f"盈亏比: {abs(total_profit/total_loss):,.2f}\n" if total_loss != 0 else "盈亏比: ∞\n"
            
            # 月度平均
            summary += f"\n===== 月度平均 =====\n"
            summary += f"月均交易次数: {avg_monthly_trades:.1f}笔\n"
            summary += f"月均收益: {avg_monthly_profit:,.2f}元\n"
            
            # 显示统计信息
            self.stats_text.insert(tk.END, summary)
            
            # 添加月度统计
            if monthly_stats:
                self.stats_text.insert(tk.END, "\n===== 月度统计 =====\n")
                self.stats_text.insert(tk.END, self._format_monthly_stats(monthly_stats))
            
            # 添加股票统计
            if stock_stats:
                self.stats_text.insert(tk.END, "\n===== 股票统计 =====\n")
                self.stats_text.insert(tk.END, self._format_stock_stats(stock_stats))
            
        except Exception as e:
            self.show_centered_message(f"更新统计信息时发生错误：{str(e)}", "错误", "error")
            
    def _format_monthly_stats(self, monthly_stats):
        """格式化月度统计信息"""
        if not monthly_stats:
            return "暂无数据"
            
        lines = []
        for stat in monthly_stats:
            lines.append(f"{stat['month']}: 净收益 {stat['net_profit']:,.2f} 元，交易 {stat['trade_count']} 笔")
        return "\n".join(lines)
        
    def _format_stock_stats(self, stock_stats):
        """格式化股票统计信息"""
        if not stock_stats:
            return "暂无数据"
            
        lines = []
        for stat in stock_stats:
            lines.append(
                f"{stat['stock_name']}: 净收益 {stat['net_profit']:,.2f} 元，"
                f"交易 {stat['trade_count']} 笔"
            )
        return "\n".join(lines)
        
    def save_data(self):
        """保存数据（备份）"""
        try:
            success, path = self.db.backup_database()
            if success:
                self.show_centered_message(f"数据已备份到：\n{path}", "备份成功", "info")
            else:
                self.show_centered_message(f"备份失败：{path}", "错误", "error")
        except Exception as e:
            self.show_centered_message(f"备份失败：{str(e)}", "错误", "error")

    def show_context_menu(self, event):
        """显示右键菜单"""
        # 确保点击的是有效行
        item = self.tree.identify_row(event.y)
        if item:
            # 选中被点击的行
            self.tree.selection_set(item)
            
            # 创建右键菜单
            menu = tk.Menu(self, tearoff=0)
            menu.add_command(label="删除", command=self.delete_selected)
            menu.add_separator()
            menu.add_command(label="清空所有", command=self.clear_all_records)
            
            # 显示菜单
            menu.post(event.x_root, event.y_root)
            
    def delete_selected(self):
        """删除选中的记录"""
        selected_items = self.tree.selection()
        if not selected_items:
            self.show_centered_message("请先选择要删除的记录", "提示", "warning")
            return
            
        # 获取选中记录的ID（从tags中获取）
        ids = [int(self.tree.item(item)["tags"][0]) for item in selected_items]
        
        # 确认删除
        if not self.show_centered_message(
            f"确定要删除选中的 {len(ids)} 条记录吗？",
            "确认删除",
            "question",
            buttons=['是', '否']
        ):
            return
            
        # 执行删除
        success, error = self.db.delete_transactions(ids)
        if success:
            self.refresh_data()
            self.show_centered_message("删除成功！", "成功", "info")
        else:
            self.show_centered_message(f"删除失败：{error}", "错误", "error")
            
    def clear_all_records(self):
        """清空所有记录"""
        # 确认清空
        if not self.show_centered_message(
            "确定要清空所有记录吗？此操作不可恢复！",
            "确认清空",
            "question",
            buttons=['是', '否']
        ):
            return
            
        # 再次确认
        if not self.show_centered_message(
            "最后确认：真的要删除所有记录吗？",
            "再次确认",
            "question",
            buttons=['是', '否']
        ):
            return
            
        # 执行清空
        success, error = self.db.clear_all_transactions()
        if success:
            self.refresh_data()
            self.show_centered_message("已清空所有记录！", "成功", "info")
        else:
            self.show_centered_message(f"清空失败：{error}", "错误", "error")

    def show_centered_message(self, message, title="提示", message_type="info", buttons=None):
        """显示居中的消息框"""
        dialog = None
        
        if message_type == "info":
            dialog = Messagebox.show_info(message, title, parent=self)
        elif message_type == "error":
            dialog = Messagebox.show_error(message, title, parent=self)
        elif message_type == "warning":
            dialog = Messagebox.show_warning(message, title, parent=self)
        elif message_type == "question":
            return Messagebox.show_question(message, title, parent=self, buttons=buttons)
        else:
            dialog = Messagebox.show_info(message, title, parent=self)
        
        # 确保对话框居中显示
        if dialog:
            self.center_window(dialog)
        
        return dialog

    def center_window(self, window):
        """将窗口居中显示"""
        window.update_idletasks()
        width = window.winfo_width()
        height = window.winfo_height()
        x = (window.winfo_screenwidth() // 2) - (width // 2)
        y = (window.winfo_screenheight() // 2) - (height // 2)
        window.geometry('{}x{}+{}+{}'.format(width, height, x, y))
        window.deiconify()

    def clear_dates(self):
        """清除日期选择"""
        self.chart_start_date.entry.delete(0, tk.END)
        self.chart_end_date.entry.delete(0, tk.END)
        self.update_chart()

    def get_chart_date_range(self):
        """获取图表的日期范围"""
        try:
            start_date = None
            end_date = None
            
            start_str = self.chart_start_date.entry.get().strip()
            end_str = self.chart_end_date.entry.get().strip()
            
            if start_str:
                start_date = datetime.strptime(start_str, '%Y-%m-%d')
            if end_str:
                end_date = datetime.strptime(end_str, '%Y-%m-%d')
            
            return start_date, end_date
        except ValueError:
            return None, None

    def resize_chart(self):
        """调整图表大小"""
        try:
            # 获取图表容器的大小
            container_width = self.chart_container.winfo_width()
            container_height = self.chart_container.winfo_height()
            
            # 确保容器有合理的大小
            if container_width <= 1 or container_height <= 1:
                return
            
            # 为工具栏预留空间
            toolbar_height = self.toolbar.winfo_height() if hasattr(self, 'toolbar') else 0
            available_height = container_height - toolbar_height - 20  # 额外留出一些边距
            
            # 计算合适的图表大小（考虑DPI）
            dpi = self.fig.dpi
            width_inches = (container_width - 40) / dpi  # 留出左右边距
            height_inches = (available_height - 40) / dpi  # 留出上下边距
            
            # 设置最小尺寸
            width_inches = max(width_inches, 6)
            height_inches = max(height_inches, 4)
            
            # 设置图表大小
            self.fig.set_size_inches(width_inches, height_inches, forward=True)
            
            # 更新画布
            self.canvas.draw_idle()
            
        except Exception as e:
            print(f"调整图表大小时出错：{str(e)}")

    def handle_command_line_args(self):
        """处理命令行参数"""
        parser = argparse.ArgumentParser(description='个人投资记账程序')
        parser.add_argument('--update', type=str, help='更新模式，需要结束的进程PID')
        args = parser.parse_args()
        
        # 检查是否有待安装的更新
        update_flag_file = Path(self.config_dir) / "update_ready"
        if update_flag_file.exists():
            try:
                new_version_path = update_flag_file.read_text().strip()
                if os.path.exists(new_version_path):
                    # 启动新版本并退出当前版本
                    subprocess.Popen([new_version_path])
                    update_flag_file.unlink()  # 删除标记文件
                    sys.exit(0)
            except Exception as e:
                print(f"安装更新失败: {str(e)}")
                if update_flag_file.exists():
                    update_flag_file.unlink()
        
        if args.update:
            try:
                old_pid = int(args.update)
                # 等待旧进程结束
                import time
                import psutil
                
                max_wait = 30  # 最大等待30秒
                while max_wait > 0:
                    if not psutil.pid_exists(old_pid):
                        break
                    time.sleep(1)
                    max_wait -= 1
                
                # 如果进程还在运行，强制结束
                if psutil.pid_exists(old_pid):
                    p = psutil.Process(old_pid)
                    p.terminate()
                    p.wait()
            except Exception as e:
                print(f"更新模式错误: {str(e)}")

    def create_menu(self):
        """创建菜单栏"""
        menubar = tk.Menu(self)
        self.config(menu=menubar)
        
        # 文件菜单
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="文件", menu=file_menu)
        file_menu.add_command(label="导入", command=self.import_file)
        file_menu.add_command(label="导出Excel", command=self.export_excel)
        file_menu.add_separator()
        file_menu.add_command(label="退出", command=self.quit)
        
        # 帮助菜单
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="帮助", menu=help_menu)
        help_menu.add_command(label="检查更新", command=lambda: self.check_for_updates(silent=False))
        help_menu.add_command(label="更新历史", command=self.show_update_history)
        help_menu.add_command(label="更新设置", command=self.show_update_settings)
        help_menu.add_separator()
        help_menu.add_command(label="关于", command=self.show_about)
    
    def check_for_updates(self, silent=False):
        """检查更新"""
        update_info = self.version_checker.check_for_updates()
        
        if update_info["has_update"]:
            if silent:
                # 在后台自动下载
                self.download_update_background(update_info)
            else:
                # 手动检查时显示提示
                message = f"""发现新版本 {update_info['version']}
                
更新内容:
{update_info['release_notes']}

更新已在后台自动下载，将在下次启动时生效。"""
                self.show_centered_message(message, title="发现新版本")
    
    def download_update_background(self, update_info):
        """后台下载更新"""
        try:
            # 显示进度条
            self.update_label.configure(text="正在下载更新...")
            self.show_update_progress()
            self.update_progress['value'] = 0
            
            def update_progress(value):
                self.update_progress['value'] = value
                if value >= 100:
                    self.update_label.configure(text="更新已下载，下次启动生效")
                    # 3秒后隐藏进度条
                    self.after(3000, self.hide_update_progress)
                self.update()
            
            # 在后台线程中下载
            import threading
            def download_thread():
                try:
                    # 下载更新
                    new_version_path = self.version_checker.download_update(
                        update_info['download_url'],
                        update_info.get('checksum', ''),
                        callback=update_progress
                    )
                    
                    if new_version_path:
                        # 备份当前版本
                        if self.version_checker.backup_current_version():
                            # 记录更新历史
                            self.version_checker.add_update_history(
                                update_info['version'],
                                update_info['publish_date']
                            )
                            
                            # 创建标记文件，指示下次启动时更新
                            update_flag_file = Path(self.config_dir) / "update_ready"
                            update_flag_file.write_text(new_version_path)
                    else:
                        self.update_label.configure(text="更新下载失败")
                        self.after(3000, self.hide_update_progress)
                        
                except Exception as e:
                    print(f"后台下载更新失败: {str(e)}")
                    self.update_label.configure(text="更新下载失败")
                    self.after(3000, self.hide_update_progress)
            
            # 启动下载线程
            threading.Thread(target=download_thread, daemon=True).start()
            
        except Exception as e:
            print(f"启动后台下载失败: {str(e)}")
            self.hide_update_progress()
            
    def show_update_history(self):
        """显示更新历史"""
        history = self.version_checker.get_update_history()
        if not history:
            self.show_centered_message("暂无更新历史记录。", title="更新历史")
            return
            
        history_window = ttk.Toplevel(self)
        history_window.title("更新历史")
        history_window.geometry("400x300")
        self.center_window(history_window)
        
        # 创建表格
        columns = ("日期", "版本", "原版本")
        tree = ttk.Treeview(history_window, columns=columns, show="headings")
        
        # 设置列标题
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=100)
        
        # 添加数据
        for record in reversed(history):
            tree.insert("", "end", values=(
                datetime.fromisoformat(record["date"]).strftime("%Y-%m-%d %H:%M"),
                record["version"],
                record["previous_version"]
            ))
        
        # 添加滚动条
        scrollbar = ttk.Scrollbar(history_window, orient="vertical", command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        
        # 布局
        tree.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
    
    def show_update_settings(self):
        """显示更新设置"""
        config = self.version_checker.load_config()
        
        settings_window = ttk.Toplevel(self)
        settings_window.title("更新设置")
        settings_window.geometry("300x200")
        self.center_window(settings_window)
        
        # 自动检查更新
        auto_check_var = tk.BooleanVar(value=config["auto_check"])
        auto_check = ttk.Checkbutton(
            settings_window,
            text="自动检查更新",
            variable=auto_check_var
        )
        auto_check.pack(pady=10, padx=20, anchor="w")
        
        # 检查频率
        freq_frame = ttk.Frame(settings_window)
        freq_frame.pack(fill="x", padx=20, pady=5)
        ttk.Label(freq_frame, text="检查频率:").pack(side="left")
        freq_var = tk.StringVar(value=str(config["check_frequency"]))
        freq_entry = ttk.Entry(freq_frame, width=5, textvariable=freq_var)
        freq_entry.pack(side="left", padx=5)
        ttk.Label(freq_frame, text="天").pack(side="left")
        
        # 静默更新
        silent_update_var = tk.BooleanVar(value=config["silent_update"])
        silent_update = ttk.Checkbutton(
            settings_window,
            text="静默安装更新",
            variable=silent_update_var
        )
        silent_update.pack(pady=10, padx=20, anchor="w")
        
        def save_settings():
            try:
                freq = int(freq_var.get())
                if freq < 1:
                    raise ValueError("检查频率必须大于0")
                    
                config["auto_check"] = auto_check_var.get()
                config["check_frequency"] = freq
                config["silent_update"] = silent_update_var.get()
                
                self.version_checker.save_config(config)
                settings_window.destroy()
                
                self.show_centered_message("设置已保存。", title="更新设置")
                
            except ValueError as e:
                self.show_centered_message(
                    str(e),
                    title="输入错误",
                    message_type="error"
                )
        
        # 保存按钮
        ttk.Button(
            settings_window,
            text="保存",
            command=save_settings,
            style="primary.TButton"
        ).pack(pady=20)
    
    def show_about(self):
        """显示关于对话框"""
        message = f"""个人投资记账程序 v{self.version}

一个简单的个人投资记账工具，帮助您追踪投资收益。

© 2025 HX"""
        
        self.show_centered_message(
            message,
            title="关于",
            message_type="info"
        )

    def create_toolbar(self):
        """创建顶部工具栏"""
        toolbar = ttk.Frame(self)
        toolbar.pack(fill="x", padx=5, pady=2)
        
        # 左侧空间占位
        ttk.Label(toolbar).pack(side="left", expand=True)
        
        # 更新进度条框架
        self.update_frame = ttk.Frame(toolbar)
        self.update_frame.pack(side="right", padx=5)
        
        # 更新标签
        self.update_label = ttk.Label(self.update_frame, text="")
        self.update_label.pack(side="left", padx=5)
        
        # 更新进度条
        self.update_progress = ttk.Progressbar(
            self.update_frame, 
            length=100,
            mode='determinate',
            style='success.Horizontal.TProgressbar'
        )
        
        # 初始时隐藏进度条和标签
        self.hide_update_progress()

    def show_update_progress(self):
        """显示更新进度条"""
        self.update_label.pack(side="left", padx=5)
        self.update_progress.pack(side="left", padx=5)
        
    def hide_update_progress(self):
        """隐藏更新进度条"""
        self.update_label.pack_forget()
        self.update_progress.pack_forget()

if __name__ == "__main__":
    app = StockTracker()
    app.mainloop() 