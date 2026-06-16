@echo off
setlocal
set "PATH=C:\iverilog\bin;%PATH%"
cd /d "%~dp0"

echo ===== Test 3: SC CPU + Student ID Sorting =====
echo          0x02181024 -^> 0x00112248

echo [BUILD]...
iverilog -I src -I tests -s tb_board_number_demo -o board_number_demo_tb.out ^
    src\alu.v src\ctrl.v src\ctrl_encode_def.v src\EXT.v src\im.v ^
    src\NPC.v src\PC.v src\RF.v src\SCCPU.v src\dm.v ^
    src\debounce.v src\hex_to_7seg.v src\scan_7seg.v ^
    src\sccomp.v src\board_number_demo.v sim\tb_board_number_demo.v
if errorlevel 1 goto err

echo [RUN]...
vvp board_number_demo_tb.out
echo.
echo [PASS] Test 3 complete
pause
goto end

:err
echo [FAIL] Build error
pause
:end
