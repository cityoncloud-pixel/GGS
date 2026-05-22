# GGS 对话指令（Cursor / Codex 对称）

在已执行 `ggs init` 的项目中，**无需粘贴** `runner.prompt.md`。

| 环境 | 自动触发文件 | 对话指令 |
|------|----------------|----------|
| **Cursor** | `.cursor/rules/ggs-runner.mdc` | `运行 GGS` |
| **Codex** | 项目根 `AGENTS.md` | `运行 GGS` |

Agent 会读取 `project_control/.ggs/templates/runner.prompt.md` 并执行（含 Goal Grill Gate → Draft → Review → Export）。

## 可选参数（写在同一条消息里）

| 意图 | 示例 |
|------|------|
| 快速路径，少提问 | `运行 GGS，fast mode，grill depth none` |
| 深度澄清 | `运行 GGS，deep clarification` |
| 指定项目路径 | 在对应 IDE 中打开**项目根目录**后再发指令 |

## 终端命令

```powershell
ggs init -TargetPath D:\path\to\your-project
ggs doctor -TargetPath D:\path\to\your-project
ggs run -TargetPath D:\path\to\your-project      # 打印 IDE + CLI 说明
ggs export -TargetPath D:\path\to\your-project   # GGS 跑完后校验
```

## `ggs agent`（CLI 对称：Cursor / Codex / Hermes）

自动选择已安装的 CLI（`-Runtime auto` 默认先试 Cursor `agent`，再试 Codex `codex`）。

```powershell
ggs agent -TargetPath D:\path\to\your-project                 # auto
ggs agent -TargetPath D:\path\to\your-project -Runtime cursor
ggs agent -TargetPath D:\path\to\your-project -Runtime codex
ggs agent -TargetPath D:\path\to\your-project -Fast           # 少提问
ggs agent -TargetPath D:\path\to\your-project -DryRun         # 只显示将执行的命令
```

配置默认运行时（`~/.ggs/config.json`）：

```json
{
  "runtime": { "preferred": "codex" },
  "cursor_agent": { "command": "agent" },
  "codex": { "command": "codex" }
}
```

详见 [docs/GGS_Hermes_Integration.md](docs/GGS_Hermes_Integration.md)、[docs/GGS_Runtime.md](docs/GGS_Runtime.md)。

## 首次使用检查

- [ ] 已 `ggs init`，存在 `project_control/.ggs/`
- [ ] 已编辑 `project_control/.ggs/goal_seed.md`
- [ ] 存在 `.cursor/rules/ggs-runner.mdc`（Cursor）
- [ ] 存在 `AGENTS.md`（Codex）
- [ ] IDE 中说「运行 GGS」，或 `ggs agent -Runtime auto`
