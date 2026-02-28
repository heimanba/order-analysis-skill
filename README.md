# Order Analysis Skill

将工单分析 SOP 固化为可复用的 Claude Skill，通过 agent-browser 稳定获取内网工单数据，并利用 AI 进行自动化分析。

## 核心思路

传统方案让 AI "操作浏览器" 存在两大问题：
1. **Token 消耗极高** - 需要生成大量页面 snapshot
2. **稳定性差** - 动态 DOM 元素定位困难

本方案的突破点：**SPA 页面的数据本质上来自接口请求**。与其让 AI 学会"怎么点页面"，不如让 AI **直接执行已经被验证过的请求**（Copy as fetch）。

### 工作流程

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────┐    ┌─────────────┐
│  打开目标页面  │ → │ Copy as fetch    │ → │ agent-browser │ → │  AI 分析数据  │
│ (人工登录)   │    │ 构造请求脚本      │    │ eval 执行    │    │ 输出报告     │
└─────────────┘    └──────────────────┘    └─────────────┘    └─────────────┘
```

## 项目结构

```
order-analysis-skill/
├── SKILL.md                      # Skill 定义文件（Claude 使用）
├── README.md                     # 项目说明
└── scripts/
    ├── check-cdp.sh              # 检查/启动 Chrome Debug 模式
    ├── check-agent-browser.sh    # 检查/安装 agent-browser 工具
    └── order-analysis.js         # 工单数据获取脚本模板
```

## 快速开始

### 1. 环境准备

确保系统已安装：
- macOS（当前脚本针对 Mac 优化）
- Google Chrome
- Node.js（脚本会自动检查安装）

### 2. 首次运行

在 Claude Code 中直接触发 Skill，或手动执行：

```bash
# 步骤 1: 前置检查
sh scripts/check-cdp.sh
sh scripts/check-agent-browser.sh

# 步骤 2: 打开工单系统（替换为实际内网地址）
agent-browser --cdp 9222 open "https://inner.example.com"

# 步骤 3: 人工登录系统（在打开的浏览器中完成登录）

# 步骤 4: 准备输出目录
OUTPUT_DIR=".output/order-analysis/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# 步骤 5: 获取工单数据
agent-browser --cdp 9222 eval "$(cat scripts/order-analysis.js)" > "$OUTPUT_DIR/order.json"

# 步骤 6: AI 分析并生成报告
# 此步骤由 Claude 自动完成，读取 order.json 并输出分析报告到 $OUTPUT_DIR/order_report.md
```

### 3. 配置工单数据源

编辑 `scripts/order-analysis.js`，将从浏览器 DevTools 复制的 fetch 代码粘贴进去：

```javascript
var params = {
  // 根据实际需求配置参数，如产品名称、时间范围等
  productName: "API 网关",
  startDate: "2024-01-01",
  endDate: "2024-01-31"
};

var result = fetch("https://your-inner-system.com/api/orders", {
  "headers": { /* 从浏览器 Copy as fetch 获取 */ },
  "body": "params="+encodeURIComponent(JSON.stringify(params)),
  "method": "POST",
  "credentials": "include"  // 关键：携带登录态 Cookie
});
// ... 后续处理逻辑
```

## 自定义配置

### 筛选特定产品

修改 `order-analysis.js` 中的 `productName`：

```javascript
const productName = "API 网关";  // 改成其他产品名，或留空获取全部
```

### 调整分析维度

编辑 `SKILL.md` 中的"分析数据"步骤提示词，适配不同角色需求：

| 角色 | 关注重点 | 提示词调整方向 |
|------|---------|---------------|
| 研发 | 技术问题、错误堆栈 | 聚焦具体 Bug 和解决方案 |
| PD | 共性问题、产品化机会 | 提炼需求模式和改进建议 |
| TL | 横向对比、趋势分析 | 多产品对比和资源分配建议 |

## 原理详解

### 为什么不用 Playwright / playwright-mcp？

- Token 消耗高：需要持续生成页面 snapshot
- 稳定性差：动态 DOM 元素定位容易失败
- 维护成本高：UI 变更后脚本需要重写

### 为什么不用 agent-browser 的 snapshot/click？

虽然 agent-browser 对 snapshot 做了大量优化（Token 消耗降低 93%），但**只要是"让 AI 去操作页面"，行为就一定不稳定**。

### Copy as fetch 的优势

1. **稳定性**：请求已被浏览器验证过，只要登录态有效就能复现
2. **低成本**：直接获取 JSON 数据，无需解析 DOM
3. **易维护**：接口相对稳定，比 UI  selectors 变化频率低

## 适用场景

- ✅ 内网系统，需要登录态才能访问
- ✅ 高频重复的工单/数据分析任务
- ✅ 同一数据需要多角色、多维度分析
- ✅ 希望将个人 SOP 沉淀为团队可复用资产

## 局限性

- ⚠️ 首次仍需人工登录获取 Cookie
- ⚠️ 接口变更后需要更新 fetch 脚本
- ⚠️ 强依赖 Chrome Debug 模式

## 相关资源

- [Claude Skills 官方文档](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [agent-browser](https://github.com/vercel-labs/agent-browser) - Vercel Labs 的浏览器自动化工具
- [宝玉：Skills 将取代 Workflow](https://baoyu.io/blog/agent-skills-replace-workflow)

## License

MIT
