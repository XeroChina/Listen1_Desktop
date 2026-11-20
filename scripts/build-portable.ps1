# 将 electron-builder 的 win-unpacked 输出重组为便携版目录结构并压缩。
#
# 目标结构：
#   Listen1/
#     Listen1.exe      launcher（根目录入口）
#     portable         便携标志文件
#     Program/         运行程序（Electron 主程序及其依赖）
#     Data/            用户数据（配置、cookie、会话等）
param(
    [Parameter(Mandatory = $true)]
    [string]$AppDir,
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Arch = "x64",
    [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $OutDir "portable-stage"
$appRoot = Join-Path $stage "Listen1"
$programDir = Join-Path $appRoot "Program"
$dataDir = Join-Path $appRoot "Data"

if (-not (Test-Path $AppDir)) {
    throw "找不到构建输出目录: $AppDir"
}

Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $programDir | Out-Null
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

# 1) 运行程序归拢到 Program 子目录
Copy-Item -Path (Join-Path $AppDir '*') -Destination $programDir -Recurse -Force

# 2) 编译根目录 launcher（Listen1.exe）
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    throw "找不到 C# 编译器: $csc"
}
$platform = switch ($Arch) {
    "x64" { "x64" }
    "ia32" { "x86" }
    "arm64" { "arm64" }
    default { throw "不支持的架构: $Arch" }
}
$iconPath = Join-Path $repoRoot "build\icon.ico"
$launcherOut = Join-Path $appRoot "Listen1.exe"
$cscArgs = @(
    "/nologo",
    "/noconfig",
    "/target:winexe",
    "/platform:$platform",
    "/r:System.dll",
    "/win32icon:$iconPath",
    "/out:$launcherOut",
    (Join-Path $repoRoot "launcher\Launcher.cs")
)
& $csc $cscArgs
if ($LASTEXITCODE -ne 0) {
    throw "launcher 编译失败"
}

# 3) portable 标志文件
New-Item -ItemType File -Force -Path (Join-Path $appRoot "portable") | Out-Null

# 4) Data 占位，保证空目录进入压缩包
Set-Content -Path (Join-Path $dataDir ".gitkeep") -Value "" -NoNewline

# 5) 压缩为 zip
$zip = Join-Path $OutDir ("listen1_" + $Version + "_win_" + $Arch + "_portable.zip")
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path $appRoot -DestinationPath $zip -CompressionLevel Optimal

Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue

Write-Host "便携包已生成: $zip"
