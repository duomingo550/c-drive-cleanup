# c_scan.ps1 — C盘只读扫描(L0)
# 用法: powershell -ExecutionPolicy Bypass -File c_scan.ps1

$ErrorActionPreference = "SilentlyContinue"

function GB($b) { [math]::Round($b/1GB, 2) }
function MB($b) { [math]::Round($b/1MB) }
function DirSize($p) {
  if(Test-Path $p) {
    (Get-ChildItem $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  } else { 0 }
}

Write-Output "=== C盘空间 ==="
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
Write-Output ("总: {0:N1} GB / 剩余: {1:N1} GB ({2}%)" -f ($disk.Size/1GB), ($disk.FreeSpace/1GB), [math]::Round($disk.FreeSpace/$disk.Size*100))

Write-Output "`n=== 系统缓存 ==="
$sysCache = [ordered]@{
  "用户临时文件 %TEMP%" = DirSize $env:TEMP
  "系统临时文件 Windows\Temp" = DirSize "C:\Windows\Temp"
  "Windows更新缓存" = DirSize "C:\Windows\SoftwareDistribution\Download"
  "缩略图缓存" = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*" -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  "着色器缓存" = (DirSize "$env:LOCALAPPDATA\D3DSCache") + (DirSize "$env:LOCALAPPDATA\NVIDIA\DXCache") + (DirSize "$env:LOCALAPPDATA\NVIDIA\GLCache")
  "系统日志" = DirSize "C:\Windows\Logs"
  "错误报告WER" = DirSize "$env:ProgramData\Microsoft\Windows\WER"
}
$sysTotal = 0
foreach($k in $sysCache.Keys) { $sysTotal += $sysCache[$k]; Write-Output ("  {0}: {1} MB" -f $k, (MB $sysCache[$k])) }
Write-Output ("  小计: {0:N2} GB" -f ($sysTotal/1GB))

Write-Output "`n=== 浏览器缓存 ==="
function BrowserCache($ud) {
  $sum = 0
  if(Test-Path $ud) {
    Get-ChildItem $ud -Directory -Force | Where-Object { $_.Name -eq "Default" -or $_.Name -like "Profile *" } | ForEach-Object {
      $sum += DirSize (Join-Path $_.FullName "Cache")
      $sum += DirSize (Join-Path $_.FullName "Code Cache")
      $sum += DirSize (Join-Path $_.FullName "GPUCache")
    }
  }
  return $sum
}
Write-Output ("  Edge: {0:N2} GB" -f ((BrowserCache "$env:LOCALAPPDATA\Microsoft\Edge\User Data")/1GB))
Write-Output ("  Chrome: {0:N2} GB" -f ((BrowserCache "$env:LOCALAPPDATA\Google\Chrome\User Data")/1GB))

Write-Output "`n=== 其他应用缓存 ==="
$appCache = [ordered]@{
  "网易云音乐 Cache" = DirSize "$env:LOCALAPPDATA\NetEase\CloudMusic\Cache"
  "npm-cache" = DirSize "$env:LOCALAPPDATA\npm-cache"
  ".cache (用户目录)" = DirSize "$env:USERPROFILE\.cache"
  "剪映缓存" = DirSize "$env:LOCALAPPDATA\JianyingPro\User Data\Cache"
}
foreach($k in $appCache.Keys) { Write-Output ("  {0}: {1:N2} GB" -f $k, ($appCache[$k]/1GB)) }

Write-Output "`n=== 用户目录一级 ==="
Get-ChildItem $env:USERPROFILE -Directory -Force | ForEach-Object {
  $s = DirSize $_.FullName
  [PSCustomObject]@{ GB = [math]::Round($s/1GB, 2); Dir = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Output "=== AppData\Local Top 10 ==="
Get-ChildItem "$env:LOCALAPPDATA" -Directory -Force | ForEach-Object {
  $s = DirSize $_.FullName
  [PSCustomObject]@{ GB = [math]::Round($s/1GB, 2); Dir = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Output "=== AppData\Roaming Top 10 ==="
Get-ChildItem "$env:APPDATA" -Directory -Force | ForEach-Object {
  $s = DirSize $_.FullName
  [PSCustomObject]@{ GB = [math]::Round($s/1GB, 2); Dir = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Output "=== ProgramData Top 10 ==="
Get-ChildItem "C:\ProgramData" -Directory -Force | ForEach-Object {
  $s = DirSize $_.FullName
  [PSCustomObject]@{ GB = [math]::Round($s/1GB, 2); Dir = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Output "`n=== 回收站 ==="
$rb = (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | Measure-Object -Property Size -Sum
Write-Output ("  {0:N2} GB" -f ($rb.Sum/1GB))

Write-Output "`n扫描完成(未修改任何内容)"
