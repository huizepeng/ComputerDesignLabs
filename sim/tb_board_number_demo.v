`timescale 1ns / 1ps

module tb_board_number_demo;

reg clk;
reg rstn;
reg [15:0] sw_i;
reg btn_sort_raw;
wire [15:0] led_o;
wire [7:0] disp_seg_o;
wire [7:0] disp_an_o;
integer errors;
integer ci;
reg [7:0] chk;

localparam STUDENT_ID = 32'h02181024;
localparam SORTED_SID = 32'h00112248;

board_number_demo #(
    .SCAN_DIV_BITS(2),
    .STUDENT_ID(STUDENT_ID),
    .DEBOUNCE_BITS(4)
) dut (
    .clk(clk),
    .rstn(rstn),
    .sw_i(sw_i),
    .btn_sort_raw(btn_sort_raw),
    .led_o(led_o),
    .disp_seg_o(disp_seg_o),
    .disp_an_o(disp_an_o)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

task expect;
    input condition;
    input [255:0] message;
    begin
        if (!condition) begin
            $display("[FAIL] %0s", message);
            errors = errors + 1;
        end
    end
endtask

task step;
    begin
        @(posedge clk);
        #1;
    end
endtask

initial begin
    errors = 0;
    rstn = 1'b0;      // reset active
    sw_i = 16'h1234;
    btn_sort_raw = 1'b0;
    chk = 8'h00;

    repeat (2) step();
    rstn = 1'b1;      // release reset, CPU starts
    step();

    // Test 1: LED mirror
    expect(led_o == 16'h1234, "LEDs mirror sw 0x1234");
    sw_i = 16'hABCD;
    step();
    expect(led_o == 16'hABCD, "LEDs mirror sw 0xABCD");

    // Test 2: initial display (STUDENT_ID)
    repeat (20) step();
    $display("[INFO] Checking initial display (STUDENT_ID 0x02181024)...");
    chk = 8'h00;
    for (ci = 0; ci < 80; ci = ci + 1) begin
        step();
        case (disp_an_o)
            8'b11111110: if (!chk[0]) begin chk[0] = 1; expect(disp_seg_o == 8'h99, "init d0:4"); end
            8'b11111101: if (!chk[1]) begin chk[1] = 1; expect(disp_seg_o == 8'hA4, "init d1:2"); end
            8'b11111011: if (!chk[2]) begin chk[2] = 1; expect(disp_seg_o == 8'hC0, "init d2:0"); end
            8'b11110111: if (!chk[3]) begin chk[3] = 1; expect(disp_seg_o == 8'hF9, "init d3:1"); end
            8'b11101111: if (!chk[4]) begin chk[4] = 1; expect(disp_seg_o == 8'h80, "init d4:8"); end
            8'b11011111: if (!chk[5]) begin chk[5] = 1; expect(disp_seg_o == 8'hF9, "init d5:1"); end
            8'b10111111: if (!chk[6]) begin chk[6] = 1; expect(disp_seg_o == 8'hA4, "init d6:2"); end
            8'b01111111: if (!chk[7]) begin chk[7] = 1; expect(disp_seg_o == 8'hC0, "init d7:0"); end
        endcase
        if (&chk) ci = 80;
    end
    expect(&chk, "not all init digits scanned");

    // Test 3: wait for CPU to finish, then check DM result
    sw_i = 16'h0000;
    btn_sort_raw = 1'b0;
    $display("[INFO] Waiting for CPU to sort (5000 cycles)...");
    repeat (5000) step();

    $display("[INFO] CPU finished. Checking DM[0x184]...");
    $display("  reg_sel=5'd0 reg_data=%h", dut.U_SCCOMP.reg_data);
    $display("  dmem_out=%h", dut.U_SCCOMP.dmem_out);

    expect(dut.U_SCCOMP.dmem_out == SORTED_SID, "DM[0x184] should be sorted 0x00112248");

    // Also check DM[0x180] = original
    expect(dut.U_SCCOMP.U_DM.dmem[96] == STUDENT_ID, "DM[0x180] should be original 0x02181024");

    // Test 4: sort mode display (btn_sort pressed)
    repeat (10) step();
    $display("[INFO] Testing sort mode display...");
    btn_sort_raw = 1'b1;
    repeat (40) step();

    $display("[INFO] Scanning sorted display (0x00112248)...");
    chk = 8'h00;
    for (ci = 0; ci < 80; ci = ci + 1) begin
        step();
        case (disp_an_o)
            8'b11111110: if (!chk[0]) begin chk[0] = 1; expect(disp_seg_o == 8'h80, "sort d0:8"); end
            8'b11111101: if (!chk[1]) begin chk[1] = 1; expect(disp_seg_o == 8'h99, "sort d1:4"); end
            8'b11111011: if (!chk[2]) begin chk[2] = 1; expect(disp_seg_o == 8'hA4, "sort d2:2"); end
            8'b11110111: if (!chk[3]) begin chk[3] = 1; expect(disp_seg_o == 8'hA4, "sort d3:2"); end
            8'b11101111: if (!chk[4]) begin chk[4] = 1; expect(disp_seg_o == 8'hF9, "sort d4:1"); end
            8'b11011111: if (!chk[5]) begin chk[5] = 1; expect(disp_seg_o == 8'hF9, "sort d5:1"); end
            8'b10111111: if (!chk[6]) begin chk[6] = 1; expect(disp_seg_o == 8'hC0, "sort d6:0"); end
            8'b01111111: if (!chk[7]) begin chk[7] = 1; expect(disp_seg_o == 8'hC0, "sort d7:0"); end
        endcase
        if (&chk) ci = 80;
    end
    expect(&chk, "not all sorted digits scanned");

    btn_sort_raw = 1'b0;

    if (errors == 0)
        $display("[PASS] lab-5 single-cycle CPU: all checks passed.");
    else
        $display("[FAIL] lab-5 single-cycle CPU: %0d error(s) found.", errors);

    $finish;
end

endmodule
