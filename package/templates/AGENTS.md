# GGS Runner（Codex）

> Cursor 用户：同等功能见 `.cursor/rules/ggs-runner.mdc`。两端触发短语相同：**运行 GGS**。

## 触发

用户说「运行 GGS」「run GGS」「ggs run」「启动 GGS」「目标编译」，或要处理 `goal_seed` / `goal.md` / Grill 澄清。

## 启动（禁止让用户粘贴 prompt）

1. 用 **Read** 读取（相对项目根）：
   - `project_control/.ggs/templates/runner.prompt.md`（全文，权威流程）
   - Goal Grill Gate 阶段再读：`project_control/.ggs/templates/grill.prompt.md`
   - 起草/评审时读：`project_control/.ggs/templates/goal.schema.md`
2. 若 `runner.prompt.md` 不存在 → 停止，提示用户执行 `ggs init`。
3. 严格按 `runner.prompt.md` 状态机执行；以磁盘文件为准，不依赖对话记忆。

## 工作区文件

- 读：`project_control/.ggs/state.json`、`goal_seed.md`、`grill.md`、`goal.draft.md`、`assumptions.md`
- 写：同上 + `goal.review.json` + `project_control/goal.next.md` + `project_control/goal.md`
- 不执行 GAEH；不调用外部 API。

## Goal Grill Gate

起草 `goal.draft.md` 之前必须先完成 Grill（见 `grill.prompt.md`），结果写入 `grill.md`；仅对 A 级高影响阻塞项逐条提问。

## 完成标准

- `state.json` → `status: "EXPORTED"`
- `goal.review.json` → `verdict: "PASS"`
- `project_control/goal.md` 满足 `goal.schema.md` Hard Gates

## CLI（Hermes / 终端）

```bash
ggs agent -TargetPath <本项目根> -Runtime codex
# 或
ggs agent -TargetPath <本项目根> -Runtime auto
```
