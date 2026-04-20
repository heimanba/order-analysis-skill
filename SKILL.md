---
name: order-analysis
description: "Analyze product upgrade tickets (工单) to identify common issues and propose product improvements. Use when the user needs to review support tickets, analyze order trends, perform root-cause analysis on customer issues, or generate product improvement reports from an internal ticket system. Accesses the ticket system via agent-browser, extracts order data as JSON, then classifies problems, identifies trends, and outputs actionable recommendations."
---

## 核心工作流程

### 步骤 1: 前置检查
执行以下两个检查脚本，确保环境准备就绪：
```bash
# 检查 Chrome Debug 模式
sh scripts/check-cdp.sh

# 检查 agent-browser 工具
sh scripts/check-agent-browser.sh
```

Both scripts auto-recover (start Chrome / install agent-browser). If they still fail: verify Chrome is installed and port 9222 is free (`lsof -i :9222`), and that Node.js is available (`node --version`).

### 步骤 2: 打开工单系统页面
```bash
agent-browser --cdp 9222 open "https://inner.example.com"
```

### 步骤 3: 准备输出目录
创建以时间命名的输出目录（格式：YYYYMMDD-HHMMSS）：
```bash
OUTPUT_DIR=".output/order-analysis/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"
```

### 步骤 4: 获取订单数据
在浏览器中打开页面后，**在同一 shell 会话中**执行以下命令获取订单的所有JSON数据：
```bash
agent-browser --cdp 9222 eval "$(cat scripts/order-analysis.js)" > "$OUTPUT_DIR/order.json"
```

**验证数据：**
```bash
test -s "$OUTPUT_DIR/order.json" && python3 -c "import json; json.load(open('$OUTPUT_DIR/order.json'))" && echo "OK" || echo "FAIL: check login session or scripts/order-analysis.js"
```
If validation fails: re-login in the browser (session expired), or update the fetch URL in `scripts/order-analysis.js`.

### 步骤 5: 分析数据

Read `$OUTPUT_DIR/order.json` and produce `$OUTPUT_DIR/order_report.md` with this structure:

```markdown
# 工单分析报告

## 1. 数据概览
- 工单总数、时间范围、涉及产品

## 2. 问题分类
| 类别 | 数量 | 占比 | 典型工单 |
|------|------|------|----------|
| 配置错误 | N | X% | #ID: 简述 |
| 功能缺失 | N | X% | #ID: 简述 |
| 性能问题 | N | X% | #ID: 简述 |
| 使用咨询 | N | X% | #ID: 简述 |

## 3. 趋势分析
- 高频问题 TOP 5 及按周/月变化趋势
- 新增 vs 重复出现的问题

## 4. 根因定位
- 共性根因（如文档不足、API 设计缺陷、默认配置不合理）
- 每个根因关联的工单数量

## 5. 改进建议（按优先级排序）
| 优先级 | 建议 | 预期影响 | 关联根因 |
|--------|------|----------|----------|
| P0 | ... | 减少 X% 工单 | ... |
```

Analyze the JSON `data` array — each item typically contains fields like order ID, product name, description, status, and creation time. Classify by reading the description text for patterns.

## agent-browser 参考

使用 `agent-browser` 进行网页自动化操作。运行 `agent-browser --help` 查看所有命令。
**注意**: 所有 `agent-browser` 命令应加上 `--cdp 9222` 参数。

常用命令：
1. `agent-browser --cdp 9222 open <url>` - 访问指定页面
2. `agent-browser --cdp 9222 snapshot -i` - 获取可交互元素及其引用 (@e1, @e2)
3. `agent-browser --cdp 9222 click @e1` / `fill @e2 "text"` - 通过引用与页面元素交互
4. 页面变化后重新执行 snapshot

