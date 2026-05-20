# GGS 版本说明

| 项 | 值 |
|----|-----|
| 当前 Kit | **v0.1.0** |
| 安装目录 | `%USERPROFILE%\.ggs\kits\0.1.0` |
| Handoff | `handoff_schema_version: 1.0` |
| GAEH 最低版本 | **v0.3.0** |

## 发布

```powershell
.\build.ps1 -Clean
# dist/ggs-kit-v0.1.0.zip
```

## 与 GAEH 冻结线

GAEH **v0.3.0** 仍内嵌旧版 `.ggs` 分发；本仓库为独立演进线，不修改 GAEH tag `v0.3.0`。
