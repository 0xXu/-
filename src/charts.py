import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
from typing import Dict, Any, List
from datetime import datetime

class ChartGenerator:
    @staticmethod
    def create_profit_trend(data: List[Dict[str, Any]]):
        """创建收益趋势图"""
        if not data:
            fig = go.Figure()
            fig.add_annotation(
                text="暂无数据",
                xref="paper",
                yref="paper",
                x=0.5,
                y=0.5,
                showarrow=False,
                font=dict(size=20)
            )
            return fig
            
        # 准备数据
        df = pd.DataFrame(data)
        if 'month' in df.columns:
            df['month'] = pd.to_datetime(df['month'] + '-01')  # 添加日期以转换为datetime
        
        # 创建图表
        fig = go.Figure()
        
        # 添加折线图
        fig.add_trace(go.Scatter(
            x=df['month'],
            y=df['net_profit'],
            mode='lines+markers',
            name='净收益',
            line=dict(color='#1f77b4', width=2),
            marker=dict(size=8)
        ))
        
        # 添加数据标签
        for i, row in df.iterrows():
            fig.add_annotation(
                x=row['month'],
                y=row['net_profit'],
                text=f"{row['net_profit']:,.0f}元",
                yshift=10,
                showarrow=False
            )
        
        # 更新布局
        fig.update_layout(
            title="月度收益趋势",
            xaxis_title="月份",
            yaxis_title="净收益（元）",
            showlegend=False,
            hovermode='x unified',
            plot_bgcolor='white',
            paper_bgcolor='white',
            xaxis=dict(
                showgrid=True,
                gridcolor='lightgray',
                tickformat='%Y年%m月'
            ),
            yaxis=dict(
                showgrid=True,
                gridcolor='lightgray',
                tickformat=',d'
            ),
            margin=dict(t=50, l=50, r=50, b=50)
        )
        
        return fig
        
    @staticmethod
    def create_stock_distribution(data: List[Dict[str, Any]]):
        """创建股票分布图"""
        if not data:
            fig = go.Figure()
            fig.add_annotation(
                text="暂无数据",
                xref="paper",
                yref="paper",
                x=0.5,
                y=0.5,
                showarrow=False,
                font=dict(size=20)
            )
            return fig
            
        # 准备数据
        df = pd.DataFrame(data)
        df = df.sort_values('net_profit', ascending=True)
        
        # 创建图表
        fig = go.Figure()
        
        # 添加条形图
        colors = ['#ff7f7f' if x < 0 else '#7fbf7f' for x in df['net_profit']]
        fig.add_trace(go.Bar(
            x=df['net_profit'],
            y=df['stock_name'],
            orientation='h',
            marker_color=colors,
            text=[f"{x:,.0f}元" for x in df['net_profit']],
            textposition='outside'
        ))
        
        # 更新布局
        fig.update_layout(
            title="股票收益分布",
            xaxis_title="净收益（元）",
            yaxis_title="股票名称",
            showlegend=False,
            plot_bgcolor='white',
            paper_bgcolor='white',
            xaxis=dict(
                showgrid=True,
                gridcolor='lightgray',
                tickformat=',d'
            ),
            yaxis=dict(
                showgrid=False,
                autorange="reversed"
            ),
            margin=dict(t=50, l=150, r=50, b=50)
        )
        
        return fig
        
    @staticmethod
    def create_monthly_stats(data: List[Dict[str, Any]]):
        """创建月度统计图"""
        if not data:
            fig = go.Figure()
            fig.add_annotation(
                text="暂无数据",
                xref="paper",
                yref="paper",
                x=0.5,
                y=0.5,
                showarrow=False,
                font=dict(size=20)
            )
            return fig
            
        # 准备数据
        df = pd.DataFrame(data)
        if 'month' in df.columns:
            df['month'] = pd.to_datetime(df['month'] + '-01')
        
        # 创建带有双y轴的子图
        fig = make_subplots(specs=[[{"secondary_y": True}]])
        
        # 添加柱状图（净收益）
        fig.add_trace(
            go.Bar(
                x=df['month'],
                y=df['net_profit'],
                name='净收益',
                marker_color='rgba(30, 144, 255, 0.6)',
                text=[f"{x:,.0f}元" for x in df['net_profit']],
                textposition='outside'
            ),
            secondary_y=False
        )
        
        # 添加折线图（交易次数）
        fig.add_trace(
            go.Scatter(
                x=df['month'],
                y=df['trade_count'],
                name='交易次数',
                mode='lines+markers+text',
                line=dict(color='red', width=2),
                marker=dict(size=8),
                text=[f"{x}笔" for x in df['trade_count']],
                textposition='top center'
            ),
            secondary_y=True
        )
        
        # 更新布局
        fig.update_layout(
            title="月度交易统计",
            showlegend=True,
            plot_bgcolor='white',
            paper_bgcolor='white',
            xaxis=dict(
                title="月份",
                showgrid=True,
                gridcolor='lightgray',
                tickformat='%Y年%m月'
            ),
            legend=dict(
                orientation="h",
                yanchor="bottom",
                y=1.02,
                xanchor="right",
                x=1
            ),
            margin=dict(t=80, l=50, r=50, b=50)
        )
        
        # 更新y轴
        fig.update_yaxes(
            title_text="净收益（元）",
            showgrid=True,
            gridcolor='lightgray',
            tickformat=',d',
            secondary_y=False
        )
        fig.update_yaxes(
            title_text="交易次数（笔）",
            showgrid=False,
            secondary_y=True
        )
        
        return fig 