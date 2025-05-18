# InvestLedger - 轻量级投资记账软件

InvestLedger 是一款用于个人投资记账的轻量级桌面软件，使用 Python 和 PySide6 (Qt) 开发。

## 主要功能

- **交易记录管理**：添加、编辑、删除投资交易记录
- **仪表盘**：展示投资概览和关键指标
- **图表与统计**：通过图表直观地分析投资收益
- **标签管理**：为交易添加标签，便于分类和筛选
- **多格式导出**：支持 CSV、Excel、PDF 多种格式导出数据
- **盈利目标管理**：设置月度和年度盈利目标，追踪达成情况
- **自动备份**：定期备份数据，确保数据安全

## 最新功能更新

1. **图表功能完善**
   - 解决了 QtCharts 组件集成问题
   - 自动检测 Charts 模块可用性
   - 实现了条形图和饼图展示

2. **多格式数据导出**
   - 支持导出为 CSV 格式 (内置支持)
   - 支持导出为 Excel 格式 (需安装 xlsxwriter 库)
   - 支持导出为 PDF 报表 (需安装 reportlab 库)
   - 可过滤日期范围、资产类型

3. **标签管理系统**
   - 创建、编辑和删除标签
   - 为交易分配标签
   - 基于标签筛选交易
   - 自定义标签颜色和描述

4. **盈利目标管理**
   - 设置月度和年度盈利目标
   - 直观展示目标达成进度
   - 盈利目标提醒功能

## 依赖项

- Python 3.6+
- PySide6
- 可选依赖：
  - xlsxwriter (用于Excel导出)
  - reportlab (用于PDF导出)

## 安装与使用

1. 确保安装了Python 3.6+和pip
2. 安装依赖：
   ```
   pip install -r requirements.txt
   ```
3. 运行程序：
   ```
   python main.py
   ```

## 可选功能

某些功能需要额外依赖：
- **Excel导出功能**：需要安装xlsxwriter库（`pip install xlsxwriter`）
- **PDF报表功能**：需要安装reportlab库（`pip install reportlab`）
- **图表统计功能**：需要PySide6 QtCharts模块支持（通常随PySide6安装）

## 未来计划

- 多币种支持
- 投资组合分析
- 风险评估功能
- 云端同步

## 联系方式

有任何问题或建议，请提交Issue或Pull Request。 