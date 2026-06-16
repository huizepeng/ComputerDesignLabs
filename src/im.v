// instruction memory
module im(input  [31:2]  addr, output [31:0] dout);
  reg  [31:0] RAM[127:0];
  integer i;

  initial begin
    for (i = 0; i < 128; i = i + 1) RAM[i] = 32'h00000013; // nop
    $readmemh("rv32_sid_sort_sim.dat", RAM, 0, 54);
  end

  assign dout = RAM[addr]; // word aligned
endmodule
