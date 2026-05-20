# 发布 GGS 仓库到 GitHub

本地仓库已初始化（`main` 分支，Kit v0.1.0）。

## 1. 在 GitHub 创建空仓库

- 名称：`GGS`
- 组织/用户：`cityoncloud-pixel`
- **不要**勾选「Add README」（本地已有）

## 2. 推送

```powershell
cd D:\01_PROJECT\GGS
git remote add origin https://github.com/cityoncloud-pixel/GGS.git
git push -u origin main
```

## 3.（可选）Release

```powershell
.\build.ps1 -Clean
# 上传 dist/ggs-kit-v0.1.0.zip 到 Release tag v0.1.0
```
