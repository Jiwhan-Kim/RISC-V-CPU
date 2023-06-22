module Branch_Control(
    input wire         PCSel,
    input wire  [31:0] Imm,
    input wire  [7:0]  IF_ID_PC,
    input wire         stall,

    output wire        branch,
    output wire [7:0]  pc_branch
);
    
assign branch = stall ? 1'b0 : PCSel;
assign newPC  = stall ? 8'b0 : IF_ID_PC + Imm;

endmodule