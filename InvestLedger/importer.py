#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import csv
import datetime
from pathlib import Path

import csv
import io
import re
import datetime
from storage import Transaction

class ImportResult:
    """导入结果类，用于保存导入状态和错误信息"""
    
    def __init__(self):
        self.success_count = 0
        self.error_count = 0
        self.error_rows = []  # 存储错误行及原因
        self.parsed_data = []  # 存储成功解析的数据
    
    def add_success(self, data):
        """添加成功解析的数据"""
        self.success_count += 1
        self.parsed_data.append(data)
    
    def add_error(self, row_index, row_data, error_message):
        """添加解析失败的行"""
        self.error_count += 1
        self.error_rows.append({
            'row_index': row_index,
            'row_data': row_data,
            'error_message': error_message
        })

class DataImporter:
    """数据导入器，负责解析和导入各种格式的数据"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
        self.templates_dir = os.path.join(os.getenv('APPDATA'), 'InvestLedger', 'import_templates')
        
        # 确保模板目录存在
        Path(self.templates_dir).mkdir(parents=True, exist_ok=True)
    
    def import_csv(self, file_content, delimiter=',', mapping=None):
        """
        导入CSV数据
        mapping: 字段映射，如 {'项目名称': 'project_name', '日期': 'date', ...}
        """
        result = ImportResult()
        
        # 如果没有提供字段映射，使用默认映射
        if not mapping:
            mapping = {
                '日期': 'date',
                '资产类别': 'asset_type',
                '项目名称': 'project_name',
                '数量': 'amount',
                '单价': 'unit_price',
                '币种': 'currency',
                '盈亏': 'profit_loss',
                '备注': 'notes'
            }
        
        try:
            # 使用io.StringIO处理文件内容
            f = io.StringIO(file_content)
            reader = csv.DictReader(f, delimiter=delimiter)
            
            for i, row in enumerate(reader, start=1):
                try:
                    # 转换字段名
                    transaction_data = {}
                    for csv_field, model_field in mapping.items():
                        if csv_field in row:
                            transaction_data[model_field] = row[csv_field]
                    
                    # 验证必填字段
                    if self._validate_transaction_data(transaction_data):
                        # 类型转换
                        self._convert_transaction_data_types(transaction_data)
                        
                        # 创建交易对象
                        transaction = Transaction(**transaction_data)
                        result.add_success(transaction)
                    else:
                        result.add_error(i, row, "缺少必填字段")
                        
                except Exception as e:
                    result.add_error(i, row, str(e))
        
        except Exception as e:
            result.add_error(0, {}, f"CSV解析错误: {str(e)}")
        
        return result
    
    def import_text(self, text_content, format_type="custom"):
        """导入文本内容，支持多种格式"""
        result = ImportResult()
        
        if format_type == "custom":
            # 处理自定义文本格式，如 "项目名称：盈/亏XXX元，日期"
            lines = text_content.strip().split("\n")
            
            for i, line in enumerate(lines, start=1):
                try:
                    transaction = self._parse_custom_text_line(line.strip())
                    if transaction:
                        result.add_success(transaction)
                    else:
                        result.add_error(i, line, "无法解析行")
                except Exception as e:
                    result.add_error(i, line, str(e))
        
        elif format_type == "tsv":
            # 制表符分隔的数据
            return self.import_csv(text_content, delimiter='\t')
        
        return result
    
    def _parse_custom_text_line(self, line):
        """
        解析自定义文本行格式：项目名称：盈/亏XXX元，日期
        例如：若羽臣：盈310元， 2025年4月10日
        """
        try:
            # 使用正则表达式匹配模式
            pattern = r'(.+)：(盈|亏)(\d+)元[，,]\s*(\d{4})年(\d{1,2})月(\d{1,2})日'
            match = re.match(pattern, line)
            
            if not match:
                return None
            
            project_name = match.group(1).strip()
            profit_type = match.group(2)  # "盈" 或 "亏"
            amount = int(match.group(3))
            year = int(match.group(4))
            month = int(match.group(5))
            day = int(match.group(6))
            
            # 构建日期字符串 YYYY-MM-DD
            date_str = f"{year:04d}-{month:02d}-{day:02d}"
            
            # 根据盈亏类型确定金额正负
            profit_loss = amount if profit_type == "盈" else -amount
            
            # 创建交易记录
            return Transaction(
                date=date_str,
                asset_type="股票",  # 默认为股票类型
                project_name=project_name,
                amount=1,  # 默认为1
                unit_price=profit_loss,  # 用盈亏金额作为单价
                currency="CNY",  # 默认为人民币
                profit_loss=profit_loss,
                notes=line  # 原始文本作为备注
            )
            
        except Exception as e:
            print(f"解析行失败: {e}")
            return None
    
    def _validate_transaction_data(self, data):
        """验证交易数据必填字段"""
        required_fields = ['project_name', 'date']
        for field in required_fields:
            if field not in data or not data[field]:
                return False
        return True
    
    def _convert_transaction_data_types(self, data):
        """转换数据类型"""
        # 数值类型转换
        for field in ['amount', 'unit_price', 'profit_loss']:
            if field in data and data[field]:
                try:
                    data[field] = float(data[field])
                except (ValueError, TypeError):
                    data[field] = 0
        
        # 日期格式化
        if 'date' in data and data['date']:
            try:
                # 尝试解析各种日期格式
                date_formats = [
                    '%Y-%m-%d',  # 2023-01-01
                    '%Y/%m/%d',  # 2023/01/01
                    '%Y年%m月%d日',  # 2023年01月01日
                    '%Y.%m.%d'   # 2023.01.01
                ]
                
                for fmt in date_formats:
                    try:
                        date_obj = datetime.datetime.strptime(data['date'], fmt).date()
                        data['date'] = date_obj.isoformat()
                        break
                    except ValueError:
                        continue
                
            except Exception:
                # 保持原始值
                pass
    
    # 导入模板管理方法
    
    def save_import_template(self, template_name, template_data):
        """保存导入模板
        
        Args:
            template_name: 模板名称
            template_data: 模板数据，包含字段映射、分隔符等信息
            
        Returns:
            bool: 保存是否成功
        """
        try:
            # 确保模板名称有效
            template_name = template_name.strip()
            if not template_name:
                return False
            
            # 添加.json扩展名
            if not template_name.endswith('.json'):
                template_name += '.json'
            
            # 保存模板文件
            template_path = os.path.join(self.templates_dir, template_name)
            with open(template_path, 'w', encoding='utf-8') as f:
                json.dump(template_data, f, ensure_ascii=False, indent=2)
            
            return True
        except Exception as e:
            print(f"保存导入模板失败: {e}")
            return False
    
    def load_import_template(self, template_name):
        """加载导入模板
        
        Args:
            template_name: 模板名称
            
        Returns:
            dict: 模板数据，如果加载失败则返回None
        """
        try:
            # 添加.json扩展名
            if not template_name.endswith('.json'):
                template_name += '.json'
            
            # 加载模板文件
            template_path = os.path.join(self.templates_dir, template_name)
            if not os.path.exists(template_path):
                return None
            
            with open(template_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"加载导入模板失败: {e}")
            return None
    
    def get_available_templates(self):
        """获取可用的导入模板列表
        
        Returns:
            list: 模板名称列表
        """
        try:
            # 获取模板目录中的所有JSON文件
            templates = [f for f in os.listdir(self.templates_dir) if f.endswith('.json')]
            # 去掉扩展名
            return [os.path.splitext(t)[0] for t in templates]
        except Exception as e:
            print(f"获取导入模板列表失败: {e}")
            return []
    
    def delete_import_template(self, template_name):
        """删除导入模板
        
        Args:
            template_name: 模板名称
            
        Returns:
            bool: 删除是否成功
        """
        try:
            # 添加.json扩展名
            if not template_name.endswith('.json'):
                template_name += '.json'
            
            # 删除模板文件
            template_path = os.path.join(self.templates_dir, template_name)
            if os.path.exists(template_path):
                os.remove(template_path)
                return True
            return False
        except Exception as e:
            print(f"删除导入模板失败: {e}")
            return False
    
    def save_imported_data(self, import_result):
        """将导入结果保存到数据库"""
        success_count = 0
        
        for transaction in import_result.parsed_data:
            if self.db_manager.add_transaction(transaction):
                success_count += 1
        
        return success_count
    
    def batch_process_clipboard_data(self, clipboard_text):
        """批量处理剪贴板数据"""
        result = self.import_text(clipboard_text)
        return result