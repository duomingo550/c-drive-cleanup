# c-drive-cleanup · 测试报告

- 测试日期：2026-11-25
- 被测版本：c-drive-cleanup（豆包用户技能库版本，本次打包 v1.0.0）
- 环境：Windows / Windows PowerShell 5.1 + PowerShell 7 / 单机
- 方式：只读扫描脚本实跑两次（5.1 与 7 各一次）+ 迁移脚本安全用例 + 语法检查

## 结果汇总

| 用例 | 内容 | 结果 |
|---|---|---|
| T1 | `c_scan.ps1` 在 PowerShell 7 下只读扫描 | ✅ exit 0，88 行输出，9 个分区齐全 |
| T2 | `c_scan.ps1` 在 Windows PowerShell 5.1 下只读扫描 | ✅ exit 0，92 行输出 |
| T3 | `c_move_app.ps1` 源目录不存在 | ✅ exit 1 并提示「源目录不存在」，未做任何改动 |
| T4 | 两个脚本语法检查（5.1 解析器） | ✅ 均 PARSE_OK |

**结论：4/4 通过。**

## 修掉的 bug（本次发布前）

**原始问题**：`c_scan.ps1` 是 UTF-8 **无 BOM**。用 Windows 自带 PowerShell 5.1 执行时，中文按 ANSI 解析成乱码，直接语法错误：

```
Missing '=' operator after key in hash literal
The string is missing the terminator: ".
```

也就是说，按 SKILL.md 里写的 `powershell -ExecutionPolicy Bypass -File c_scan.ps1` 调用，**一运行就报错**。

**修复**：给 `c_scan.ps1`、`c_move_app.ps1` 加 UTF-8 BOM（内容未改）。修复后 5.1 与 7 均正常。

## 扫描覆盖范围（实跑确认）

`c_scan.ps1` 输出 9 个分区：C 盘空间、系统缓存、浏览器缓存、其他应用缓存、用户目录一级、AppData\Local Top 10、AppData\Roaming Top 10、ProgramData Top 10、回收站。

结尾固定一行：`扫描完成(未修改任何内容)`。

## 已知差异与限制

1. **大文件（>500MB）不在扫描脚本里**：SKILL.md 提到这一项，但脚本未实现；实际使用时由智能体另行查找。说明书按实际能力写。
2. **迁移脚本无 dry-run**：`c_move_app.ps1` 直接执行 robocopy + 重命名 + 建 junction，属于破坏性操作。本次只验证了「源目录不存在」的拒绝路径，未在真实数据上执行迁移。
3. **仅 Windows**：依赖 robocopy 与目录联接。
4. **junction 需要管理员权限**：`mklink /J` 在部分环境需要提升权限。

## 打包说明

- 技能目录原样打包（`scripts/` 两个脚本 + SKILL.md）
- 校验和见 `SHA256SUMS.txt`
