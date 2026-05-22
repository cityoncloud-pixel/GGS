# GGS — Goal Generation System

**GGS** 是独立的 **Goal Compiler（目标编译器）**：把模糊想法编译为 GAEH 可消费的 `project_control/goal.md`。

**GAEH**（执行 Harness）在独立仓库：[cityoncloud-pixel/GAEH](https://github.com/cityoncloud-pixel/GAEH)（安装 Release **v0.3.0**）。

**本仓库**：<https://github.com/cityoncloud-pixel/GGS>

---

## 产品边界

| 产品 | 仓库 | 职责 |
|------|------|------|
| **GGS** | 本仓库 | 澄清 → 起草 → 评审 → 导出 `goal.md` |
| **GAEH** | [GAEH](https://github.com/cityoncloud-pixel/GAEH) | Spec → Plan → APPROVE → Execute |

交接契约：[docs/GGS_GAEH_Handoff.md](./docs/GGS_GAEH_Handoff.md)

---

## 快速开始

```powershell
# 1) 安装 GGS（本仓库 package 目录）
cd D:\path\to\GGS\package
powershell -ExecutionPolicy Bypass -File .\ggs.ps1 install
$env:PATH = "$env:USERPROFILE\.ggs\bin;$env:PATH"

# 2) 在目标项目初始化 GGS 工作区（仅 .ggs + goal 壳，不含 ai_harness）
ggs init -TargetPath D:\path\to\your-project

# 3) 编辑种子并在 Cursor 中运行 GGS
# 编辑 project_control/.ggs/goal_seed.md
ggs run -TargetPath D:\path\to\your-project
# → 在 Cursor 对话中说：运行 GGS（无需粘贴 runner.prompt.md）
# → init 已安装 .cursor/rules/ggs-runner.mdc，Agent 自动读取 runner + grill prompt
# → 简单目标：运行 GGS，fast mode / grill depth none

# 4) 校验可移交 GAEH
ggs export -TargetPath D:\path\to\your-project

# 5) 在同一项目安装 GAEH 执行（另一仓库）
# gaeh init -TargetPath ...   # 若尚无 harness
# gaeh doctor / gaeh start → APPROVE
```

---

## CLI

| 命令 | 说明 |
|------|------|
| `ggs install` | 安装到 `~/.ggs` |
| `ggs init` | 落盘 `project_control/.ggs/` 与 `goal.md` 模板 |
| `ggs run` | 打印 runner 入口 |
| `ggs doctor` | 检查 GGS 文件结构 |
| `ggs export` | 检查 Handoff 三件套（EXPORTED + PASS + goal.md） |

---

## 构建 Release

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Clean
# → dist/ggs-kit-v0.1.0.zip
```

---

## 与 GAEH v0.3.0 内嵌 GGS 的关系

- **v0.3.0** 的 `gaeh-kit` 仍内嵌 `.ggs/`（冻结线，不改动）。
- **本仓库** 为独立 GGS Kit（`ggs-kit-v0.1.0`），安装路径 `~/.ggs`，与 `~/.gaeh` 分离。

---

## 文档

- [docs/GGS_Overview.md](./docs/GGS_Overview.md)
- [docs/GGS_GAEH_Handoff.md](./docs/GGS_GAEH_Handoff.md)

## License

MIT — 见 [LICENSE](./LICENSE)。
