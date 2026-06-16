`include "ctrl_encode_def.v"
// data memory
module dm(clk, DMWr, addr, din, dout, dmem_out);
   input          clk;
   input          DMWr;
   input  [31:0]  addr;
   input  [31:0]  din;
   output reg [31:0]  dout;
   output [31:0]  dmem_out;
   
   reg [31:0] dmem[127:0];
   
   always @(posedge clk)
      if (DMWr) begin
         dmem[addr[8:2]] <= din;
      end
    
     //load
     always @(*) begin
         dout <= dmem[addr[8:2]];
     end

     assign dmem_out = dmem[97];
     
endmodule    
