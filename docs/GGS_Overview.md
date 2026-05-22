# GGS Overview — Goal Generation System

| 元数据 | 值 |
|--------|-----|
| 产品名 | GGS（Goal Generation System） |
| 角色 | **Goal Compiler**（目标编译器） |
| 基线 | **GGS Kit v0.1.0**（本仓库；`ggs init` 安装到 `project_control/.ggs/`） |
| 权威 Handoff | [GGS_GAEH_Handoff.md](./GGS_GAEH_Handoff.md) |

---

## 1. 一句话定位

**GGS 把 Owner 的模糊想法编译成结构化、可验证、可供 GAEH 消费的 `project_control/goal.md`。**

它不写业务代码、不做 Spec/Plan/Execute，不负责 `APPROVE` 之后的连续实现。

---

## 2. GGS 与 GAEH 的分工

```text
Owner 想法
    ↓
┌─────────────────────────────────────┐
│  GGS（Goal Compiler）                │
│  澄清 → 起草 → 评审 → 导出 goal.md   │
└─────────────────────────────────────┘
    ↓  Handoff：goal.md
┌─────────────────────────────────────┐
│  GAEH（Execution Harness）           │
│  Spec → Plan → APPROVE → Execute …   │
└─────────────────────────────────────┘
    ↓
交付物（代码 / 文档 / 可运行程序等）
```

| 维度 | GGS | GAEH |
|------|-----|------|
| 核心问题 | **要做什么、做到什么算完成？** | **怎么做成、如何验证与落盘？** |
| 主要输入 | `goal_seed.md` + `grill.md` | `goal.md` |
| 主要输出 | `goal.md`（+ 评审与过程文件） | `plans/`、`reports/`、`specs/` 等 |
| 运行方式 | Cursor / Codex 说「运行 GGS」；或 `ggs agent -Runtime auto`（`ggs init` 安装 Rule + `AGENTS.md`） | Cursor/Codex + harness 规则 + 适配器 |
| Owner 门禁 | 澄清问答、确认目标是否合理 | `APPROVE` 后才开始连续实现 |

**边界口诀**：GGS 定义正确的问题；GAEH 正确地解决问题。

---

## 3. GGS 不是什么

- **不是** Execution Agent（不替代 GAEH 写代码、跑测试、更新 `task_queue`）。
- **不是** 独立 CLI 运行时（v0.3 无 `ggs.ps1`；便利命令 `gaeh ggs` 仅打印入口路径）。
- **不是** 云端编排或多 Agent 集群（v0.3 为本地文件驱动）。
- **不应** 在 GGS 阶段生成完整 Spec 或大规模实现计划（`goal.review.json` 中的 `handoff` 仅为**建议**，供 GAEH 参考）。

---

## 4. 在项目中的文件位置（v0.3）

初始化：`ggs init` 后，目标项目内出现：

```text
<PROJECT>/
└── project_control/
    ├── .ggs/                    ← GGS 工作区
    │   ├── goal_seed.md         ← 输入：原始想法
    │   ├── grill.md             ← Goal Grill Gate 澄清结果（A/B/C 分类）
    │   ├── goal.draft.md        ← 起草稿
    │   ├── assumptions.md       ← Best-Effort 假设审计
    │   ├── state.json           ← 状态机
    │   ├── goal.review.json     ← 结构化评审
    │   ├── history/             ← 迭代快照
    │   └── templates/
    │       ├── runner.prompt.md ← 单入口 Prompt（实际“引擎”）
    │       ├── grill.prompt.md  ← Goal Grill Gate 策略
    │       └── goal.schema.md   ← 输出质量门槛
    ├── goal.next.md             ← Export 缓冲（可选）
    └── goal.md                  ← Handoff 给 GAEH 的主契约

项目根（`ggs init` 同时安装）：

```text
AGENTS.md                        ← Codex 触发
.cursor/rules/ggs-runner.mdc     ← Cursor 触发
```
```

Kit 源文件位于本仓库：`package/templates/project_control/.ggs/`。  
GAEH 执行层在 [GAEH 仓库](https://github.com/cityoncloud-pixel/GAEH) 单独安装。

---

## 5. 状态机

`state.json` 中 `status` 推荐流转：

```text
IDEA_CAPTURED
    ↓  Goal Grill Gate（歧义扫描 → 仅 A 级提问 → 写入 grill.md）
    ↓  depth=none 时可跳过提问（快速路径）
    ↓  Draft（依据 goal_seed + grill）
GOAL_DRAFTED
    ↓  Review
GOAL_REVIEWED
    ↓  verdict=REVISE → 修订循环（≤ max_revision_rounds）
    ↓  verdict=PASS
EXPORTED
```

评审结论（`goal.review.json`）：

| verdict | 含义 |
|---------|------|
| `PASS` | 可 Export 到 `goal.md` |
| `REVISE` | GGS 按 `auto_revisions` 改稿后再审 |
| `BLOCKED` | 需 Owner 输入；持续 UNKNOWN 则 Best-Effort + 记入 `assumptions.md` |

策略默认值见 `state.json` 的 `policy`（如 `max_question_rounds: 3`、`max_revision_rounds: 3`）。

**Goal Grill Gate**（`state.json.grill`，可选字段，旧项目无此字段时 Runner 仍按 `normal` 深度运行）：

| 字段 | 说明 |
|------|------|
| `depth` | `none` \| `light` \| `normal` \| `deep` |
| `state` | `NOT_STARTED` \| `SCANNED` \| `ASKING` \| `RESOLVED` \| `SKIPPED` |

---

## 6. 如何运行 GGS（v0.3）

### 6.1 前置条件

- 已对目标项目执行 `ggs init`（本仓库 GGS Kit）。
- `project_control/.ggs/templates/runner.prompt.md` 存在。

### 6.2 步骤

1. **写入想法**：编辑 `project_control/.ggs/goal_seed.md`。
2. **启动 Runner（推荐）**：在 **Cursor 或 Codex** 对话发送 [commandlist.md](../../commandlist.md) 中的 **「运行 GGS」**；Agent 从磁盘读取 `runner.prompt.md` / `grill.prompt.md`（`ggs init` 安装 `.cursor/rules/ggs-runner.mdc` 与 `AGENTS.md`）。无需粘贴整份 prompt。
3. **CLI（Hermes）**：`ggs agent -TargetPath <项目> -Runtime auto|cursor|codex`。见 [GGS_Runtime.md](./GGS_Runtime.md)。
4. **备选**：无触发文件时，可全文粘贴 `runner.prompt.md`。
5. **Goal Grill Gate**：Runner 在起草前扫描歧义；仅对高影响 A 级阻塞项提问（见 `grill.prompt.md`）。简单目标可设 `state.json.grill.depth=none` 走快速路径。回答在对话中回复即可；答不出可用 `UNKNOWN`。
6. **等待 Export**：直至 `state.json` 为 `EXPORTED` 且 `goal.review.json` 为 `PASS`，并生成 `goal.md`。
7. **进入 GAEH**：见 [GGS_GAEH_Handoff.md](./GGS_GAEH_Handoff.md)。

### 6.3 CLI

```powershell
ggs run -TargetPath D:\path\to\your-project
ggs agent -TargetPath D:\path\to\your-project -Runtime auto   # Cursor/Codex CLI，见 GGS_Runtime.md
ggs export -TargetPath D:\path\to\your-project
```

`gaeh ggs`（GAEH 仓库）仅为兼容别名；**独立部署请用 `ggs`**。

---

## 7. 与「Agent」的关系

v0.3 的 GGS 是：

```text
文件系统 + 状态机 + 单入口 Prompt + 评审 JSON
```

运行在 **宿主 IDE 里的 LLM**（Cursor/Codex），无独立进程。

未来若演进为「Goal Agent」，可能增加：自动追问、`ggs export` 校验、独立 `ggs-kit` 安装包等；**当前阶段不做工程拆分**，见 [GAEH_v0.3_Freeze_and_GGS_Roadmap.md](../GAEH_v0.3_Freeze_and_GGS_Roadmap.md)。

---

## 8. 相关文档

| 文档 | 说明 |
|------|------|
| [GGS_GAEH_Handoff.md](./GGS_GAEH_Handoff.md) | Export / 启动 GAEH 的正式契约 |
| [GGS_Runtime.md](./GGS_Runtime.md) | Cursor / Codex 对称运行说明 |
| [GGS_Hermes_Integration.md](./GGS_Hermes_Integration.md) | `ggs agent` / Hermes 编排 |
| [GGS_Decoupling_Assessment.md](../GGS_Decoupling_Assessment.md) | GGS 与 GAEH 耦合分析与解耦路线 |
| [GAEH_v0.3_Freeze_and_GGS_Roadmap.md](../GAEH_v0.3_Freeze_and_GGS_Roadmap.md) | 冻结与分阶段计划 |
| [VERSIONING.md](../VERSIONING.md) | 版本与 Release 说明 |
| [goalgeneration.md](../../goalgeneration.md) | 历史愿景（非权威规格） |

---

## 9. 快速自检

- [ ] 我能用一句话说明 GGS 产出什么 → **`goal.md`**
- [ ] 我知道 GGS 不写什么 → **代码 / Spec 全文 / 连续实现**
- [ ] 我知道跑完 GGS 后下一步 → **Handoff 检查 + GAEH + `APPROVE`**
