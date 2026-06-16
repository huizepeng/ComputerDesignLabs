`include "ctrl_encode_def.v"

module NPC(PC, JumpPC, NPCOp, IMM, NPC);
   input  [31:0] PC;
   input  [31:0] JumpPC;
   input  [4:0]  NPCOp;
   input  [31:0] IMM;
   output reg [31:0] NPC;

   wire [31:0] PCPLUS4;
   assign PCPLUS4 = PC + 4;

   always @(*) begin
        case (NPCOp)
            `NPC_PLUS4:   NPC = PCPLUS4;
            `NPC_BRANCH:  NPC = JumpPC + IMM;
            `NPC_JUMP:    NPC = JumpPC + IMM;
            `NPC_JALR:    NPC = (JumpPC + IMM) & ~1;
            default:      NPC = PCPLUS4;
        endcase
    end
endmodule
