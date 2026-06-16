@echo off
setlocal
set "PATH=C:\iverilog\bin;%PATH%"
cd /d "%~dp0"

echo ===== Test 4: Pipeline CPU + Student ID Sorting =====
echo          0x02181024 -^> 0x00112248

echo [BUILD]...
iverilog -I pl-src -I src -s tb_pl_sort -o board_number_demo_tb_pl.out ^
    pl-src\alu.v pl-src\ctrl.v pl-src\ctrl_encode_def.v pl-src\dm_sort.v ^
    pl-src\EXT.v pl-src\im_sort.v pl-src\NPC.v pl-src\PC.v ^
    pl-src\pl_reg.v pl-src\PLCPU.v pl-src\RF.v pl-src\plcomp_sort.v ^
    sim\tb_pl_sort.v
if errorlevel 1 goto err

echo [RUN]...
vvp board_number_demo_tb_pl.out
echo.
echo [PASS] Test 4 complete
pause
goto end

:err
echo [FAIL] Build error
pause
:end
