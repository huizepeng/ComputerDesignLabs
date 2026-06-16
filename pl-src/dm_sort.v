`include "ctrl_encode_def.v"
module dm_sort(clk, DMWr, DMRe, addr, din, dout, dmem_out);
   input          clk;
   input          DMWr;
   input          DMRe;
   input  [31:0]  addr;
   input  [31:0]  din;
   output reg [31:0]  dout;
   output [31:0]  dmem_out;
   
   reg [31:0] dmem[127:0];
   
   always @(posedge clk)
      if (DMWr) dmem[addr[8:2]] <= din;

   always @(*)
      if (DMRe) dout <= dmem[addr[8:2]];

   assign dmem_out = dmem[97];
endmodule
