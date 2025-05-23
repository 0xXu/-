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
import pandas as pd  # 添加pandas库支持Excel文件
import chardet        # 添加编码检测支持
from storage import Transaction

class ImportResult:
    """导入结果对象，包含成功和失败的记录"""
    
    def __init__(self):
        """初始化导入结果"""
        self.parsed_data = []  # 成功解析的数据
        self.error_data = []   # 解析失败的数据
        self.skipped_data = [] # 跳过的重复数据
    
    def add_success(self, data):
        """添加成功解析的数据"""
        self.parsed_data.append(data)
    
    def add_error(self, row_index, row_data, error_message):
        """添加解析失败的数据"""
        self.error_data.append({
            'row_index': row_index,
            'row_data': row_data,
            'error_message': error_message
        })
    
    def add_skipped(self, data, reason="重复记录"):
        """添加被跳过的数据"""
        self.skipped_data.append({
            'data': data,
            'reason': reason
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
                    # 转换字段名，并自动去除每个字段的前后空格
                    transaction_data = {}
                    for csv_field, model_field in mapping.items():
                        if csv_field in row:
                            # 自动去除前后空格
                            value = row[csv_field]
                            if isinstance(value, str):
                                value = value.strip()
                            transaction_data[model_field] = value
                    
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
    
    def import_text(self, text_content, format_type="auto"):
        """导入文本内容，支持多种格式
        
        Args:
            text_content: 文本内容
            format_type: 格式类型，可选值："auto"(自动检测), "custom"(自定义), "csv", "tsv"
            
        Returns:
            ImportResult: 导入结果
        """
        result = ImportResult()
        
        # 如果文本内容为空，直接返回
        if not text_content or not text_content.strip():
            result.add_error(0, {}, "文本内容为空")
            return result
        
        # 自动检测格式
        if format_type == "auto":
            # 检查是否包含制表符，如果是则认为是TSV
            if '\t' in text_content:
                format_type = "tsv"
            # 检查是否符合自定义文本格式 (更宽松的匹配)
            elif re.search(r'(.+)[：:]\s*(盈|亏)(\d+)元?', text_content):
                format_type = "custom"
            # 检查是否包含逗号，如果是则认为是CSV
            elif ',' in text_content:
                format_type = "csv"
            else:
                # 默认为自定义格式
                format_type = "custom"
        
        # 根据格式类型处理
        if format_type == "custom":
            # 处理自定义文本格式，如 "项目名称：盈/亏XXX元，日期"
            lines = text_content.strip().split("\n")
            
            for i, line in enumerate(lines, start=1):
                try:
                    # 跳过空行
                    if not line.strip():
                        continue
                        
                    # 现在_parse_custom_text_line返回交易对象和错误信息    
                    transaction, error_message = self._parse_custom_text_line(line.strip())
                    if transaction:
                        result.add_success(transaction)
                    else:
                        result.add_error(i, line, error_message or "无法解析行")
                except Exception as e:
                    result.add_error(i, line, str(e))
        
        elif format_type == "tsv":
            # 制表符分隔的数据
            return self.import_csv(text_content, delimiter='\t')
        
        elif format_type == "csv":
            # 逗号分隔的数据
            return self.import_csv(text_content, delimiter=',')
            
        return result
    
    def _parse_custom_text_line(self, line):
        """
        解析自定义文本行格式：项目名称：盈/亏XXX元，日期
        例如：若羽臣：盈310元， 2025年4月10日
        """
        try:
            # 首先尝试匹配标准格式 - 修改以支持元后多个空格再跟逗号的情况
            pattern = r'(.+)：(盈|亏)(\d+)元\s*[，,]\s*(\d{4})年(\d{1,2})月(\d{1,2})日'
            match = re.match(pattern, line)
            
            if not match:
                # 尝试匹配带冒号的更宽松格式 - 同样修改空格处理
                pattern2 = r'(.+)[:：]?\s*(盈|亏)(\d+)元\s*[，,]?\s*(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})[日]?'
                match = re.match(pattern2, line)
            
            if not match:
                # 再尝试匹配更宽松的格式，少一些约束
                pattern3 = r'(.+)[：:]\s*(盈|亏)(\d+)[元]?\s*[，,]?\s*(\d{4})\D+(\d{1,2})\D+(\d{1,2})\D*'
                match = re.match(pattern3, line)
            
            if not match:
                # 检查可能的格式问题
                if "：" not in line and ":" not in line:
                    return None, "格式错误: 缺少冒号分隔项目名称与盈亏信息"
                if "盈" not in line and "亏" not in line:
                    return None, "格式错误: 缺少盈亏标识(盈或亏)"
                if not re.search(r'\d+元', line):
                    return None, "格式错误: 缺少金额或金额格式不正确"
                if not re.search(r'\d{4}[-/年]\d{1,2}[-/月]\d{1,2}', line) and not re.search(r'\d{4}年\d{1,2}月\d{1,2}', line):
                    return None, "格式错误: 日期格式不正确，支持的格式有YYYY年MM月DD日或YYYY-MM-DD"
                
                # 提取有用的信息用于调试
                project_match = re.search(r'^(.+?)[：:]', line)
                project_name = project_match.group(1).strip() if project_match else "未找到项目名"
                
                profit_match = re.search(r'(盈|亏)(\d+)', line)
                profit_info = profit_match.group(0) if profit_match else "未找到盈亏信息"
                
                date_match = re.search(r'(\d{4})[\D]+(\d{1,2})[\D]+(\d{1,2})', line)
                date_info = f"{date_match.group(1)}年{date_match.group(2)}月{date_match.group(3)}日" if date_match else "未找到日期"
                
                return None, f"格式不符合规范，无法正确解析。解析结果: 项目={project_name}, 盈亏={profit_info}, 日期={date_info}"
            
            # 提取数据并自动去除前后空格
            project_name = match.group(1).strip()
            profit_type = match.group(2)  # "盈" 或 "亏"
            amount = int(match.group(3))
            year = int(match.group(4))
            month = int(match.group(5))
            day = int(match.group(6))
            
            # 验证日期有效性
            try:
                datetime.date(year, month, day)
            except ValueError:
                return None, f"日期无效: {year}年{month}月{day}日不是有效日期"
            
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
                notes=""  # 不再将原始文本作为备注
            ), None
            
        except Exception as e:
            print(f"解析行失败: {e}")
            return None, f"解析失败: {str(e)}"
    
    def _validate_transaction_data(self, data):
        """验证交易数据必填字段"""
        required_fields = ['project_name', 'date']
        for field in required_fields:
            if field not in data or not data[field]:
                return False
        return True
    
    def _convert_transaction_data_types(self, data):
        """转换数据类型"""
        # 对所有字符串类型字段自动去除空格
        for field in data:
            if isinstance(data[field], str):
                data[field] = data[field].strip()
        
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
        skipped_count = 0
        
        for transaction in import_result.parsed_data:
            # 检查是否存在相同的交易记录（项目名称、金额和日期相同）
            existing = self.check_duplicate_transaction(transaction)
            if existing:
                print(f"跳过重复的交易: {transaction.project_name}, {transaction.date}, {transaction.profit_loss}")
                import_result.add_skipped(transaction)
                skipped_count += 1
                continue
                
            if self.db_manager.add_transaction(transaction):
                success_count += 1
        
        if skipped_count > 0:
            print(f"成功导入{success_count}条记录，跳过{skipped_count}条重复记录")
        
        return success_count
    
    def check_duplicate_transaction(self, transaction):
        """检查是否存在重复的交易记录
        
        重复的定义：项目名称、日期和盈亏金额都相同
        
        Args:
            transaction: 要检查的交易记录
            
        Returns:
            bool: 是否存在重复记录
        """
        # 构造过滤条件：项目名称、日期和盈亏金额都相同
        filters = [
            ('project_name', '=', transaction.project_name),
            ('date', '=', transaction.date),
            ('profit_loss', '=', transaction.profit_loss)
        ]
        
        # 查询数据库
        existing_transactions = self.db_manager.get_transactions(filters)
        
        # 如果找到记录，返回True表示存在重复
        return len(existing_transactions) > 0
    
    def batch_process_clipboard_data(self, clipboard_text):
        """批量处理剪贴板数据"""
        result = self.import_text(clipboard_text)
        return result
    
    def import_excel(self, file_path, sheet_name=0, header_row=0, mapping=None):
        """
        导入Excel数据
        
        Args:
            file_path: Excel文件路径
            sheet_name: 工作表名称或索引，默认为第一个工作表
            header_row: 表头行号，默认为0（第一行）
            mapping: 字段映射，如 {'项目名称': 'project_name', '日期': 'date', ...}
            
        Returns:
            ImportResult: 导入结果
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
            # 使用pandas读取Excel文件
            df = pd.read_excel(file_path, sheet_name=sheet_name, header=header_row)
            
            # 处理每一行数据
            for i, row in df.iterrows():
                try:
                    # 转换字段名
                    transaction_data = {}
                    for excel_field, model_field in mapping.items():
                        if excel_field in row.index:
                            # 处理NaN值
                            value = row[excel_field]
                            if pd.isna(value):
                                value = None
                            transaction_data[model_field] = value
                    
                    # 验证必填字段
                    if self._validate_transaction_data(transaction_data):
                        # 类型转换
                        self._convert_transaction_data_types(transaction_data)
                        
                        # 创建交易对象
                        transaction = Transaction(**transaction_data)
                        result.add_success(transaction)
                    else:
                        result.add_error(i + header_row + 1, row.to_dict(), "缺少必填字段")
                        
                except Exception as e:
                    result.add_error(i + header_row + 1, row.to_dict(), str(e))
        
        except Exception as e:
            result.add_error(0, {}, f"Excel解析错误: {str(e)}")
        
        return result
    
    def detect_encoding(self, file_path):
        """
        检测文件编码
        
        Args:
            file_path: 文件路径
            
        Returns:
            str: 检测到的编码，默认为utf-8
        """
        try:
            with open(file_path, 'rb') as f:
                raw_data = f.read(4096)  # 读取部分文件内容用于检测
            result = chardet.detect(raw_data)
            if result['encoding'] and result['confidence'] > 0.7:
                return result['encoding']
            return 'utf-8'  # 默认返回UTF-8
        except Exception:
            return 'utf-8'
    
    def import_file(self, file_path, file_type=None, delimiter=',', header_row=0, mapping=None):
        """
        通用文件导入方法，根据文件类型调用对应的导入方法
        
        Args:
            file_path: 文件路径
            file_type: 文件类型，可选值：'csv', 'tsv', 'excel', 'txt'
            delimiter: 分隔符，用于CSV/TSV文件
            header_row: 表头行索引
            mapping: 字段映射
            
        Returns:
            ImportResult: 导入结果
        """
        # 如果未指定文件类型，则根据扩展名判断
        if not file_type:
            ext = os.path.splitext(file_path)[1].lower()
            if ext == '.csv':
                file_type = 'csv'
            elif ext == '.tsv':
                file_type = 'tsv'
            elif ext in ['.xlsx', '.xls']:
                file_type = 'excel'
            elif ext == '.txt':
                file_type = 'txt'
            else:
                file_type = 'csv'  # 默认为CSV
        
        # 根据文件类型调用对应的导入方法
        if file_type == 'excel':
            return self.import_excel(file_path, header_row=header_row, mapping=mapping)
        elif file_type in ['tsv', 'csv', 'txt']:
            # 检测文件编码
            encoding = self.detect_encoding(file_path)
            
            try:
                # 读取文件内容
                with open(file_path, 'r', encoding=encoding) as f:
                    file_content = f.read()
                
                if file_type == 'tsv':
                    return self.import_csv(file_content, delimiter='\t', mapping=mapping)
                elif file_type == 'csv':
                    return self.import_csv(file_content, delimiter=delimiter, mapping=mapping)
                else:  # txt
                    # 尝试自动检测格式
                    return self.import_text(file_content, format_type="auto")
            except UnicodeDecodeError:
                # 如果编码检测失败，尝试使用不同的编码
                for enc in ['utf-8', 'gb2312', 'gbk', 'gb18030', 'iso-8859-1']:
                    try:
                        with open(file_path, 'r', encoding=enc) as f:
                            file_content = f.read()
                        
                        if file_type == 'tsv':
                            return self.import_csv(file_content, delimiter='\t', mapping=mapping)
                        elif file_type == 'csv':
                            return self.import_csv(file_content, delimiter=delimiter, mapping=mapping)
                        else:  # txt
                            return self.import_text(file_content, format_type="auto")
                    except UnicodeDecodeError:
                        continue
                
                # 所有编码都失败了
                result = ImportResult()
                result.add_error(0, {}, "文件编码不支持，请尝试转换为UTF-8编码")
                return result
        else:
            result = ImportResult()
            result.add_error(0, {}, f"不支持的文件类型: {file_type}")
            return result
    
    def generate_preview(self, file_path, file_type=None, delimiter=',', lines=10):
        """
        生成文件预览
        
        Args:
            file_path: 文件路径
            file_type: 文件类型，可选值：'csv', 'tsv', 'excel', 'txt'
            delimiter: 分隔符，用于CSV/TSV文件
            lines: 预览行数
            
        Returns:
            dict: 包含预览数据和列信息的字典
        """
        preview_data = {
            'success': False,
            'headers': [],
            'rows': [],
            'error': None
        }
        
        try:
            # 如果未指定文件类型，则根据扩展名判断
            if not file_type:
                ext = os.path.splitext(file_path)[1].lower()
                if ext == '.csv':
                    file_type = 'csv'
                elif ext == '.tsv':
                    file_type = 'tsv'
                elif ext in ['.xlsx', '.xls']:
                    file_type = 'excel'
                elif ext == '.txt':
                    file_type = 'txt'
                else:
                    file_type = 'csv'  # 默认为CSV
            
            if file_type == 'excel':
                # 使用pandas读取Excel文件
                df = pd.read_excel(file_path, nrows=lines)
                preview_data['headers'] = df.columns.tolist()
                preview_data['rows'] = df.head(lines).values.tolist()
                preview_data['success'] = True
            
            elif file_type in ['csv', 'tsv', 'txt']:
                # 检测文件编码
                encoding = self.detect_encoding(file_path)
                
                try:
                    if file_type == 'csv':
                        with open(file_path, 'r', encoding=encoding) as f:
                            reader = csv.reader(f, delimiter=delimiter)
                            headers = next(reader, [])
                            preview_data['headers'] = headers
                            
                            rows = []
                            for i, row in enumerate(reader):
                                if i >= lines:
                                    break
                                rows.append(row)
                            
                            preview_data['rows'] = rows
                            preview_data['success'] = True
                    
                    elif file_type == 'tsv':
                        with open(file_path, 'r', encoding=encoding) as f:
                            reader = csv.reader(f, delimiter='\t')
                            headers = next(reader, [])
                            preview_data['headers'] = headers
                            
                            rows = []
                            for i, row in enumerate(reader):
                                if i >= lines:
                                    break
                                rows.append(row)
                            
                            preview_data['rows'] = rows
                            preview_data['success'] = True
                    
                    else:  # txt
                        with open(file_path, 'r', encoding=encoding) as f:
                            lines_data = []
                            for i, line in enumerate(f):
                                if i >= lines:
                                    break
                                lines_data.append(line.strip())
                            
                            preview_data['headers'] = ['内容']
                            preview_data['rows'] = [[line] for line in lines_data]
                            preview_data['success'] = True
                
                except UnicodeDecodeError:
                    # 如果编码检测失败，尝试使用不同的编码
                    for enc in ['utf-8', 'gb2312', 'gbk', 'gb18030', 'iso-8859-1']:
                        try:
                            if file_type in ['csv', 'tsv']:
                                with open(file_path, 'r', encoding=enc) as f:
                                    reader = csv.reader(f, delimiter=',' if file_type == 'csv' else '\t')
                                    headers = next(reader, [])
                                    preview_data['headers'] = headers
                                    
                                    rows = []
                                    for i, row in enumerate(reader):
                                        if i >= lines:
                                            break
                                        rows.append(row)
                                    
                                    preview_data['rows'] = rows
                                    preview_data['success'] = True
                                    break
                            else:  # txt
                                with open(file_path, 'r', encoding=enc) as f:
                                    lines_data = []
                                    for i, line in enumerate(f):
                                        if i >= lines:
                                            break
                                        lines_data.append(line.strip())
                                    
                                    preview_data['headers'] = ['内容']
                                    preview_data['rows'] = [[line] for line in lines_data]
                                    preview_data['success'] = True
                                    break
                        except UnicodeDecodeError:
                            continue
                    
                    if not preview_data['success']:
                        preview_data['error'] = "文件编码不支持，请尝试转换为UTF-8编码"
        
        except Exception as e:
            preview_data['error'] = f"生成预览失败: {str(e)}"
        
        return preview_data