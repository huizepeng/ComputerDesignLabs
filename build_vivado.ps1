# final_lab5 一键 Vivado 脚本
# 在安装了 Vivado 的电脑上运行此脚本
# 自动完成: 创建工程 -> 综合 -> 实现 -> 生成 bitstream

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 查找 Vivado
$VivadoBat = $null
$SearchPaths = @(
    "C:\Xilinx\2025.2.1\Vivado\bin\vivado.bat",
    "C:\Xilinx\2025.2\Vivado\bin\vivado.bat",
    "C:\Xilinx\Vivado\2024.2\bin\vivado.bat",
    "C:\Xilinx\Vivado\2024.1\bin\vivado.bat",
    "C:\Xilinx\Vivado\2023.2\bin\vivado.bat",
    "C:\Xilinx\Vivado\2023.1\bin\vivado.bat",
    "D:\Xilinx\2025.2.1\Vivado\bin\vivado.bat",
    "D:\Xilinx\2025.2\Vivado\bin\vivado.bat",
    "D:\Xilinx\Vivado\2024.2\bin\vivado.bat",
    "D:\Xilinx\Vivado\2023.2\bin\vivado.bat"
)

foreach ($p in $SearchPaths) {
    if (Test-Path $p) {
        $VivadoBat = $p
        break
    }
}

if (-not $VivadoBat) {
    # 尝试 PATH 中查找
    $found = Get-Command vivado -ErrorAction SilentlyContinue
    if ($found) {
        $VivadoBat = "vivado"
    } else {
        Write-Host "[ERROR] 未找到 Vivado，请确认 Vivado 已安装" -ForegroundColor Red
        Write-Host "常见安装路径: C:\Xilinx\Vivado\2024.2\bin\vivado.bat" -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host "[INFO] 使用 Vivado: $VivadoBat" -ForegroundColor Green

# Step 1: 创建 Vivado 工程
Write-Host "`n===== Step 1/4: 创建工程 =====" -ForegroundColor Cyan
$CreateProjectTcl = Join-Path $ScriptDir "scripts\create_vivado_project.tcl"

& $VivadoBat -mode batch -source $CreateProjectTcl
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 工程创建失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[OK] 工程创建完成" -ForegroundColor Green

# Step 2: 综合
Write-Host "`n===== Step 2/4: 综合 (Synthesis) =====" -ForegroundColor Cyan
$SynthTcl = @"
open_project vivado/sort_demo/sort_demo.xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set status [get_property STATUS [get_runs synth_1]]
puts "synth_1 status: `$status"
if {![string match "*Complete*" `$status]} {
    close_project
    exit 1
}
close_project
exit 0
"@
$SynthTclPath = Join-Path $ScriptDir "scripts\_run_synth.tcl"
Set-Content -Path $SynthTclPath -Value $SynthTcl -Encoding ASCII

& $VivadoBat -mode batch -source $SynthTclPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 综合失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[OK] 综合完成" -ForegroundColor Green

# Step 3: 实现
Write-Host "`n===== Step 3/4: 实现 (Implementation) =====" -ForegroundColor Cyan
$ImplTcl = @"
open_project vivado/sort_demo/sort_demo.xpr
launch_runs impl_1 -jobs 4
wait_on_run impl_1
set status [get_property STATUS [get_runs impl_1]]
puts "impl_1 status: `$status"
if {![string match "*Complete*" `$status]} {
    close_project
    exit 1
}
close_project
exit 0
"@
$ImplTclPath = Join-Path $ScriptDir "scripts\_run_impl.tcl"
Set-Content -Path $ImplTclPath -Value $ImplTcl -Encoding ASCII

& $VivadoBat -mode batch -source $ImplTclPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] 实现失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[OK] 实现完成" -ForegroundColor Green

# Step 4: 生成 Bitstream
Write-Host "`n===== Step 4/4: 生成 Bitstream =====" -ForegroundColor Cyan
$BitTclPath = Join-Path $ScriptDir "scripts\run_bitstream_check.tcl"

& $VivadoBat -mode batch -source $BitTclPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Bitstream 生成失败" -ForegroundColor Red
    pause
    exit 1
}

# 查找生成的 bit 文件
$BitFile = Join-Path $ScriptDir "vivado\bitstream_check\board_number_demo.bit"
if (Test-Path $BitFile) {
    Write-Host "`n[OK] Bitstream 生成成功!" -ForegroundColor Green
    Write-Host "文件: $BitFile" -ForegroundColor White
    Write-Host "工程: $ScriptDir\vivado\sort_demo\sort_demo.xpr" -ForegroundColor White
} else {
    Write-Host "[WARN] bit 文件未找到，可能在以下位置:" -ForegroundColor Yellow
    Write-Host "  vivado\sort_demo\sort_demo.runs\impl_1\board_number_demo.bit"
}

Write-Host "`n===== 全部完成 =====" -ForegroundColor Green
Write-Host "接下来: 打开 Vivado GUI -> Hardware Manager -> Program Device" -ForegroundColor Cyan
pause
