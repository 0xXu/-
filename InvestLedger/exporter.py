#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import csv
import datetime
import logging
from pathlib import Path
import io

try:
    import xlsxwriter
    has_excel = True
except ImportError:
    has_excel = False
    logging.warning("xlsxwriter库未安装，Excel导出功能不可用")

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    has_pdf = True
except ImportError:
    has_pdf = False
    logging.warning("reportlab库未安装，PDF导出功能不可用")

class ExportFormat:
    """导出格式枚举"""
    CSV = "csv"
    EXCEL = "excel"
    PDF = "pdf"

class ExportResult:
    """导出结果类"""
    
    def __init__(self, success, file_path=None, message=None, data=None):
        self.success = success
        self.file_path = file_path  # 导出的文件路径（如果保存到文件）
        self.message = message  # 错误信息或成功消息
        self.data = data  # 导出的数据（用于预览或内存中操作）


class DataExporter:
    """数据导出类，支持多种格式导出"""
    
    def __init__(self, db_manager):
        """
        初始化导出器
        
        Parameters:
        - db_manager: 数据库管理器实例
        """
        self.db_manager = db_manager
    
    def export_transactions(self, export_format, file_path=None, filters=None, include_header=True, summary=True):
        """
        导出交易数据
        
        Parameters:
        - export_format: 导出格式（ExportFormat枚举）
        - file_path: 导出文件路径，None表示返回数据而不保存文件
        - filters: 过滤条件列表，格式为[(字段, 操作符, 值), ...]
        - include_header: 是否包含表头
        - summary: 是否包含汇总信息
        
        Returns:
        - ExportResult对象
        """
        try:
            # 获取数据
            transactions = self.db_manager.get_transactions(filters=filters)
            
            if not transactions:
                return ExportResult(False, message="没有符合条件的交易数据")
            
            # 根据格式导出
            if export_format == ExportFormat.CSV:
                return self._export_as_csv(transactions, file_path, include_header, summary)
            elif export_format == ExportFormat.EXCEL:
                if not has_excel:
                    return ExportResult(False, message="Excel导出不可用，请安装xlsxwriter库")
                return self._export_as_excel(transactions, file_path, include_header, summary)
            elif export_format == ExportFormat.PDF:
                if not has_pdf:
                    return ExportResult(False, message="PDF导出不可用，请安装reportlab库")
                return self._export_as_pdf(transactions, file_path, include_header, summary)
            else:
                return ExportResult(False, message=f"不支持的导出格式: {export_format}")
                
        except Exception as e:
            logging.error(f"导出数据失败: {e}")
            return ExportResult(False, message=f"导出数据失败: {e}")
    
    def _export_as_csv(self, transactions, file_path, include_header, summary):
        """导出为CSV格式"""
        try:
            # 定义表头
            headers = ["交易ID", "日期", "资产类型", "项目名称", "数量", "单价", "货币", "盈亏", "备注"]
            
            # 准备数据行
            rows = []
            if include_header:
                rows.append(headers)
            
            # 添加交易数据
            for trans in transactions:
                rows.append([
                    trans.id,
                    trans.date,
                    trans.asset_type,
                    trans.project_name,
                    trans.amount,
                    trans.unit_price,
                    trans.currency,
                    trans.profit_loss,
                    trans.notes
                ])
            
            # 添加汇总信息
            if summary and transactions:
                total_profit = sum(t.profit_loss for t in transactions if t.profit_loss > 0)
                total_loss = sum(t.profit_loss for t in transactions if t.profit_loss < 0)
                net_profit_loss = total_profit + total_loss
                
                rows.append([])  # 空行
                rows.append(["汇总信息", "", "", "", "", "", "", "", ""])
                rows.append(["总交易数量", len(transactions), "", "", "", "", "", "", ""])
                rows.append(["总盈利", total_profit, "", "", "", "", "", "", ""])
                rows.append(["总亏损", total_loss, "", "", "", "", "", "", ""])
                rows.append(["净盈亏", net_profit_loss, "", "", "", "", "", "", ""])
            
            # 写入文件或内存
            if file_path:
                os.makedirs(os.path.dirname(os.path.abspath(file_path)), exist_ok=True)
                
                with open(file_path, 'w', newline='', encoding='utf-8-sig') as f:
                    writer = csv.writer(f)
                    writer.writerows(rows)
                
                return ExportResult(True, file_path=file_path, 
                                   message=f"成功导出 {len(transactions)} 条交易记录到 {file_path}")
            else:
                output = io.StringIO()
                writer = csv.writer(output)
                writer.writerows(rows)
                csv_data = output.getvalue()
                
                return ExportResult(True, data=csv_data, 
                                   message=f"成功导出 {len(transactions)} 条交易记录")
        
        except Exception as e:
            logging.error(f"导出CSV失败: {e}")
            return ExportResult(False, message=f"导出CSV失败: {e}")
    
    def _export_as_excel(self, transactions, file_path, include_header, summary):
        """导出为Excel格式"""
        if not has_excel:
            return ExportResult(False, message="Excel导出不可用，请安装xlsxwriter库")
        
        try:
            # 确保文件路径有效
            if file_path:
                os.makedirs(os.path.dirname(os.path.abspath(file_path)), exist_ok=True)
                workbook = xlsxwriter.Workbook(file_path)
            else:
                output = io.BytesIO()
                workbook = xlsxwriter.Workbook(output, {'in_memory': True})
            
            # 创建工作表
            worksheet = workbook.add_worksheet("交易记录")
            
            # 定义表头和格式
            header_format = workbook.add_format({
                'bold': True, 
                'font_color': 'white',
                'bg_color': '#2c3e50',
                'align': 'center',
                'valign': 'vcenter',
                'border': 1
            })
            
            cell_format = workbook.add_format({
                'border': 1
            })
            
            number_format = workbook.add_format({
                'border': 1,
                'num_format': '#,##0.00'
            })
            
            date_format = workbook.add_format({
                'border': 1,
                'num_format': 'yyyy-mm-dd'
            })
            
            summary_format = workbook.add_format({
                'bold': True,
                'border': 1
            })
            
            profit_format = workbook.add_format({
                'border': 1,
                'num_format': '#,##0.00',
                'font_color': 'red'
            })
            
            loss_format = workbook.add_format({
                'border': 1,
                'num_format': '#,##0.00',
                'font_color': 'green'
            })
            
            # 写入表头
            headers = ["交易ID", "日期", "资产类型", "项目名称", "数量", "单价", "货币", "盈亏", "备注"]
            row = 0
            
            if include_header:
                for col, header in enumerate(headers):
                    worksheet.write(row, col, header, header_format)
                row += 1
            
            # 写入交易数据
            for trans in transactions:
                worksheet.write(row, 0, trans.id, cell_format)
                
                # 尝试解析日期为Excel日期格式
                try:
                    date_obj = datetime.datetime.strptime(trans.date, '%Y-%m-%d')
                    worksheet.write_datetime(row, 1, date_obj, date_format)
                except:
                    worksheet.write(row, 1, trans.date, cell_format)
                
                worksheet.write(row, 2, trans.asset_type, cell_format)
                worksheet.write(row, 3, trans.project_name, cell_format)
                worksheet.write(row, 4, trans.amount, number_format)
                worksheet.write(row, 5, trans.unit_price, number_format)
                worksheet.write(row, 6, trans.currency, cell_format)
                
                # 根据盈亏使用不同颜色
                if trans.profit_loss > 0:
                    worksheet.write(row, 7, trans.profit_loss, profit_format)
                else:
                    worksheet.write(row, 7, trans.profit_loss, loss_format)
                
                worksheet.write(row, 8, trans.notes, cell_format)
                row += 1
            
            # 添加汇总信息
            if summary and transactions:
                total_profit = sum(t.profit_loss for t in transactions if t.profit_loss > 0)
                total_loss = sum(t.profit_loss for t in transactions if t.profit_loss < 0)
                net_profit_loss = total_profit + total_loss
                
                row += 1  # 空行
                worksheet.write(row, 0, "汇总信息", summary_format)
                row += 1
                
                worksheet.write(row, 0, "总交易数量", summary_format)
                worksheet.write(row, 1, len(transactions), summary_format)
                row += 1
                
                worksheet.write(row, 0, "总盈利", summary_format)
                worksheet.write(row, 1, total_profit, profit_format)
                row += 1
                
                worksheet.write(row, 0, "总亏损", summary_format)
                worksheet.write(row, 1, total_loss, loss_format)
                row += 1
                
                worksheet.write(row, 0, "净盈亏", summary_format)
                if net_profit_loss > 0:
                    worksheet.write(row, 1, net_profit_loss, profit_format)
                else:
                    worksheet.write(row, 1, net_profit_loss, loss_format)
            
            # 调整列宽
            for i, width in enumerate([10, 12, 12, 25, 10, 10, 8, 12, 30]):
                worksheet.set_column(i, i, width)
            
            # 保存工作簿
            workbook.close()
            
            if file_path:
                return ExportResult(True, file_path=file_path, 
                                   message=f"成功导出 {len(transactions)} 条交易记录到 {file_path}")
            else:
                excel_data = output.getvalue()
                return ExportResult(True, data=excel_data, 
                                   message=f"成功导出 {len(transactions)} 条交易记录")
                
        except Exception as e:
            logging.error(f"导出Excel失败: {e}")
            return ExportResult(False, message=f"导出Excel失败: {e}")
    
    def _export_as_pdf(self, transactions, file_path, include_header, summary):
        """导出为PDF格式"""
        if not has_pdf:
            return ExportResult(False, message="PDF导出不可用，请安装reportlab库")
        
        try:
            # 确保文件路径有效
            if file_path:
                os.makedirs(os.path.dirname(os.path.abspath(file_path)), exist_ok=True)
                output = file_path
            else:
                output = io.BytesIO()
            
            # 创建PDF文档
            doc = SimpleDocTemplate(
                output,
                pagesize=landscape(A4),
                title="交易记录导出",
                author="InvestLedger"
            )
            
            # 创建样式
            styles = getSampleStyleSheet()
            title_style = styles['Heading1']
            normal_style = styles['Normal']
            
            # 创建内容元素
            elements = []
            
            # 添加标题
            title = Paragraph("交易记录导出报表", title_style)
            elements.append(title)
            elements.append(Spacer(1, 12))
            
            # 添加日期
            date_text = f"导出日期: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            date_paragraph = Paragraph(date_text, normal_style)
            elements.append(date_paragraph)
            elements.append(Spacer(1, 12))
            
            # 准备表格数据
            table_data = []
            if include_header:
                table_data.append([
                    "交易ID", "日期", "资产类型", "项目名称", 
                    "数量", "单价", "货币", "盈亏", "备注"
                ])
            
            # 添加交易数据
            for trans in transactions:
                table_data.append([
                    str(trans.id),
                    trans.date,
                    trans.asset_type,
                    trans.project_name,
                    f"{trans.amount:.2f}",
                    f"{trans.unit_price:.2f}",
                    trans.currency,
                    f"{trans.profit_loss:.2f}",
                    trans.notes[:30] + ("..." if len(trans.notes) > 30 else "")  # 截断过长的备注
                ])
            
            # 创建表格
            table = Table(table_data)
            
            # 设置表格样式
            table_style = TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('ALIGN', (0, 1), (-1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
            ])
            
            # 为盈利/亏损设置不同颜色
            for i, trans in enumerate(transactions, 1):
                if include_header:
                    row_idx = i
                else:
                    row_idx = i - 1
                    
                if row_idx < len(table_data):  # 确保行索引有效
                    if trans.profit_loss > 0:
                        table_style.add('TEXTCOLOR', (7, row_idx), (7, row_idx), colors.red)
                    else:
                        table_style.add('TEXTCOLOR', (7, row_idx), (7, row_idx), colors.green)
            
            table.setStyle(table_style)
            elements.append(table)
            
            # 添加汇总信息
            if summary and transactions:
                elements.append(Spacer(1, 20))
                
                total_profit = sum(t.profit_loss for t in transactions if t.profit_loss > 0)
                total_loss = sum(t.profit_loss for t in transactions if t.profit_loss < 0)
                net_profit_loss = total_profit + total_loss
                
                summary_data = [
                    ["汇总信息", ""],
                    ["总交易数量", str(len(transactions))],
                    ["总盈利", f"{total_profit:.2f}"],
                    ["总亏损", f"{total_loss:.2f}"],
                    ["净盈亏", f"{net_profit_loss:.2f}"]
                ]
                
                summary_table = Table(summary_data, colWidths=[100, 100])
                
                summary_style = TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 10),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                    ('ALIGN', (1, 1), (1, -1), 'RIGHT'),
                ])
                
                # 为盈利/亏损设置不同颜色
                summary_style.add('TEXTCOLOR', (1, 2), (1, 2), colors.red)  # 总盈利
                summary_style.add('TEXTCOLOR', (1, 3), (1, 3), colors.green)  # 总亏损
                
                # 净盈亏颜色
                if net_profit_loss > 0:
                    summary_style.add('TEXTCOLOR', (1, 4), (1, 4), colors.red)
                else:
                    summary_style.add('TEXTCOLOR', (1, 4), (1, 4), colors.green)
                
                summary_table.setStyle(summary_style)
                elements.append(summary_table)
            
            # 构建PDF
            doc.build(elements)
            
            if file_path:
                return ExportResult(True, file_path=file_path, 
                                   message=f"成功导出 {len(transactions)} 条交易记录到 {file_path}")
            else:
                pdf_data = output.getvalue()
                return ExportResult(True, data=pdf_data, 
                                   message=f"成功导出 {len(transactions)} 条交易记录")
                
        except Exception as e:
            logging.error(f"导出PDF失败: {e}")
            return ExportResult(False, message=f"导出PDF失败: {e}") 