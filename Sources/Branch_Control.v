module Branch_Control(
    input wire         PCSel,
    input wire  [31:0] Imm,
    input wire  [7:0]  IF_ID_PC,

    output wire        branch,
    output wire [7:0]  pc_branch
);

assign branch = PCSel;
assign newPC = IF_ID_PC + Imm;

endmodule