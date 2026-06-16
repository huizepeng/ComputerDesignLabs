@echo off
setlocal
set "PATH=C:\iverilog\bin;%PATH%"
cd /d "%~dp0"
mkdir tests\build 2>nul

echo ===== Test 1: Single-Cycle CPU + 30 Instructions =====

echo [BUILD] SC testbench...
iverilog -I src -I tests -s sc_final_tb -o tests\build\sc_final.out ^
    src\alu.v src\ctrl.v src\ctrl_encode_def.v src\EXT.v tests\im_test.v ^
    src\NPC.v src\PC.v src\RF.v src\SCCPU.v src\dm.v tests\sccomp_test.v ^
    tests\tb\sc_final_tb.v
if errorlevel 1 goto err

echo.
for %%T in ("SC-slt|sc/sc_compare_slt.dat|80" "SC-sltu|sc/sc_compare_sltu.dat|80" "SC-logic|sc/sc_logic_immediate.dat|80" "SC-shift|sc/sc_shift_immediate.dat|80" "SC-slti|sc/sc_set_less_immediate.dat|80" "SC-branches|sc/sc_branches.dat|100" "SC-jalr|sc/sc_jalr.dat|80") do (
    for /f "tokens=1,2,3 delims=|" %%a in (%%T) do (
        echo [RUN] %%a
        vvp tests\build\sc_final.out +IMEM=tests\%%b +CYCLES=%%c
    )
)

echo.
echo [PASS] Test 1 complete
pause
goto end

:err
echo [FAIL] Build error
pause
:end
