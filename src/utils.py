import re
from datetime import datetime
from typing import Tuple, Optional, Dict, Any
import pandas as pd

class DataValidator:
    """数据验证和格式化工具类"""
    
    @staticmethod
    def validate_stock_name(name: str) -> Tuple[bool, str]:
        """验证股票名称"""
        if not name or not name.strip():
            return False, "股票名称不能为空"
        if len(name) > 50:
            return False, "股票名称过长"
        return True, name.strip()
    
    @staticmethod
    def validate_amount(amount: str) -> Tuple[bool, float, str]:
        """验证金额
        支持格式：
        1. 668元
        2. 亏668元
        3. 亏了668元
        4. 盈利668元
        5. 668
        """
        try:
            # 移除所有空格
            amount = amount.strip()
            
            # 判断盈亏
            is_profit = None
            if '盈' in amount or '赚' in amount:
                is_profit = True
                # 移除"盈"、"盈利"、"赚"等字样
                amount = re.sub(r'盈利|盈|赚', '', amount)
            elif '亏' in amount or '损' in amount:
                is_profit = False
                # 移除"亏"、"亏损"、"亏了"等字样
                amount = re.sub(r'亏损|亏了|亏', '', amount)
            
            # 提取数字
            number_match = re.search(r'\d+\.?\d*', amount)
            if not number_match:
                return False, 0, "无法识别金额数字"
            
            value = float(number_match.group())
            if value <= 0:
                return False, 0, "金额必须大于0"
                
            if is_profit is not None:
                return True, value, is_profit
            return True, value, ""
            
        except ValueError:
            return False, 0, "无效的金额格式"
    
    @staticmethod
    def validate_date(date_str: str) -> Tuple[bool, datetime, str]:
        """验证日期格式"""
        try:
            # 预处理：清理字符串
            date_str = date_str.strip()  # 移除首尾空格
            date_str = re.sub(r'\s+', '', date_str)  # 移除中间的空格
            
            # 修正常见的错误字符
            date_str = date_str.replace('曰', '日')  # 修正"曰"为"日"
            date_str = date_str.replace('牟', '年')  # 修正"牟"为"年"
            
            # 处理错误的日期格式（如"2025年3日7号"）
            date_str = re.sub(r'年(\d{1,2})日(\d{1,2})', r'年\1月\2', date_str)
            
            # 处理"YYYY年MM月DD日"和"YYYY年MM月DD号"格式
            match = re.match(r'(\d{4})年(\d{1,2})月(\d{1,2})[日号]', date_str)
            if match:
                year, month, day = map(int, match.groups())
                # 验证日期是否有效
                if month < 1 or month > 12:
                    return False, datetime.now(), f"月份 {month} 无效，应在1-12之间"
                if day < 1 or day > 31:
                    return False, datetime.now(), f"日期 {day} 无效，应在1-31之间"
                try:
                    date = datetime(year, month, day)
                    return True, date, ""
                except ValueError:
                    return False, datetime.now(), f"无效的日期：{year}年{month}月{day}日"
            
            # 尝试其他常见格式
            for fmt in ['%Y-%m-%d', '%Y/%m/%d', '%Y.%m.%d']:
                try:
                    date = datetime.strptime(date_str, fmt)
                    return True, date, ""
                except ValueError:
                    continue
            
            return False, datetime.now(), "无效的日期格式，请使用'YYYY年MM月DD日'或'YYYY年MM月DD号'格式"
        except Exception as e:
            return False, datetime.now(), f"日期解析错误：{str(e)}"
    
    @staticmethod
    def parse_transaction_line(line: str) -> Tuple[bool, Dict[str, Any], str]:
        """解析单行交易记录"""
        try:
            # 移除空白字符
            line = line.strip()
            if not line:
                return False, {}, "空行"
            
            # 解析基本格式：股票名称：盈/亏金额，日期，[备注]
            parts = line.split('：', 1)
            if len(parts) != 2:
                return False, {}, "格式错误，应为'股票名称：盈/亏金额，日期'"
            
            stock_name = parts[0].strip()
            valid, stock_name = DataValidator.validate_stock_name(stock_name)
            if not valid:
                return False, {}, f"股票名称错误：{stock_name}"
            
            # 解析剩余部分
            remaining = parts[1].split('，')
            if len(remaining) < 2:
                return False, {}, "格式错误，缺少金额或日期"
            
            # 解析盈亏和金额
            amount_part = remaining[0]
            is_profit = '盈' in amount_part
            if not ('盈' in amount_part or '亏' in amount_part):
                return False, {}, "必须指定'盈'或'亏'"
            
            valid, amount, error = DataValidator.validate_amount(amount_part)
            if not valid:
                return False, {}, f"金额错误：{error}"
            
            # 解析日期
            valid, date, error = DataValidator.validate_date(remaining[1])
            if not valid:
                return False, {}, f"日期错误：{error}"
            
            # 解析备注（如果有）
            note = remaining[2].strip() if len(remaining) > 2 else ""
            
            # 构建结果
            result = {
                'stock_name': stock_name,
                'amount': amount,
                'is_profit': is_profit,
                'trade_date': date,
                'note': note
            }
            
            return True, result, ""
            
        except Exception as e:
            return False, {}, f"解析错误：{str(e)}"
    
    @staticmethod
    def format_amount(amount: float, is_profit: bool) -> str:
        """格式化金额显示"""
        return f"{'盈' if is_profit else '亏'}{amount:.2f}元"
    
    @staticmethod
    def format_date(date: datetime) -> str:
        """格式化日期显示"""
        return f"{date.year}年{date.month}月{date.day}日"
    
    @staticmethod
    def format_for_display(record: Dict[str, Any]) -> Dict[str, str]:
        """格式化记录用于显示"""
        return {
            '日期': DataValidator.format_date(record['trade_date']),
            '股票名称': record['stock_name'],
            '盈亏': '盈' if record['is_profit'] else '亏',
            '金额': f"{record['amount']:.2f}元",
            '备注': record['note']
        }
    
    @staticmethod
    def format_for_export(records: list) -> pd.DataFrame:
        """格式化记录用于导出"""
        formatted_records = []
        for record in records:
            formatted_record = DataValidator.format_for_display(record)
            formatted_records.append(formatted_record)
        return pd.DataFrame(formatted_records) 