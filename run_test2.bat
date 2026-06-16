@echo off
setlocal
set "PATH=C:\iverilog\bin;%PATH%"
cd /d "%~dp0"
mkdir tests\build 2>nul

echo ===== Test 2: Pipeline CPU + 30 Instructions =====

echo [BUILD] PL testbench...
iverilog -I pl-src -I src -I tests -s pl_final_tb -o tests\build\pl_final.out ^
    pl-src\alu.v pl-src\ctrl.v pl-src\ctrl_encode_def.v pl-src\EXT.v tests\im_test.v ^
    pl-src\NPC.v pl-src\PC.v pl-src\RF.v pl-src\PLCPU.v pl-src\pl_reg.v ^
    pl-src\plcomp.v pl-src\dm.v tests\tb\pl_final_tb.v
if errorlevel 1 goto err

echo.
for %%T in ("PL-slt|pl/pl_compare_slt.dat|160" "PL-sltu|pl/pl_compare_sltu.dat|160" "PL-logic|pl/pl_logic_immediate.dat|160" "PL-shift|pl/pl_shift_immediate.dat|160" "PL-slti|pl/pl_set_less_immediate.dat|160" "PL-branches|pl/pl_branches.dat|200" "PL-beq|pl/pl_beq.dat|160" "PL-jal|pl/pl_jal.dat|160" "PL-jalr|pl/pl_jalr.dat|160") do (
    for /f "tokens=1,2,3 delims=|" %%a in (%%T) do (
        echo [RUN] %%a
        vvp tests\build\pl_final.out +IMEM=tests\%%b +CYCLES=%%c
    )
)

echo.
echo [PASS] Test 2 complete
pause
goto end

:err
echo [FAIL] Build error
pause
:end
