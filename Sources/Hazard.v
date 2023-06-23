module Hazard(
    input wire [4:0]    IF_ID_RS1,
    input wire [4:0]    IF_ID_RS2,
    input wire [4:0]    ID_EX_RD,
    input wire [4:0]    EX_MEM_RD,

    input wire          ID_EX_RegWrite,
    input wire          EX_MEM_RegWrite,
    input wire [1:0]    ID_EX_WBSel,
    input wire [1:0]    EX_MEM_WBSel,

    input wire          branch_indicator,

    output wire         stall
);

    wire stall_load;
    wire stall_branch_EX;
    wire stall_branch_MEM;

    assign stall_load       =  ((ID_EX_RD == IF_ID_RS1 || ID_EX_RD == IF_ID_RS2) 
                             && (ID_EX_RD != 5'b0)
                             && (ID_EX_RegWrite == 1'b1)
                             && (ID_EX_WBSel == 2'b10))
                             ? 1'b1 : 1'b0;

    assign stall_branch_EX  =  ((ID_EX_RD == IF_ID_RS1 || ID_EX_RD == IF_ID_RS2)
                             && (ID_EX_RD != 5'b0) 
                             && (ID_EX_RegWrite == 1'b1) 
                             && (branch_indicator))
                             ? 1'b1 : 1'b0;

    assign stall_branch_MEM =  ((EX_MEM_RD == IF_ID_RS1 || EX_MEM_RD == IF_ID_RS2)
                             && (EX_MEM_RD != 5'b0)
                             && (EX_MEM_RegWrite == 1'b1)
                             && (EX_MEM_WBSel == 2'b10)
                             && (branch_indicator))
                             ? 1'b1 : 1'b0;

    assign stall = stall_load || stall_branch_EX || stall_branch_MEM;
endmodule