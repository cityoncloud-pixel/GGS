# GGS 运行时对称：Cursor 与 Codex

GGS 核心（`project_control/.ggs/` 下所有 prompt 与文件契约）与 IDE 无关。  
**对称**体现在：`ggs init` 同时安装两种触发方式，且 `ggs agent` 可调用两种 CLI。

## 对称一览

| 能力 | Cursor | Codex |
|------|--------|-------|
| `ggs init` 安装触发器 | `.cursor/rules/ggs-runner.mdc` | `AGENTS.md`（项目根） |
| IDE 一句话启动 | 对话：`运行 GGS` | 对话：`运行 GGS` |
| CLI 启动 | `ggs agent -Runtime cursor` | `ggs agent -Runtime codex` |
| CLI 命令 | `agent --workspace <根> ...` | `codex exec --cd <根> ...` 或 `codex --cd <根> ...` |
| 读的流程 | `runner.prompt.md` + `grill.prompt.md` | 同左 |
| 写的产物 | `grill.md`、`goal.draft.md`、`goal.md` 等 | 同左 |
| `ggs doctor` | 检查 Cursor rule | 检查 `AGENTS.md` |
| `ggs export` | 通用 | 通用 |

## `ggs init` 落盘

```text
<PROJECT>/
├── AGENTS.md                          ← Codex
├── .cursor/rules/ggs-runner.mdc       ← Cursor
└── project_control/.ggs/            ← GGS 工作区（通用）
```

## `-Runtime` 行为

| 值 | 行为 |
|----|------|
| `auto`（默认） | 若存在 `agent` → Cursor；否则若存在 `codex` → Codex；否则报错并提示安装 |
| `cursor` | 仅 Cursor Agent CLI |
| `codex` | 仅 Codex CLI |

`~/.ggs/config.json` 中 `runtime.preferred`：

- 设为 `cursor` 或 `codex`：`-Runtime auto` 时**固定**使用该侧（CLI 必须已安装）。
- 未设置或为 `auto`：`-Runtime auto` 时先找 Cursor `agent`，再找 Codex `codex`。

## 非交互（`-Print`）

| 运行时 | 命令形态 | Grill 人工澄清 |
|--------|----------|----------------|
| Cursor | `agent ... -p` | 通常无法等待问答 |
| Codex | `codex exec --sandbox workspace-write` | 同左 |

复杂目标建议：不用 `-Print`，或 `-Fast` + `grill.depth=none`。

## 仍不通用之处

- **不能**用 `cursor .` 代替 `ggs agent`（打不开带 prompt 的 Agent）。
- **Codex** 与 **Cursor** 需各自安装 CLI；未安装一侧时，用 `-Runtime` 指定另一侧或 IDE 对话。
- Hermes 按实际运行时调用 `ggs agent -Runtime cursor|codex|auto`。
