# c_move_app.ps1 — 迁移单个应用数据到D盘(junction方式)
# 用法: .\c_move_app.ps1 -Source "C:\path\to\app" -Target "D:\path\to\app"

param(
  [Parameter(Mandatory=$true)]
  [string]$Source,
  [Parameter(Mandatory=$true)]
  [string]$Target
)

$ErrorActionPreference = "Stop"

# 检查源目录
if(-not (Test-Path $Source)) {
  Write-Error "源目录不存在: $Source"
  exit 1
}

# 检查是否已经是junction
$item = Get-Item $Source -Force
if($item.LinkType -eq "Junction") {
  Write-Host "已经是Junction: $Source -> $($item.Target)"
  exit 0
}

# 创建目标父目录
$targetParent = Split-Path $Target -Parent
if(-not (Test-Path $targetParent)) {
  New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
}

# 1. 复制
Write-Host "复制 $Source -> $Target ..."
robocopy $Source $Target /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null

# 2. 重命名原目录
$sourceLeaf = Split-Path $Source -Leaf
$sourceParent = Split-Path $Source -Parent
$backupName = "${sourceLeaf}_backup"
$backupPath = Join-Path $sourceParent $backupName

Write-Host "重命名原目录为备份..."
Rename-Item -Path $Source -NewName $backupName -Force

# 3. 创建junction
Write-Host "创建Junction..."
cmd /c "mklink /J `"$Source`" `"$Target`"" | Out-Null

# 4. 验证
if(Test-Path $Source) {
  Write-Host "成功: $Source -> $Target"
  Write-Host "备份在: $backupPath"
  Write-Host "确认应用正常后，删除备份: rmdir /S /Q `"$backupPath`""
} else {
  Write-Host "Junction失败，恢复原目录..."
  Rename-Item -Path $backupPath -NewName $sourceLeaf -Force
  exit 1
}
