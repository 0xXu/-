#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import datetime
import urllib.request
import urllib.error
from pathlib import Path

class CurrencyManager:
    """货币汇率管理类，负责获取和缓存汇率数据"""
    
    def __init__(self, base_currency="CNY"):
        """初始化货币管理器
        
        Args:
            base_currency: 基准货币，默认为人民币
        """
        self.base_currency = base_currency
        self.exchange_rates = {}
        self.last_update = None
        self.cache_file = os.path.join(os.getenv('APPDATA'), 'InvestLedger', 'exchange_rates.json')
        
        # 确保缓存目录存在
        Path(os.path.dirname(self.cache_file)).mkdir(parents=True, exist_ok=True)
        
        # 尝试加载缓存的汇率数据
        self._load_cached_rates()
    
    def _load_cached_rates(self):
        """从缓存文件加载汇率数据"""
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self.exchange_rates = data.get('rates', {})
                    self.last_update = data.get('timestamp')
                    self.base_currency = data.get('base', self.base_currency)
        except Exception as e:
            print(f"加载汇率缓存失败: {e}")
    
    def _save_to_cache(self):
        """将汇率数据保存到缓存文件"""
        try:
            data = {
                'base': self.base_currency,
                'rates': self.exchange_rates,
                'timestamp': self.last_update
            }
            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"保存汇率缓存失败: {e}")
    
    def update_rates(self, force=False):
        """更新汇率数据
        
        Args:
            force: 是否强制更新，即使缓存未过期
            
        Returns:
            bool: 更新是否成功
        """
        # 检查缓存是否过期（超过24小时）
        if not force and self.last_update:
            last_update_time = datetime.datetime.fromisoformat(self.last_update)
            if (datetime.datetime.now() - last_update_time).total_seconds() < 86400:
                return True  # 缓存未过期，不需要更新
        
        try:
            # 使用开放汇率API获取最新汇率
            # 注意：实际使用时需要注册获取API密钥
            # 这里使用免费API示例，实际应用中可能需要替换
            url = f"https://open.er-api.com/v6/latest/{self.base_currency}"
            
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode('utf-8'))
                
                if data.get('result') == 'success':
                    self.exchange_rates = data.get('rates', {})
                    self.last_update = datetime.datetime.now().isoformat()
                    self._save_to_cache()
                    return True
                return False
        except (urllib.error.URLError, json.JSONDecodeError) as e:
            print(f"更新汇率失败: {e}")
            return False
    
    def get_rate(self, currency_code):
        """获取指定货币相对于基准货币的汇率
        
        Args:
            currency_code: 货币代码，如USD、EUR等
            
        Returns:
            float: 汇率值，如果货币代码不存在则返回1.0
        """
        # 如果是基准货币，汇率为1
        if currency_code == self.base_currency:
            return 1.0
        
        # 尝试从缓存获取汇率
        rate = self.exchange_rates.get(currency_code)
        if rate is not None:
            return float(rate)
        
        # 如果缓存中没有该货币的汇率，尝试更新
        if self.update_rates():
            return float(self.exchange_rates.get(currency_code, 1.0))
        
        # 更新失败，返回默认值1.0
        return 1.0
    
    def convert(self, amount, from_currency, to_currency=None):
        """货币转换
        
        Args:
            amount: 金额
            from_currency: 源货币代码
            to_currency: 目标货币代码，默认为基准货币
            
        Returns:
            float: 转换后的金额
        """
        if to_currency is None:
            to_currency = self.base_currency
        
        # 如果源货币和目标货币相同，无需转换
        if from_currency == to_currency:
            return amount
        
        # 获取源货币和目标货币的汇率
        from_rate = self.get_rate(from_currency)
        to_rate = self.get_rate(to_currency)
        
        # 计算转换后的金额
        # 先转换为基准货币，再转换为目标货币
        return amount * (to_rate / from_rate)
    
    def get_available_currencies(self):
        """获取可用的货币列表
        
        Returns:
            list: 货币代码列表
        """
        # 确保基准货币在列表中
        currencies = list(self.exchange_rates.keys())
        if self.base_currency not in currencies:
            currencies.append(self.base_currency)
        return sorted(currencies)
    
    def set_base_currency(self, currency_code):
        """设置基准货币
        
        Args:
            currency_code: 新的基准货币代码
            
        Returns:
            bool: 设置是否成功
        """
        if currency_code == self.base_currency:
            return True  # 无需更改
        
        self.base_currency = currency_code
        # 强制更新汇率数据
        return self.update_rates(force=True)