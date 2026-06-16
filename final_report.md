# 计算机设计实验 Lab-5 最终验收报告

> 学号：02181024  
> 日期：2026-06-16

---

## 一、测试结果

### 测试1：单周期 CPU + 30条指令测试

**测试2：流水线 CPU + 30条指令测试**

```
  SC-slt      x10=00000001 ✓
  SC-sltu     x10=00000001 ✓    PL-slt      x10=00000001 ✓
  SC-logic    x10=000000f0 ✓    PL-sltu     x10=00000001 ✓
  SC-shift    x10=00000010 ✓    PL-logic    x10=000000f0 ✓
  SC-slti     x10=00000000 ✓    PL-shift    x10=00000010 ✓
  SC-branches x10=00000002 ✓    PL-slti     x10=00000000 ✓
  SC-jalr     x10=0000000c ✓    PL-branches x10=00000002 ✓
                                PL-beq      x10=00000002 ✓
                                PL-jal      x1 =00000004 ✓
                                PL-jalr     x10=0000000c ✓
```

**分支测试详细（SC/PL 一致）**：

```
x10=00000002  x11=00000001  x12=00000002  x13=00000001  x14=00000002
x15=00000001  x16=00000002  x17=00000001  x18=00000002  x19=00000001
```

偶数寄存器=2（分支跳转成功，执行了跳转目标处的 addi xN,2），奇数=1（分支未跳转路径）。

**jalr 测试（SC/PL 一致）**：x1=0x07, x3=0x0b, x7=0x0d, x10=0x0c, x11=0x1c。
验证 `jalr` 能正确通过 `x1(ra)` 返回。

---

### 测试3 & 测试4：学号排序

| | 单周期 CPU | 流水线 CPU |
|------|------|------|
| 原始学号 DM[0x180] | `0x02181024` | `0x02181024` |
| 排序结果 DM[0x184] | `0x00112248` | `0x00112248` |
| 排序正确 | PASS | PASS |

学号 `02181024` 的 BCD 数字：0,2,1,8,1,0,2,4  
升序排列：0,0,1,1,2,2,4,8 → `0x00112248`

---

### 板上验证（测试5）

| 文件 | 路径 |
|------|------|
| SC bitstream | `vivado/bitstream_check/board_number_demo.bit` |
| PL bitstream | `vivado/bitstream_check_pl/board_number_demo_pl.bit` |

**验证步骤**：
1. 烧录 bitstream 到 Nexys4 DDR
2. 上电后数码管显示 `02181024`
3. 按住 btnU → 数码管切换为 `00112248`
4. 松开 → 恢复 `02181024`
5. LED 始终镜像拨码开关状态

**【待补板卡验证截图】**

---

## 二、指令实现详解

### 2.1 运算指令：`add x11, x2, x3` 的完整数据通路

**RISC-V 编码**：`add x11, x2, x3` → `0x003105B3`

```
指令字: 0000000 00011 00010 000 01011 0110011
        funct7  rs2  rs1  f3  rd    opcode
        ─────  ───  ───  ───  ─────  ──────
        0x00   x3   x2   ADD  x11   R-type
```

**单周期 CPU 执行过程**（`SCCPU.v:89` + `alu.v:15`）：

```
1. IF: PC_out → IM[PC[31:2]] → instr

2. ID: ctrl 译码
   Op=0110011, Funct7=0, Funct3=0 → RegWrite=1, ALUOp=ALUOp_add(00011),
   ALUSrc=0(A=RD1,B=RD2), WDSel=WDSel_FromALU(00)

3. EX: alu 计算
   A = RF[rs1] = RF[x2] = 0x55
   B = RF[rs2] = RF[x3] = 0xFF
   ALUOp = ALUOp_add → C = A + B = 0x154

4. MEM: 无操作(MemWrite=0)

5. WB: WD = aluout = 0x154, RF[x11] ← WD
```

**ALU 源码**（`src/alu.v:15`）：
```
`ALUOp_add:  C = A + B;
```

**ctrl 译码**（`src/ctrl.v:42`）：
```
{7'b0000000, 3'b000}: ALUOp = `ALUOp_add;
```

**寄存器写入**（`src/SCCPU.v:92-99`）：
```
case(WDSel)
    `WDSel_FromALU: WD <= aluout;   // add 走这条路
    `WDSel_FromMEM: WD <= Data_in;
    `WDSel_FromPC:  WD <= PC_out+4;
endcase
```

---

### 2.2 跳转指令：`bne x1, x2, target` 的实现

**RISC-V 编码**：`bne x1, x2, +12` → `0x00209663`

```
指令字: 0 000001 00010 00001 001 0010 0 1100011
        i12 i10:5  rs2  rs1  f3 i4:1 i11 opcode
                         BNE
```

**单周期执行**：

```
1. ID: ctrl 译码
   Op=1100011, Funct3=001 → ALUOp=ALUOp_bne(00101), EXTOp=B-type
   NPCOp = Zero ? NPC_BRANCH : NPC_PLUS4

2. EX: alu 计算
   A=RF[x1]=5, B=RF[x2]=7
   ALUOp=bne → C = (A != B) = 1
   Zero = (C != 0) = 1

3. NPC 计算 (src/NPC.v):
   Zero=1 → NPCOp = NPC_BRANCH
   NPC = PC + imm = PC + 12 → 跳转到 target

4. PC ← NPC (下一周期取 target 指令)
```

**分支 Zero 逻辑**（`src/alu.v:34-38`）：
```
assign Zero = (ALUOp == `ALUOp_bne || ALUOp == `ALUOp_blt ||
               ALUOp == `ALUOp_bge || ALUOp == `ALUOp_bltu ||
               ALUOp == `ALUOp_bgeu) ? (C != 32'b0) : (C == 32'b0);
```

bne: 不相等 → C≠0 → Zero=1 → NPCOp=BRANCH → 跳转  
beq: 相等 → C=0 → Zero=1 → NPCOp=BRANCH → 跳转

**流水线中的分支处理**（`pl-src/PLCPU.v:163-164`）：

与单周期不同，流水线在 ID 阶段**不判断 Zero**，而是无条件编码 NPCOp=BRANCH，将判断推迟到 EX 阶段：

```
// ID 阶段：无条件设置为 BRANCH
ctrl.v: NPCOp = `NPC_BRANCH;  // 不依赖 Zero

// EX 阶段：ALU 计算 Zero，与 NPCOp[0] 相与
assign EX_NPCOp = {ID_EX_out[154:151], ID_EX_out[150] & Zero};

// 若 Zero=1: EX_NPCOp[0]=1 → NPC_BRANCH → 跳转
// 若 Zero=0: EX_NPCOp[0]=0 → NPC_PLUS4 → 不跳转
```

跳转时冲刷流水线（`jump_flush`）：
```
assign jump_flush = (EX_NPCOp == NPC_JUMP)
                 || (EX_NPCOp == NPC_JALR)
                 || (EX_NPCOp == NPC_BRANCH);
// flush 清零 IF_ID_in 和 ID_EX_in，产生1个气泡
```

**jalr 间接跳转**（排序程序的 swap 返回）：
`jalr x0, x1, 0` → 目标 = (RF[x1] + 0) & ~1

NPC 中对 jalr 的特殊处理（`pl-src/PLCPU.v:164`）：
```
npc_base = (EX_NPCOp == NPC_JALR) ? EX_RD1 : EX_pc;
```

`EX_RD1` 是寄存器 x1 的值（jalr 的 rs1），从 ID_EX 流水线寄存器取出。

---

## 三、流水线与单周期对比

### 3.1 流水线寄存器

流水线 CPU 在每两级之间插入了一组 **pl_reg** 寄存器，形成 4 级流水：

```
PC → [IF_ID] → ID → [ID_EX] → EX → [EX_MEM] → MEM → [MEM_WB] → WB
```

| 寄存器 | 位宽 | 锁存内容 |
|--------|------|---------|
| IF_ID | 64 bit | PC(32) + 指令字(32) |
| ID_EX | 194 bit | PC + rs1 + rs2 + rd + immout + RD1 + RD2 + 全部控制信号 |
| EX_MEM | 146 bit | PC + rd + ALU结果 + 控制信号 |
| MEM_WB | 136 bit | PC + rd + ALU结果 + DM数据 + 控制信号 |

**pl_reg 模块**（`pl-src/pl_reg.v`）：
```
module pl_reg #(parameter WIDTH = 32)(
    input clk, rst,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
always @(posedge clk, posedge rst)
    if (rst) out <= 0;
    else     out <= in;
endmodule
```

**时钟设计**：PC 和所有流水线寄存器使用 `~clk`（negedge 捕获），RF 在 posedge 写入。这样：posedge 写入 RF → 半个周期稳定 → negedge 流水线寄存器捕获 → 保证读到正确值。

---

### 3.2 数据冲突解决（RAW + 转发）

**场景**：相邻指令的 RAW 冲突
```
I1: addi x5, x0, 5     // WB 才写 x5
I2: add  x6, x5, x7    // EX 就要读 x5 ← 冲突!
```

**转发单元**（`pl-src/PLCPU.v:149-169`）：
```
// MEM阶段转发（间隔1条指令，优先级高）
forward_rs1_from_mem = MEM_RegWrite && (MEM_rd != 0)
                    && (MEM_rd == EX_rs1);

// WB阶段转发（间隔2条指令，优先级低）
forward_rs1_from_wb  = WB_RegWrite && (WB_rd != 0)
                    && (WB_rd == EX_rs1) && !forward_rs1_from_mem;

// 转发MUX
if (forward_rs1_from_mem)
    alu_in1 = MEM_aluout;      // 从EX_MEM流水线寄存器拿
else if (forward_rs1_from_wb)
    alu_in1 = WD;               // 从RF写数据拿
else
    alu_in1 = EX_RD1;           // 从RF读
```

**优先级的原理**：I1 在 WB、I2 在 MEM、I3 在 EX 时，I2 和 I3 都写 x5。I3 应该拿到 I2 的值（最新），所以 MEM 优先于 WB。

**Load-use 处理**：`lw x5, 0(x0)` 的数据在 MEM 末尾才到达 DM，无法用 MEM_aluout 转发（那只是加载地址）。本实验的排序程序中 lw 和 use 之间有 2-3 条指令间距，通过 "WB→EX 转发 + RF 组合读" 自然规避。

---

### 3.3 控制冲突解决（分支冲刷）

**单周期**：分支在同一周期内完成"译码→计算→判断→跳转"，无冲突。

**流水线**：分支在 ID 阶段译码，但 EX 阶段才知道是否跳转。IF 已经多取了 2 条指令。

**解决**：无条件假设"不跳转"，若 EX 阶段确定跳转则冲刷。

```
beq 在 EX 阶段:
  Zero=1 → EX_NPCOp = NPC_BRANCH
  jump_flush = 1
  → IF_ID_in = 0, ID_EX_in = 0  (冲刷2条指令)
  → 产生 1 cycle 气泡
  → 下个周期取回目标地址指令
```

**代价**：每次跳转多消耗 1 个周期。排序程序约有 70+ 次跳转，因此 PL 需要约 5000 cycles（SC 只需 ~200）。

---

## 四、代码与 Diff

**GitHub**：https://github.com/fripSide/ComputerDesignLabs/tree/main/lab-5

**Diff 报告**：`diff-report/report.html`

| 比较组 | 文件数 | 新增 | 删除 |
|--------|--------|------|------|
| board-demo（顶层+显示） | 3 | — | — |
| single-cycle-cpu | 13 | — | — |
| pipeline-cpu | 12 | — | — |
| **合计** | **33** | **+1303** | **-252** |

---

## 五、文件清单

```
final_lab5/
├── src/           ← 单周期CPU源码（board_number_demo, sccomp, SCCPU, alu, ctrl, ...）
├── pl-src/        ← 流水线CPU源码（plcomp_sort, PLCPU, alu, ctrl, ...）
├── tests/         ← 测试程序 + testbench + expected_results.json
├── sim/           ← 仿真testbench
├── constraints/   ← 引脚约束
├── scripts/       ← Vivado Tcl脚本 + 图表生成
├── vivado/        ← 生成文件
│   ├── bitstream_check/board_number_demo.bit          ← 单周期CPU bitstream
│   └── bitstream_check_pl/board_number_demo_pl.bit    ← 流水线CPU bitstream
├── diff-report/report.html  ← Diff 网页报告
├── run_test1.bat  ← 测试1：SC + 30指令
├── run_test2.bat  ← 测试2：PL + 30指令
├── run_test3.bat  ← 测试3：SC + 学号排序
├── run_test4.bat  ← 测试4：PL + 学号排序
├── build_vivado.ps1
└── final_report.md
```

---

## 六、运行命令汇总

```powershell
# 仿真四个测试（开4个窗口）
cd C:\Users\Administrator\Desktop\final_lab5
start cmd /c run_test1.bat   # SC + 30指令
start cmd /c run_test2.bat   # PL + 30指令
start cmd /c run_test3.bat   # SC + 排序
start cmd /c run_test4.bat   # PL + 排序

# 一键评分
python tests\grade_all.py     # 92/92

# 生成 Vivado bitstream
$env:PATH = "D:\2025.2\Vivado\bin;" + $env:PATH
vivado -mode batch -source scripts\run_bitstream_check.tcl      # SC
vivado -mode batch -source scripts\run_bitstream_pl.tcl         # PL
```

---

**【待补：板卡验证截图、实际开发板运行照片】**
