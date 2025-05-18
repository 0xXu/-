#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import datetime
import calendar
from collections import defaultdict

class DataAnalyzer:
    """数据分析器，负责对交易数据进行统计和分析"""
    
    def __init__(self, db_manager):
        """初始化数据分析器"""
        self.db_manager = db_manager
        # 预算告警阈值（默认为80%，即达到预算目标的80%时触发告警）
        self.budget_alert_threshold = 0.8
    
    def get_profit_loss_summary(self, period="month", start_date=None, end_date=None):
        """
        获取指定时间段内的盈亏汇总
        period: 汇总周期，可以是"day", "week", "month", "year"
        """
        # 获取指定时间段内的所有交易
        if not start_date:
            # 默认为过去6个月
            end_date = datetime.date.today()
            start_date = (end_date - datetime.timedelta(days=180)).isoformat()
        
        if not end_date:
            end_date = datetime.date.today().isoformat()
        
        transactions = self.db_manager.get_transactions_by_date_range(start_date, end_date)
        
        # 按周期分组
        groups = defaultdict(list)
        for trans in transactions:
            date_obj = datetime.date.fromisoformat(trans.date)
            
            if period == "day":
                key = trans.date
            elif period == "week":
                # 使用年份和周数作为键
                year, week, _ = date_obj.isocalendar()
                key = f"{year}-W{week:02d}"
            elif period == "month":
                key = f"{date_obj.year}-{date_obj.month:02d}"
            elif period == "year":
                key = str(date_obj.year)
            else:
                key = trans.date
            
            groups[key].append(trans)
        
        # 计算每个分组的盈亏总额
        summary = []
        for key, group_transactions in sorted(groups.items()):
            total_profit_loss = sum(t.profit_loss for t in group_transactions)
            count = len(group_transactions)
            
            # 生成标签
            if period == "day":
                label = key
            elif period == "week":
                # 解析出年份和周数
                year_str, week_str = key.split('-W')
                year = int(year_str)
                week = int(week_str)
                # 使用周数表示
                label = f"第{week}周"
            elif period == "month":
                # 解析出年份和月份
                year_str, month_str = key.split('-')
                year = int(year_str)
                month = int(month_str)
                # 使用月份名称
                month_name = calendar.month_name[month]
                label = f"{month_name}"
            elif period == "year":
                label = key
            
            summary.append({
                'key': key,
                'label': label,
                'profit_loss': total_profit_loss,
                'transaction_count': count
            })
        
        return summary
    
    def get_asset_type_distribution(self, start_date=None, end_date=None):
        """获取资产类别分布"""
        # 如果未指定日期范围，则使用全部数据
        transactions = self.db_manager.get_transactions_by_date_range(
            start_date or "1970-01-01",
            end_date or datetime.date.today().isoformat()
        )
        
        # 按资产类别分组
        groups = defaultdict(list)
        for trans in transactions:
            groups[trans.asset_type].append(trans)
        
        # 计算每种资产类别的盈亏总额
        distribution = []
        for asset_type, group_transactions in groups.items():
            total_profit_loss = sum(t.profit_loss for t in group_transactions)
            count = len(group_transactions)
            
            distribution.append({
                'asset_type': asset_type,
                'profit_loss': total_profit_loss,
                'transaction_count': count
            })
        
        # 按盈亏金额排序
        distribution.sort(key=lambda x: abs(x['profit_loss']), reverse=True)
        
        return distribution
    
    def get_monthly_goal_comparison(self, year=None, month=None):
        """
        获取月度目标与实际盈亏比较
        如果未指定年月，则使用当前月份
        """
        if not year or not month:
            today = datetime.date.today()
            year = today.year
            month = today.month
        
        # 获取本月第一天和最后一天
        first_day = datetime.date(year, month, 1).isoformat()
        last_day = datetime.date(year, month, calendar.monthrange(year, month)[1]).isoformat()
        
        # 获取本月实际盈亏
        actual_profit_loss = self.db_manager.get_total_profit_loss(first_day, last_day)
        
        # 获取本月目标
        goal_amount = self.db_manager.get_budget_goal(year, month)
        
        # 计算完成百分比
        completion_percentage = (actual_profit_loss / goal_amount * 100) if goal_amount != 0 else 0
        
        return {
            'year': year,
            'month': month,
            'goal_amount': goal_amount,
            'actual_amount': actual_profit_loss,
            'completion_percentage': completion_percentage
        }
    
    def get_yearly_goal_comparison(self, year=None):
        """
        获取年度目标与实际盈亏比较
        如果未指定年份，则使用当前年份
        """
        if not year:
            year = datetime.date.today().year
        
        # 获取本年第一天和最后一天
        first_day = datetime.date(year, 1, 1).isoformat()
        last_day = datetime.date(year, 12, 31).isoformat()
        
        # 获取本年实际盈亏
        actual_profit_loss = self.db_manager.get_total_profit_loss(first_day, last_day)
        
        # 计算年度目标（所有月度目标之和）
        yearly_goal = 0
        for month in range(1, 13):
            monthly_goal = self.db_manager.get_budget_goal(year, month)
            yearly_goal += monthly_goal
        
        # 计算完成百分比
        completion_percentage = (actual_profit_loss / yearly_goal * 100) if yearly_goal != 0 else 0
        
        return {
            'year': year,
            'goal_amount': yearly_goal,
            'actual_amount': actual_profit_loss,
            'completion_percentage': completion_percentage
        }
    
    def check_budget_alerts(self):
        """
        检查预算告警情况
        返回需要显示告警的预算目标列表
        """
        alerts = []
        today = datetime.date.today()
        current_year = today.year
        current_month = today.month
        
        # 检查当月预算
        monthly_comparison = self.get_monthly_goal_comparison(current_year, current_month)
        if monthly_comparison['goal_amount'] > 0:
            # 计算实际盈亏与目标的比率
            ratio = abs(monthly_comparison['actual_amount']) / monthly_comparison['goal_amount']
            
            # 如果实际盈亏接近或超过目标，添加到告警列表
            if ratio >= self.budget_alert_threshold:
                alerts.append({
                    'type': 'monthly',
                    'year': current_year,
                    'month': current_month,
                    'goal_amount': monthly_comparison['goal_amount'],
                    'actual_amount': monthly_comparison['actual_amount'],
                    'ratio': ratio,
                    'message': f"当月盈亏已达到目标的{ratio*100:.1f}%"
                })
        
        # 检查年度预算
        yearly_comparison = self.get_yearly_goal_comparison(current_year)
        if yearly_comparison['goal_amount'] > 0:
            # 计算实际盈亏与目标的比率
            ratio = abs(yearly_comparison['actual_amount']) / yearly_comparison['goal_amount']
            
            # 如果实际盈亏接近或超过目标，添加到告警列表
            if ratio >= self.budget_alert_threshold:
                alerts.append({
                    'type': 'yearly',
                    'year': current_year,
                    'goal_amount': yearly_comparison['goal_amount'],
                    'actual_amount': yearly_comparison['actual_amount'],
                    'ratio': ratio,
                    'message': f"{current_year}年度盈亏已达到目标的{ratio*100:.1f}%"
                })
        
        return alerts
    
    def set_budget_alert_threshold(self, threshold):
        """
        设置预算告警阈值
        threshold: 0.0-1.0之间的浮点数，表示达到预算目标的多少比例时触发告警
        """
        if 0.0 <= threshold <= 1.0:
            self.budget_alert_threshold = threshold
            return True
        return False
    
    def get_top_projects(self, limit=5, is_profit=True, start_date=None, end_date=None):
        """
        获取盈利/亏损最多的项目
        limit: 返回数量
        is_profit: True获取盈利最多的项目，False获取亏损最多的项目
        """
        transactions = self.db_manager.get_transactions_by_date_range(
            start_date or "1970-01-01",
            end_date or datetime.date.today().isoformat()
        )
        
        # 按项目名称分组
        projects = defaultdict(lambda: {'total_profit_loss': 0, 'transactions': []})
        for trans in transactions:
            projects[trans.project_name]['total_profit_loss'] += trans.profit_loss
            projects[trans.project_name]['transactions'].append(trans)
        
        # 转换为列表并排序
        project_list = [
            {
                'project_name': name,
                'total_profit_loss': data['total_profit_loss'],
                'transaction_count': len(data['transactions'])
            }
            for name, data in projects.items()
        ]
        
        # 根据是否查询盈利项目进行排序
        if is_profit:
            # 盈利最多的项目：按盈亏金额降序排列，且只包含盈利项目
            project_list = [p for p in project_list if p['total_profit_loss'] > 0]
            project_list.sort(key=lambda x: x['total_profit_loss'], reverse=True)
        else:
            # 亏损最多的项目：按盈亏金额升序排列，且只包含亏损项目
            project_list = [p for p in project_list if p['total_profit_loss'] < 0]
            project_list.sort(key=lambda x: x['total_profit_loss'])
        
        # 返回前N个项目
        return project_list[:limit]
    
    def get_profit_loss_trend(self, period="month", count=6):
        """
        获取盈亏趋势数据，用于生成趋势图
        period: "day", "week", "month", "year"
        count: 返回的数据点数量
        """
        today = datetime.date.today()
        
        # 计算开始日期
        if period == "day":
            start_date = (today - datetime.timedelta(days=count-1)).isoformat()
        elif period == "week":
            start_date = (today - datetime.timedelta(weeks=count-1)).isoformat()
        elif period == "month":
            # 减去count-1个月
            month = today.month - (count - 1)
            year = today.year
            while month <= 0:
                month += 12
                year -= 1
            start_date = datetime.date(year, month, 1).isoformat()
        elif period == "year":
            start_date = datetime.date(today.year - (count - 1), 1, 1).isoformat()
        else:
            start_date = (today - datetime.timedelta(days=30*count)).isoformat()
        
        # 获取趋势数据
        trend_data = self.get_profit_loss_summary(period, start_date, today.isoformat())
        
        # 确保返回的数据点数量正确
        if len(trend_data) > count:
            trend_data = trend_data[-count:]
        
        return trend_data