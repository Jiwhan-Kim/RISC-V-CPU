module Branch_Control(
    input wire         PCSel,
    input wire         stall,
    input wire         branch_indicator,

    input wire  [31:0] Imm,
    input wire  [7:0]  PC,
    input wire  [7:0]  IF_ID_PC,

    output wire        branch_wrong,
    output wire        branch,
    output wire [7:0]  pc_branch
);

assign branch_wrong = branch_indicator && (!stall) && (PC != pc_branch);
assign branch = stall ? 1'b0 : PCSel;
assign pc_branch = stall ? 8'b0 : branch ? (IF_ID_PC + Imm)
                                         : (IF_ID_PC + 4'h4);

endmodule