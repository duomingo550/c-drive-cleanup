---
name: c-drive-cleanup
description: "Windows C盘空间清理与应用数据迁移工具。当用户说C盘满了、磁盘空间不足、想清理C盘、把软件数据移到D盘、释放C盘空间、清理缓存时使用。支持：(1)扫描C盘找出大文件和缓存，(2)安全清理系统/应用缓存，(3)用目录联接(junction)把应用数据迁移到D盘，(4)清空回收站。不处理macOS。"
---

# C 盘清理与数据迁移

## 核心流程

按以下顺序执行，每步完成后再进行下一步。

### 第零步：确认环境

确认当前是 Windows 环境，且运行在用户本地电脑上（不是云端沙箱）。如果是沙箱，告诉用户切到本地模式。

### 第一步：只读扫描（L0，不修改任何东西）

运行扫描脚本 `scripts/c_scan.ps1`，收集：
- C 盘总容量/剩余
- 系统缓存（Temp、Windows Temp、更新缓存、缩略图、着色器）
- 应用缓存（浏览器、网易云、npm、.cache 等）
- 用户目录各子目录大小
- AppData\Local 和 Roaming 各子目录 Top 15
- ProgramData 各子目录
- 回收站大小
- 大文件（>500MB）

**注意**：扫描用 `Get-ChildItem -Recurse -Force -File` 统计大小，遇到权限问题用 `-ErrorAction SilentlyContinue`。如果 PowerShell 输出不稳定，改用 `cmd /c "dir /s /a /-c <path>" | Select-Object -Last 2`。

### 第二步：分类报告

把扫描结果按以下分类整理给用户：

1. **系统缓存（L1 安全清理）**：Temp、Windows Temp、更新缓存、缩略图、着色器、日志
2. **应用缓存（L1-L2）**：浏览器 Cache/Code Cache/GPUCache、网易云 Cache、npm-cache、.cache
3. **应用数据（L2 迁移到 D 盘）**：微信、QQ、WPS、Edge、钉钉、剪映、TRAE、豆包等
4. **下载文件**：Downloads 目录
5. **大文件**：>500MB 的单个文件
6. **回收站**：报告大小，**默认不清空**，需用户确认

每项标注：大小、风险等级、建议操作。

### 第三步：用户确认

展示待清理清单和预计释放空间，等用户确认后再动手。

**用户说"直接清理"时**：
- L1 系统缓存可以直接清
- L2 应用数据迁移需要逐项确认

### 第四步：清理缓存（L1）

删除缓存目录内容（保留目录本身）：
- `%TEMP%\*`
- `C:\Windows\Temp\*`
- `C:\Windows\SoftwareDistribution\Download\*`
- 浏览器 `Cache`、`Code Cache`、`GPUCache` 目录下的内容
- 网易云 `CloudMusic\Cache\*`
- `npm-cache\*`
- `%USERPROFILE%\.cache\*`

**删除技巧**：
- 大量小文件删除慢，用 `robocopy 空目录 目标目录 /MIR` 比 `rd /s /q` 快
- 运行中的应用文件被占用会跳过，正常
- 删除前记录 C 盘剩余空间，删除后对比

### 第五步：迁移应用数据到 D 盘（Junction 方式）

这是本 skill 的核心。用 Windows 目录联接（Junction）把应用数据从 C 盘搬到 D 盘，应用无感知。

**迁移步骤**：
1. 检查目标应用是否在运行，如果在运行先关闭（`Stop-Process`）
2. 用 `robocopy <源> <目标> /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP` 复制到 D 盘
3. 重命名原目录为 `<name>_backup`
4. 创建 junction：`cmd /c "mklink /J \"<源>\" \"<目标>\""`
5. 验证 junction 工作正常
6. 确认应用正常后，删除备份

**标准 D 盘路径**：
- Local 数据 → `D:\AppData\Local\<应用名>`
- Roaming 数据 → `D:\AppData\Roaming\<应用名>`
- 用户目录下的 dotfile → `D:\AppData\Home\<原名称>`

**常见可迁移目录**：
- `AppData\Local\Doubao`（豆包）
- `AppData\Local\JianyingPro`（剪映）
- `AppData\Local\Microsoft\Edge`（Edge）
- `AppData\Local\DingTalk_*`（钉钉）
- `AppData\Local\Google`（Chrome）
- `AppData\Local\OpenAI`
- `AppData\Local\ima.copilot`
- `AppData\Local\Quark`
- `AppData\Local\ixbrowser-*`
- `AppData\Roaming\kingsoft`（WPS）
- `AppData\Roaming\Tencent`（微信/QQ）
- `AppData\Roaming\TRAE SOLO CN`
- `AppData\Roaming\DingTalk`
- `AppData\Roaming\SodaMusic`
- `AppData\Roaming\ixBrowser-Resources`
- `%USERPROFILE%\.workbuddy`
- `%USERPROFILE%\.codex`

**不能迁移的**：
- `C:\Windows`（系统）
- `C:\Program Files*`（已安装程序，迁移会破坏注册表）
- 用户个人文件（桌面/文档/图片）
- 系统关键文件

### 第六步：清空回收站

删除的文件默认进回收站，不会真正释放空间。需要单独清空：
- 先告诉用户回收站占了多少
- 用 `Clear-RecycleBin -Force -Confirm:$false` 尝试
- 如果失败（权限/文件占用），用管理员权限 `rd /s /q C:\$Recycle.Bin\<SID>`
- 实在不行让用户手动右键回收站 → 清空

### 第七步：汇报

输出前后对比：
- C 盘剩余空间变化
- 清理了哪些缓存
- 迁移了哪些应用
- 备份目录位置（提醒用户确认应用正常后可删）

## 关键注意事项

1. **先扫描再动手**：绝不凭假设删文件
2. **备份先行**：迁移时先 rename 为 backup，确认正常后再删
3. **不碰个人文件**：桌面/文档/下载/图片里的文件只报告不删
4. **不碰系统文件**：Windows、Program Files、注册表
5. **应用运行时不能 rename**：先关进程，或等用户退出
6. **回收站是隐藏的占用**：删了文件要记得清回收站
7. **PowerShell 输出可能不稳定**：如果 `Write-Host` 没输出，改用 `cmd /c` 或 `Format-Table`
8. **大量小文件删除慢**：用 `robocopy 空目录 /MIR` 比 `rd /s /q` 快

## 脚本

### scripts/c_scan.ps1

只读扫描脚本，输出 C 盘占用分类。直接运行：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/c_scan.ps1
```

### scripts/c_move_app.ps1

迁移单个应用到 D 盘的辅助脚本。参数：
- `-Source`：原目录路径
- `-Target`：D 盘目标路径
