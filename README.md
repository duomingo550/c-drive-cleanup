# c-drive-cleanup · 把 C 盘的账算清楚

一个 Windows Agent Skill：先只读扫描磁盘，把占用分成「能清的 / 能搬的 / 要你确认的」三级，再按你的决定动手。任何删除或迁移动作都要你点头。

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\c_scan.ps1
```

## 安装

```bash
git clone https://github.com/duomingo550/c-drive-cleanup.git "<技能目录>/c-drive-cleanup"
```

或从 [Releases](https://github.com/duomingo550/c-drive-cleanup/releases) 下载 zip，解压后把 `c-drive-cleanup/` 整个放进技能目录。

> 技能目录：豆包是 `.user_skills`；其它智能体换成各自的 skills 目录。

## 环境

- Windows（PowerShell 5.1 或 7 均可）
- 不需要安装任何依赖
- 迁移应用数据（junction）需要管理员权限

## 用法

```powershell
# 1. 只读扫描（不改任何东西）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\c_scan.ps1

# 2. 迁移某个应用数据到别的盘
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\c_move_app.ps1 `
  -Source "C:\Users\<你>\AppData\Local\某应用" -Target "D:\AppData\某应用"
```

扫描输出 9 个分区：磁盘余量、系统缓存、浏览器缓存、应用缓存、用户目录、AppData Local/Roaming Top 10、ProgramData Top 10、回收站。结尾固定 `扫描完成(未修改任何内容)`。

## 自检

双击 `自检.ps1`：只调扫描脚本，检查 9 个分区是否齐全（10/10 通过）。

## 已知限制

- 大文件（>500MB）不在扫描脚本里，由智能体另行查找
- 迁移脚本没有 dry-run，属破坏性操作，先确认再跑
- 回滚方式：删掉目录联接，把 `_backup` 目录改回原名

## 完整说明书

- [`docs/使用说明.html`](docs/使用说明.html)
- [`docs/使用说明.pdf`](docs/使用说明.pdf)
- [`TESTING.md`](TESTING.md)

## 关于

作者：明叔 · [lark123.com](https://lark123.com) · MIT 许可
