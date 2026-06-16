`timescale 1ns / 1ps

module tb_pl_sort;

reg clk;
reg rstn;
wire [31:0] dmem_out;
integer i;

localparam STUDENT_ID = 32'h02181024;
localparam SORTED_SID = 32'h00112248;

plcomp_sort dut(.clk(clk), .rstn(rstn), .dmem_out(dmem_out));

initial begin
    clk = 1'b0;
    rstn = 1'b0;
    #50;
    rstn = 1'b1;

    repeat (5000) @(posedge clk);

    $display("[RESULT] original_sid=%h", dut.U_DM.dmem[96]);
    $display("[RESULT] sorted_sid=%h", dut.U_DM.dmem[97]);
    $display("[RESULT] dmem_out=%h", dmem_out);

    if (dut.U_DM.dmem[96] !== STUDENT_ID)
        $display("[FAIL] mem[0x180] expected %h, got %h", STUDENT_ID, dut.U_DM.dmem[96]);
    else if (dut.U_DM.dmem[97] !== SORTED_SID)
        $display("[FAIL] mem[0x184] expected %h, got %h", SORTED_SID, dut.U_DM.dmem[97]);
    else
        $display("[PASS] lab-5 PL sid sorting simulation passed.");

    $finish;
end

always begin
    #5 clk = ~clk;
end

endmodule
