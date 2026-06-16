#!/usr/bin/env python3
"""Run all SC and PL tests and compare against expected_results.json."""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEST_DIR = ROOT / "tests"
EXPECTED_FILE = TEST_DIR / "expected_results.json"
IVERILOG_DIR = Path(r"C:\iverilog\bin")
BUILD_DIR = TEST_DIR / "build"

SC_SRCS = [
    "src/alu.v", "src/ctrl.v", "src/ctrl_encode_def.v",
    "src/EXT.v", "tests/im_test.v", "src/NPC.v", "src/PC.v",
    "src/RF.v", "src/SCCPU.v", "src/dm.v", "tests/sccomp_test.v",
    "tests/tb/sc_final_tb.v"
]

PL_SRCS = [
    "pl-src/alu.v", "pl-src/ctrl.v", "pl-src/ctrl_encode_def.v",
    "pl-src/EXT.v", "tests/im_test.v", "pl-src/NPC.v", "pl-src/PC.v",
    "pl-src/RF.v", "pl-src/PLCPU.v", "pl-src/pl_reg.v",
    "pl-src/plcomp.v", "pl-src/dm.v", "tests/tb/pl_final_tb.v"
]

SC_TOP = "sc_final_tb"
PL_TOP = "pl_final_tb"

REG_RE = re.compile(r"^\[REG\] x(\d+)=([0-9a-fA-F]{8})$")
MEM_RE = re.compile(r"^\[MEM\] m(\d+)=([0-9a-fA-F]{8})$")


def which_iverilog():
    iv = IVERILOG_DIR / "iverilog.exe"
    if iv.exists():
        return str(iv)
    return "iverilog"


def which_vvp():
    vv = IVERILOG_DIR / "vvp.exe"
    if vv.exists():
        return str(vv)
    return "vvp"


def build_target(top: str, srcs: list, out_name: str) -> Path:
    BUILD_DIR.mkdir(exist_ok=True)
    iverilog = which_iverilog()
    out = BUILD_DIR / out_name
    cmd = [iverilog, "-I", str(ROOT / "src"), "-I", str(ROOT / "pl-src"),
           "-I", str(ROOT / "tests"), "-s", top, "-o", str(out)]
    for s in srcs:
        cmd.append(str(ROOT / s))

    proc = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True)
    if proc.returncode != 0:
        print(f"[BUILD FAIL] {top}: {proc.stderr}")
        sys.exit(1)
    print(f"[BUILD OK] {out_name}")
    return out


def run_test(executable: Path, imem_file: Path, cycles: int) -> tuple[dict, dict]:
    vvp = which_vvp()
    cmd = [vvp, str(executable), f"+IMEM={imem_file.as_posix()}", f"+CYCLES={cycles}"]
    env = os.environ.copy()
    if IVERILOG_DIR.exists():
        env["PATH"] = f"{IVERILOG_DIR};{env.get('PATH', '')}"

    proc = subprocess.run(cmd, cwd=str(ROOT), capture_output=True, text=True, env=env)
    if proc.returncode != 0:
        print(f"  [SIM FAIL] return={proc.returncode}")
        return {}, {}

    regs = {}
    mem = {}
    for line in proc.stdout.splitlines():
        m = REG_RE.match(line.strip())
        if m:
            regs[f"x{m.group(1)}"] = int(m.group(2), 16)
            continue
        m = MEM_RE.match(line.strip())
        if m:
            mem[int(m.group(1))] = int(m.group(2), 16)
    return regs, mem


def load_expected():
    with open(EXPECTED_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def check_test(test_key: str, expected: dict, regs: dict, mem: dict) -> tuple[int, int]:
    passed = 0
    total = 0
    failures = []

    for reg_name, expected_val_str in expected.get("regs", {}).items():
        total += 1
        expected_val = int(expected_val_str, 16)
        actual = regs.get(reg_name)
        if actual == expected_val:
            passed += 1
        else:
            failures.append(f"  {reg_name}: expected {expected_val_str}, got {format_reg(actual)}")

    for mem_idx_str, expected_val_str in expected.get("mem", {}).items():
        total += 1
        expected_val = int(expected_val_str, 16)
        actual = mem.get(int(mem_idx_str))
        if actual == expected_val:
            passed += 1
        else:
            failures.append(f"  mem[{mem_idx_str}]: expected {expected_val_str}, got {format_reg(actual)}")

    return passed, total, failures


def format_reg(val):
    if val is None:
        return "<missing>"
    return f"0x{val:08x}"


def resolve_expected(expected: dict, test_key: str):
    entry = expected.get(test_key, {})
    if "same_as" in entry:
        return entry["same_as"], expected.get(entry["same_as"], {})
    return test_key, entry


def main():
    expected = load_expected()

    # Build
    sc_exe = build_target(SC_TOP, SC_SRCS, "sc_final.out")
    pl_exe = build_target(PL_TOP, PL_SRCS, "pl_final.out")

    # Define test cases
    tests = [
        # (label, target, exe, dat_file, cycles, test_key)
        # SC tests
        ("Test1a: SC-slt", "sc", sc_exe, "sc/sc_compare_slt.dat", 80, "sc/sc_compare_slt.dat"),
        ("Test1b: SC-sltu", "sc", sc_exe, "sc/sc_compare_sltu.dat", 80, "sc/sc_compare_sltu.dat"),
        ("Test1c: SC-logic", "sc", sc_exe, "sc/sc_logic_immediate.dat", 80, "sc/sc_logic_immediate.dat"),
        ("Test1d: SC-shift", "sc", sc_exe, "sc/sc_shift_immediate.dat", 80, "sc/sc_shift_immediate.dat"),
        ("Test1e: SC-slti", "sc", sc_exe, "sc/sc_set_less_immediate.dat", 80, "sc/sc_set_less_immediate.dat"),
        ("Test1f: SC-branches", "sc", sc_exe, "sc/sc_branches.dat", 100, "sc/sc_branches.dat"),
        ("Test1g: SC-jalr", "sc", sc_exe, "sc/sc_jalr.dat", 80, "sc/sc_jalr.dat"),
        # PL tests
        ("Test2a: PL-slt", "pl", pl_exe, "pl/pl_compare_slt.dat", 160, "pl/pl_compare_slt.dat"),
        ("Test2b: PL-sltu", "pl", pl_exe, "pl/pl_compare_sltu.dat", 160, "pl/pl_compare_sltu.dat"),
        ("Test2c: PL-logic", "pl", pl_exe, "pl/pl_logic_immediate.dat", 160, "pl/pl_logic_immediate.dat"),
        ("Test2d: PL-shift", "pl", pl_exe, "pl/pl_shift_immediate.dat", 160, "pl/pl_shift_immediate.dat"),
        ("Test2e: PL-slti", "pl", pl_exe, "pl/pl_set_less_immediate.dat", 160, "pl/pl_set_less_immediate.dat"),
        ("Test2f: PL-branches", "pl", pl_exe, "pl/pl_branches.dat", 200, "pl/pl_branches.dat"),
        ("Test2g: PL-beq", "pl", pl_exe, "pl/pl_beq.dat", 160, "pl/pl_beq.dat"),
        ("Test2h: PL-jal", "pl", pl_exe, "pl/pl_jal.dat", 160, "pl/pl_jal.dat"),
        ("Test2i: PL-jalr", "pl", pl_exe, "pl/pl_jalr.dat", 160, "pl/pl_jalr.dat"),
    ]

    total_passed = 0
    total_checks = 0
    print()

    for label, target, exe, dat, cycles, test_key in tests:
        resolved_key, exp_data = resolve_expected(expected, test_key)
        dat_path = TEST_DIR / dat

        if not dat_path.exists():
            print(f"[SKIP] {label} - .dat not found: {dat_path}")
            continue

        print(f"[RUN] {label} ({cycles} cycles)")
        regs, mem = run_test(exe, dat_path, cycles)
        passed, total, failures = check_test(resolved_key, exp_data, regs, mem)
        total_passed += passed
        total_checks += total

        if passed == total and total > 0:
            print(f"  [PASS] {passed}/{total}")
        else:
            print(f"  [FAIL] {passed}/{total}")
            for f in failures:
                print(f)

    print(f"\nScore: {total_passed}/{total_checks}")
    return 0 if total_passed == total_checks else 1


if __name__ == "__main__":
    sys.exit(main())
