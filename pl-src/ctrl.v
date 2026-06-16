`include "ctrl_encode_def.v"

module ctrl(Op, Funct7, Funct3, Zero,
            RegWrite, MemWrite, MemRead,
            EXTOp, ALUOp, NPCOp,
            ALUSrc, WDSel
            );

   input  [6:0] Op;
   input  [6:0] Funct7;
   input  [2:0] Funct3;
   input        Zero;

   output reg       RegWrite;
   output reg       MemWrite;
   output reg       MemRead;
   output reg [5:0] EXTOp;
   output reg [4:0] ALUOp;
   output reg [4:0] NPCOp;
   output reg       ALUSrc;
   output reg [1:0] WDSel;

   always @(*) begin
      RegWrite = 1'b0;
      MemWrite = 1'b0;
      MemRead  = 1'b0;
      EXTOp    = 6'b0;
      ALUOp    = `ALUOp_nop;
      NPCOp    = `NPC_PLUS4;
      ALUSrc   = 1'b0;
      WDSel    = `WDSel_FromALU;

      case (Op)
      7'b0110111: begin // lui
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_UTYPE;
         ALUOp    = `ALUOp_lui;
      end

      7'b0110011: begin // R-type
         RegWrite = 1'b1;
         case ({Funct7, Funct3})
         {7'b0000000, 3'b000}: ALUOp = `ALUOp_add;
         {7'b0100000, 3'b000}: ALUOp = `ALUOp_sub;
         {7'b0000000, 3'b010}: ALUOp = `ALUOp_slt;
         {7'b0000000, 3'b011}: ALUOp = `ALUOp_sltu;
         {7'b0000000, 3'b100}: ALUOp = `ALUOp_xor;
         {7'b0000000, 3'b110}: ALUOp = `ALUOp_or;
         {7'b0000000, 3'b111}: ALUOp = `ALUOp_and;
         {7'b0000000, 3'b001}: ALUOp = `ALUOp_sll;
         {7'b0000000, 3'b101}: ALUOp = `ALUOp_srl;
         {7'b0100000, 3'b101}: ALUOp = `ALUOp_sra;
         default: begin
            RegWrite = 1'b0;
            ALUOp = `ALUOp_nop;
         end
         endcase
      end

      7'b0010011: begin // I-type arithmetic
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         case (Funct3)
         3'b000: ALUOp = `ALUOp_add;
         3'b010: ALUOp = `ALUOp_slt;
         3'b011: ALUOp = `ALUOp_sltu;
         3'b100: ALUOp = `ALUOp_xor;
         3'b110: ALUOp = `ALUOp_or;
         3'b111: ALUOp = `ALUOp_and;
         3'b001: begin
            EXTOp = `EXT_CTRL_ITYPE_SHAMT;
            ALUOp = `ALUOp_sll;
         end
         3'b101: begin
            EXTOp = `EXT_CTRL_ITYPE_SHAMT;
            ALUOp = (Funct7 == 7'b0100000) ? `ALUOp_sra : `ALUOp_srl;
         end
         default: begin
            RegWrite = 1'b0;
            ALUOp = `ALUOp_nop;
         end
         endcase
         if (Funct3 != 3'b001 && Funct3 != 3'b101)
            EXTOp = `EXT_CTRL_ITYPE;
      end

      7'b0000011: begin // lw
         RegWrite = 1'b1;
         MemRead  = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         ALUOp    = `ALUOp_add;
         WDSel    = `WDSel_FromMEM;
      end

      7'b0100011: begin // sw
         MemWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_STYPE;
         ALUOp    = `ALUOp_add;
      end

      7'b1100011: begin // branches
         EXTOp = `EXT_CTRL_BTYPE;
         case (Funct3)
         3'b000: begin ALUOp = `ALUOp_sub;  NPCOp = `NPC_BRANCH; end // beq
         3'b001: begin ALUOp = `ALUOp_bne;  NPCOp = `NPC_BRANCH; end // bne
         3'b100: begin ALUOp = `ALUOp_blt;  NPCOp = `NPC_BRANCH; end // blt
         3'b101: begin ALUOp = `ALUOp_bge;  NPCOp = `NPC_BRANCH; end // bge
         3'b110: begin ALUOp = `ALUOp_bltu; NPCOp = `NPC_BRANCH; end // bltu
         3'b111: begin ALUOp = `ALUOp_bgeu; NPCOp = `NPC_BRANCH; end // bgeu
         default: begin ALUOp = `ALUOp_nop; NPCOp = `NPC_PLUS4; end
         endcase
      end

      7'b1101111: begin // jal
         RegWrite = 1'b1;
         EXTOp    = `EXT_CTRL_JTYPE;
         NPCOp    = `NPC_JUMP;
         WDSel    = `WDSel_FromPC;
      end

      7'b1100111: begin // jalr
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         ALUOp    = `ALUOp_add;
         NPCOp    = `NPC_JALR;
         WDSel    = `WDSel_FromPC;
      end

      default: begin
         RegWrite = 1'b0;
         MemWrite = 1'b0;
         MemRead  = 1'b0;
      end
      endcase
   end
endmodule
