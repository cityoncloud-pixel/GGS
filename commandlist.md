# GGS 对话指令（Cursor / Codex）

在已执行 `ggs init` 的项目中，**无需粘贴** `runner.prompt.md`。在 Cursor 对话里发送下面任一句即可：

```text
运行 GGS
```

或：

```text
run GGS
```

Agent 会自动读取 `project_control/.ggs/templates/runner.prompt.md` 并按流程执行（含 Goal Grill Gate → Draft → Review → Export）。

## 可选参数（写在同一条消息里）

| 意图 | 示例 |
|------|------|
| 快速路径，少提问 | `运行 GGS，fast mode，grill depth none` |
| 深度澄清 | `运行 GGS，deep clarification` |
| 指定项目路径 | 在 Cursor 中打开该仓库根目录后再发指令 |

## 终端命令（准备文件，不跑 AI）

```powershell
ggs init -TargetPath D:\path\to\your-project
ggs doctor -TargetPath D:\path\to\your-project
ggs run -TargetPath D:\path\to\your-project   # 打印本说明
ggs export -TargetPath D:\path\to\your-project  # GGS 跑完后校验
```

## 首次使用检查

- [ ] 已 `ggs init`，存在 `project_control/.ggs/`
- [ ] 已编辑 `project_control/.ggs/goal_seed.md`
- [ ] 项目根存在 `.cursor/rules/ggs-runner.mdc`（init 自动安装）
- [ ] 在 Cursor 中说「运行 GGS」，而非粘贴整份 runner prompt
