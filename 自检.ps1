# c-drive-cleanup · 自检脚本（只读）
# 双击运行：会调一次扫描脚本，检查 9 个分区是否齐全；不会删除或移动任何文件

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scan = Join-Path $root 'c-drive-cleanup\scripts\c_scan.ps1'

Write-Host ''
Write-Host 'C 盘清理技能 · 自检（只读）' -ForegroundColor Green
Write-Host ('-' * 60)

if (-not (Test-Path $scan)) {
  Write-Host "FAIL  找不到扫描脚本: $scan" -ForegroundColor Red
  Read-Host '按回车退出'
  exit 1
}

$sections = @(
  '=== C盘空间 ===',
  '=== 系统缓存 ===',
  '=== 浏览器缓存 ===',
  '=== 其他应用缓存 ===',
  '=== 用户目录一级 ===',
  '=== AppData\Local Top 10 ===',
  '=== AppData\Roaming Top 10 ===',
  '=== ProgramData Top 10 ===',
  '=== 回收站 ==='
)

Write-Host '正在只读扫描（可能要一两分钟）...' -ForegroundColor DarkGray
$lines = & powershell -NoProfile -ExecutionPolicy Bypass -File $scan 2>&1 | ForEach-Object { [string]$_ }
$text = $lines -join "`n"

$missing = @()
foreach ($s in $sections) {
  if ($text.Contains($s)) {
    Write-Host "PASS  $s" -ForegroundColor Green
  } else {
    Write-Host "FAIL  $s" -ForegroundColor Red
    $missing += $s
  }
}

$clean = $text.Contains('未修改任何内容')
Write-Host ('-' * 60)
if ($clean) {
  Write-Host 'PASS  结尾包含「未修改任何内容」（只读确认）' -ForegroundColor Green
} else {
  Write-Host 'FAIL  未见只读确认行' -ForegroundColor Red
}

$total = $sections.Count + 1
$pass = $total - $missing.Count - $(if ($clean) { 0 } else { 1 })
Write-Host "结果：$pass / $total 通过" -ForegroundColor $(if ($pass -eq $total) { 'Green' } else { 'Yellow' })
Write-Host '（本脚本只调用扫描，不删除、不迁移任何文件）'

Read-Host '按回车关闭'
