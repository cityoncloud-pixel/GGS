# GGS 与 Hermes / 外部编排集成

## 对称 CLI

```powershell
ggs agent -TargetPath D:\path\to\your-project -Runtime auto
ggs agent -TargetPath D:\path\to\your-project -Runtime cursor
ggs agent -TargetPath D:\path\to\your-project -Runtime codex
```

| `-Runtime` | 调用的 CLI | 典型场景 |
|-----------|------------|----------|
| `auto` | 有 `agent` 用 Cursor，否则 `codex` | 默认 / 不确定环境 |
| `cursor` | Cursor Agent CLI | Hermes 节点装 Cursor CLI |
| `codex` | Codex CLI | Hermes 节点装 Codex CLI |

配置 `~/.ggs/config.json`：

```json
{
  "schema_version": "1.0",
  "runtime": { "preferred": "codex" },
  "cursor_agent": { "command": "agent" },
  "codex": { "command": "codex" }
}
```

`preferred` 为 `cursor` 或 `codex` 时，`-Runtime auto` 固定使用该侧（若 CLI 存在）。

## Hermes 任务示例

**Cursor 环境：**

```powershell
ggs agent -TargetPath {{project}} -Runtime cursor
```

**Codex 环境：**

```powershell
ggs agent -TargetPath {{project}} -Runtime codex
```

**自动探测：**

```powershell
ggs agent -TargetPath {{project}} -Runtime auto -Fast
```

**仅预览命令：**

```powershell
ggs agent -TargetPath {{project}} -Runtime auto -DryRun
```

## 前置条件

1. `ggs init` 已执行（含 `.ggs/`、`AGENTS.md`、`.cursor/rules/`）
2. `goal_seed.md` 已填写
3. 目标机器已安装对应 CLI（[Cursor CLI](https://cursor.com/docs/cli/using) / [Codex CLI](https://developers.openai.com/codex/cli)）

## 完成检查

```powershell
ggs export -TargetPath D:\path\to\your-project
```

## 推荐流水线

```text
ggs init
→ 更新 goal_seed.md
→ ggs agent -Runtime <cursor|codex|auto>
→ （如需）用户回答 Grill 问题后再次 agent 或继续同一会话
→ ggs export
→ GAEH（独立 kit）
```

## IDE 与 CLI 关系

| 方式 | 命令/操作 |
|------|-----------|
| Cursor IDE | 对话：`运行 GGS` |
| Codex IDE | 对话：`运行 GGS` |
| Hermes / CI | `ggs agent -Runtime ...` |

核心逻辑始终在 `project_control/.ggs/templates/runner.prompt.md`，不因运行时改变。

参见 [GGS_Runtime.md](./GGS_Runtime.md)。
